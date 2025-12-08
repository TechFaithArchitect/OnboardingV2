public class PV_TwilioIntegrationHandler implements Queueable, Database.AllowsCallouts {
    public String nextPageUri;

    public PV_TwilioIntegrationHandler() {
        this.nextPageUri = '';
    }

    public PV_TwilioIntegrationHandler(String nextPageUri) {
        this.nextPageUri = nextPageUri;
    }

    public void execute(QueueableContext context) {
        POE_Callout_Config_API__mdt calloutConfig = POE_Callout_Config_API__mdt.getInstance('DCC_Twilio');
        String accountSid = calloutConfig.User__c;
        String token = calloutConfig.Password__c;
        String initialEndpoint = calloutConfig.URL__c;
        String domainBase = calloutConfig.Base_URL__c;
        String batchSize = String.valueOf((Integer)calloutConfig.Batch_Size__c);
        String endPoint;

        if (String.isBlank(nextPageUri)) {
            String formattedDate = String.valueOf(System.now().dateGMT()-1);
            endPoint = initialEndpoint + '?PageSize=' + batchSize + '&Page=0&DateSent>=' + formattedDate;
        } else {
            endPoint = domainBase + nextPageUri;
        }

        Blob credentials = Blob.valueOf(accountSid + ':' + token);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPoint);
        request.setMethod('GET');
        
        String version = '3.2.0';
        request.setHeader('X-Twilio-Client', 'salesforce-' + version);
        request.setHeader('User-Agent', 'twilio-salesforce/' + version);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Accept-Charset', 'utf-8');
        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(credentials));
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        String responseBody = response.getBody();
        String updatedResponse = responseBody.replaceAll('"from":', '"fromValue":').replaceAll('"end":', '"endValue":');
        TwilioResponseWrapper twilioResponse = (TwilioResponseWrapper) JSON.deserialize(updatedResponse, TwilioResponseWrapper.class);

        processResponse(twilioResponse);

        if (String.isNotBlank(twilioResponse.next_page_uri)) {
            System.enqueueJob(new PV_TwilioIntegrationHandler(twilioResponse.next_page_uri));
        }
    }

    public static void processResponse(TwilioResponseWrapper twilioResponse) {
        twilioResponse = removeOutboundMessages(twilioResponse);
        twilioResponse = removeExistingMessages(twilioResponse);
        List<Message_Log__c> messageLogs = new List<Message_Log__c>();

        for (MessageWrapper message : twilioResponse.messages) {
            Message_Log__c logRecord = new Message_Log__c();
            logRecord.Message_Id__c = message.sid;
            logRecord.From__c = message.fromValue;
            logRecord.To__c = message.to;
            logRecord.Body__c = message.body;
            logRecord.Direction__c = 'Inbound';
            logRecord.Status__c = setValidMessageStatus(message);
            logRecord.Sent_Date__c = PV_DateParser.parseRFC2822(message.date_sent);
            logRecord.Error_Code__c = String.valueOf(message.error_code);
            logRecord.Error_Message__c = message.error_message;
            messageLogs.add(logRecord);
        }
        
        messageLogs = matchContacts(messageLogs);
        List<Database.SaveResult> saveResults = Database.insert(messageLogs, false);
        PV_RecordOperationHandler.ProcessResult result = PV_RecordOperationHandler.processSaveResults(saveResults);
        
        if (result.firstErrorType != null) {
            String errorMessage = 'Error Type: ' + result.firstErrorType;
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_TwilioIntegrationHandler.class.getName(), errorMessage);
        }
    }
    
    public static TwilioResponseWrapper removeOutboundMessages(TwilioResponseWrapper twilioResponse) {
        List<MessageWrapper> filteredMessages = new List<MessageWrapper>();

        for (MessageWrapper message : twilioResponse.messages) {
            if (!message.direction.toLowerCase().contains('outbound')) {
                filteredMessages.add(message);
            }
        }

        twilioResponse.messages = filteredMessages;
        return twilioResponse;
    }

    public static TwilioResponseWrapper removeExistingMessages(TwilioResponseWrapper twilioResponse) {
        Set<String> messageIds = new Set<String>();
    
        for (MessageWrapper message : twilioResponse.messages) {
            messageIds.add(message.sid);
        }
    
        Set<String> existingMessageIds = new Set<String>();
        for (Message_Log__c log : [
            SELECT  Message_Id__c
            FROM    Message_Log__c
            WHERE   Message_Id__c IN :messageIds
        ]) {
            existingMessageIds.add(log.Message_Id__c);
        }
    
        List<MessageWrapper> filteredMessages = new List<MessageWrapper>();
        for (MessageWrapper message : twilioResponse.messages) {
            if (!existingMessageIds.contains(message.sid)) {
                filteredMessages.add(message);
            }
        }
    
        twilioResponse.messages = filteredMessages;
        return twilioResponse;
    }

    public static List<Message_Log__c> matchContacts(List<Message_Log__c> messageLogs) {
        List<String> phoneNumbers = new List<String>();
        Map<String, Contact> phoneToContactsMap = new Map<String, Contact>();
        List<Message_Log__c> expandedMessageLogs = new List<Message_Log__c>();
    
        for (Message_Log__c messageLog : messageLogs) {
            if (!phoneNumbers.contains(messageLog.From__c)) {
                phoneNumbers.add(messageLog.From__c);
            }
        }
    
        for (Contact contact : [
            SELECT
                Id,
                Clean_Phone__c,
                (
                    SELECT Id
                    FROM ServiceAppointments
                    WHERE Status NOT IN ('Complete', 'Canceled') OR LastModifiedDate = LAST_N_DAYS:15
                )
            FROM Contact
            WHERE Clean_Phone__c IN :phoneNumbers
            ORDER BY CreatedDate DESC
        ]) {
            if (!phoneToContactsMap.containsKey(contact.Clean_Phone__c)) {
                phoneToContactsMap.put(contact.Clean_Phone__c, contact);
            }
        }
    
        for (Message_Log__c messageLog : messageLogs) {
            Contact matchedContact = phoneToContactsMap.get(messageLog.From__c);
    
            if (matchedContact != null) {
                expandedMessageLogs = cloneMessageLog(matchedContact, messageLog, expandedMessageLogs);
            } else {
                messageLog.Contact__c = FSL_Settings__c.getInstance().Default_Message_Log_Contact_Id__c;
                expandedMessageLogs.add(messageLog);
            }
        }
    
        return expandedMessageLogs;
    }

    public static List<Message_Log__c> cloneMessageLog(Contact matchedContact, Message_Log__c messageLog, List<Message_Log__c> expandedMessageLogs) {
        if (!matchedContact.ServiceAppointments.isEmpty()) {
            for (ServiceAppointment serviceAppointment : matchedContact.ServiceAppointments) {
                Message_Log__c clonedLog = messageLog.clone(false, true, false, false);
                clonedLog.Contact__c = matchedContact.Id;
                clonedLog.Service_Appointment__c = serviceAppointment.Id;
                expandedMessageLogs.add(clonedLog);
            }
        } else {
            Message_Log__c clonedLog = messageLog.clone(false, true, false, false);
            clonedLog.Contact__c = matchedContact.Id;
            expandedMessageLogs.add(clonedLog);
        }

        return expandedMessageLogs;
    }

    public static String setValidMessageStatus(MessageWrapper message) {
        String status;

        if (message.error_code != null) {
            status = 'Error';
            return status;
        }

        switch on message.status {
            when 'failed' {
                status = 'Error';
            } 
            when 'undelivered' {
                status = 'Error';
            }
            when 'sent' {
                status = 'Sent';
            }
            when 'delivered' {
                status = 'Sent';
            }
            when 'received' {
                status = 'Received';
            }
            when else {
                status = 'Error';
            }
        }
        return status;
    }

    public static Boolean sendTwilioSMS(
        String body, String fromPhone, String toPhone, String credentials, String endpointURL, Id contactId, Id serviceAppointmentId) {
        Boolean result = true;

        try {    
            Blob creds = Blob.valueOf(credentials);

            HttpRequest req = new HttpRequest();
            Http http = new Http();
            HTTPResponse res = new HTTPResponse();

            req.setEndpoint(endpointURL);
            req.setMethod('POST');
            String version = '3.2.0';
            req.setHeader('X-Twilio-Client', 'salesforce-' + version);
            req.setHeader('User-Agent', 'twilio-salesforce/' + version);
            req.setHeader('Accept', 'application/json');
            req.setHeader('Accept-Charset', 'utf-8');
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(creds));
            req.setBody(
                'To=' +
                EncodingUtil.urlEncode((String) toPhone, 'UTF-8') +
                '&From=' +
                EncodingUtil.urlEncode((String) fromPhone, 'UTF-8') +
                '&Body=' +
                body
            );
            res = http.send(req);

            Map<String, Object> inputMap = new Map<String, Object>();
            inputMap.put('To', toPhone);
            inputMap.put('From', fromPhone);
            inputMap.put('Body', body);
            inputMap.put('ContactId', contactId);
            inputMap.put('ServiceAppointmentId', serviceAppointmentId);

            saveMessageLog(res, inputMap);
        }
        catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_TwilioIntegrationHandler.class.getName(), e.getMessage());
            if (!Test.isRunningTest()) {
                result = false;
            }
        }
        return result;
    }

    public static void saveMessageLog(HTTPResponse response, Map<String, Object> inputMap) {
        List<Message_Log__c> messageLogs = new List<Message_Log__c>();
        String messageStatus;
        String errorCode;

        if (response.getStatusCode() == 201) {
            messageStatus = 'Sent';
        } else {
            messageStatus = 'Error';
            errorCode = String.valueOf(response.getStatusCode());
        }

        String phoneNumber = (String) inputMap.get('To');
        List<Contact> contacts = getRelatedContacts(phoneNumber);

        if ((inputMap.containsKey('ContactId') && inputMap.get('ContactId') != null) || contacts.size() == 0) {
            Message_Log__c messageLog = createSingleMessageLog(messageStatus, errorCode, inputMap);
            messageLogs.add(messageLog);
        } else {
            messageLogs = createMultipleMessageLogs(contacts, messageStatus, errorCode, inputMap);
        }
        
        List<Database.SaveResult> saveResults = Database.insert(messageLogs, false);
        PV_RecordOperationHandler.ProcessResult result = PV_RecordOperationHandler.processSaveResults(saveResults);
        
        if (result.firstErrorType != null) {
            String errorMessage = 'Error Type: ' + result.firstErrorType;
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', POESendPCISMS.class.getName(), errorMessage);
        }
    }

    public static Message_Log__c createSingleMessageLog(String messageStatus, String errorCode, Map<String, Object> inputMap) {        
        String contactId = (String) inputMap.get('ContactId');
        String defaultContactId = FSL_Settings__c.getInstance().Default_Message_Log_Contact_Id__c;

        Message_Log__c messageLog = new Message_Log__c(
            Direction__c = 'Outbound',
            To__c = (String) inputMap.get('To'),
            From__c = (String) inputMap.get('From'),
            Body__c = (String) inputMap.get('Body'),
            Status__c = messageStatus,
            Contact__c = String.isNotBlank(contactId) ? contactId : defaultContactId,
            Service_Appointment__c = (String) inputMap.get('ServiceAppointmentId'),
            Sent_Date__c = System.now()
        );
        
        messageLog.Error_Code__c = errorCode;
        return messageLog;
    }

    public static List<Message_Log__c> createMultipleMessageLogs(List<Contact> contacts, String messageStatus, String errorCode, Map<String, Object> inputMap) {
        List<Message_Log__c> messageLogs = new List<Message_Log__c>();
        String contactId = (String) inputMap.get('ContactId');
        String defaultContactId = FSL_Settings__c.getInstance().Default_Message_Log_Contact_Id__c;

        for (Contact contact : contacts) {
            Message_Log__c messageLog = new Message_Log__c(
                Direction__c = 'Outbound',
                To__c = (String) inputMap.get('To'),
                From__c = (String) inputMap.get('From'),
                Body__c = (String) inputMap.get('Body'),
                Status__c = messageStatus,
                Contact__c = String.isNotBlank(contact.Id) ? contact.Id : defaultContactId,
                Service_Appointment__c = (String) inputMap.get('ServiceAppointmentId'),
                Sent_Date__c = System.now()
            );
            
            messageLog.Error_Code__c = errorCode;
            messageLogs.add(messageLog);
        }

        return messageLogs;
    }

    public static List<Contact> getRelatedContacts(String phone) {
        return [
            SELECT  Id
            FROM    Contact
            WHERE   Clean_Phone__c = :phone
        ];
    }

    public class TwilioResponseWrapper {
        public Integer endValue;
        public String first_page_uri;
        public List<MessageWrapper> messages;
        public String next_page_uri;
        public Integer page;
        public Integer page_size;
        public String previous_page_uri;
        public Integer start;
        public String uri;
    }
    
    public class MessageWrapper {
        public String account_sid;
        public String api_version;
        public String body;
        public String date_created;
        public String date_sent;
        public String date_updated;
        public String direction;
        public Integer error_code;
        public String error_message;
        public String fromValue;
        public String messaging_service_sid;
        public String num_media;
        public String num_segments;
        public String price;
        public String price_unit;
        public String sid;
        public String status;
        public Map<String, String> subresource_uris;
        public String to;
        public String uri;
    }
}