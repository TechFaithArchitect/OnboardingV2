global without sharing class FSL_SendTwiloSMS {

    public class SMSData {
        @InvocableVariable(required=true)
        public string clientPhone;
        @InvocableVariable(required=true)
        public String body;
        @InvocableVariable(required=false)
        public String contactId;
        @InvocableVariable(required=false)
        public String serviceAppointmentId;
    }

    public class MessageWrapper {
        public String credentials;
        public String endPoint;
        public String fromPhone;
        public List<SMSData> SMSDataList;
    }

    @InvocableMethod
    public static void invokeMethod(
        List<SMSData> inputList
    ) {
        Boolean result = true;

        POE_Callout_Config_API__mdt twilioConfig = POE_Callout_Config_API__mdt.getInstance('DCC_Twilio');
        String accountSid = twilioConfig.User__c;
        String token = twilioConfig.Password__c;
        String endPoint = twilioConfig.URL__c;
        String fromPhone = twilioConfig.Phone__c;
        String creds = accountSid + ':' + token;

        MessageWrapper payload = new MessageWrapper();
        payload.credentials = creds;
        payload.endPoint = endPoint;
        payload.fromPhone = fromPhone;
        payload.SMSDataList = inputList;

        System.debug('creds: ' + creds);
        System.debug('endPoint: ' + endPoint);
        System.debug('fromPhone: ' + fromPhone);
            
        System.enqueueJob(new FSL_SendTwilioSMSQueueable(payload));
        
    }
}