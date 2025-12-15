/**
 * Service for executing follow-up actions (SMS, Email, etc.)
 * Handles retry logic and integrates with Salesforce Messaging API
 */
public with sharing class FollowUpExecutionService {

    /**
     * Send SMS follow-up via Salesforce Messaging
     * @param followUpQueueId Follow_Up_Queue__c record ID
     */
    public static void sendSMSFollowUp(Id followUpQueueId) {
        if (followUpQueueId == null) {
            throw new IllegalArgumentException('Follow-up queue ID is required');
        }

        Follow_Up_Queue__c followUp = [
            SELECT Id, Onboarding__c, Onboarding__r.Account__c,
                   Follow_Up_Type__c, Status__c, Follow_Up_Rule__c,
                   Attempt_Count__c, Last_Attempt_Date__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];

        if (followUp.Onboarding__r.Account__c == null) {
            markFollowUpFailed(followUpQueueId, 'No Account found for onboarding');
            return;
        }

        // Get Contact from Account
        Contact dealerContact = FollowUpMessagingService.getPrimaryContact(followUp.Onboarding__r.Account__c);

        if (dealerContact == null) {
            markFollowUpFailed(followUpQueueId, 'No contact found for account');
            return;
        }

        Follow_Up_Rule__mdt rule = getRuleByDeveloperName(followUp.Follow_Up_Rule__c);
        Communication_Template__c commTemplate = getCommTemplate(rule);

        // Determine SMS provider (default to SalesforceMessaging if not specified)
        // NOTE: Add SMS_Provider__c field to Follow_Up_Rule__mdt to configure provider per rule
        String smsProvider = determineSMSProvider(rule, commTemplate);
        
        // Build provider configuration based on provider type
        Map<String, Object> providerConfig = buildProviderConfig(smsProvider, rule, commTemplate);
        
        // Validate provider configuration
        String configError = validateProviderConfig(smsProvider, providerConfig);
        if (configError != null) {
            markFollowUpFailed(followUpQueueId, configError);
            return;
        }

        // Check if Contact has active messaging endpoint
        if (!FollowUpMessagingService.hasActiveMessagingEndpoint(dealerContact.Id, smsProvider, providerConfig)) {
            markFollowUpFailed(followUpQueueId, 'No active messaging endpoint for contact');
            return;
        }

        try {
            // Get message content
            String messageContent = getMessageContent(followUp, rule, commTemplate);

            // Send SMS using provider strategy
            String smsId = FollowUpMessagingService.sendSMS(
                dealerContact.Id,
                messageContent,
                smsProvider,
                providerConfig
            );

            // Update Follow_Up_Queue__c
            followUp.Status__c = 'Sent';
            followUp.Last_Attempt_Date__c = DateTime.now();
            followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
            followUp.Consecutive_Failures__c = 0; // Reset on success
            
            // Store SMS tracking ID (MessagingSession ID) if available
            // Note: If Messaging_Session__c field exists on Follow_Up_Queue__c, uncomment:
            // try {
            //     followUp.Messaging_Session__c = (Id)smsId;
            // } catch (Exception e) {
            //     // Field may not exist - ignore
            // }
            
            update followUp;

            // Update attempt tracking
            FollowUpFatigueService.updateAttemptTracking(followUpQueueId, true);
        } catch (Exception e) {
            markFollowUpFailed(followUpQueueId, 'Error sending SMS: ' + e.getMessage());
            FollowUpFatigueService.updateAttemptTracking(followUpQueueId, false);
            throw e;
        }
    }

    /**
     * Send email follow-up
     * @param followUpQueueId Follow_Up_Queue__c record ID
     */
    public static void sendEmailFollowUp(Id followUpQueueId) {
        if (followUpQueueId == null) {
            throw new IllegalArgumentException('Follow-up queue ID is required');
        }

        Follow_Up_Queue__c followUp = [
            SELECT Id, Onboarding__c, Onboarding__r.Account__c,
                   Follow_Up_Type__c, Status__c, Follow_Up_Rule__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];

        Follow_Up_Rule__mdt rule = getRuleByDeveloperName(followUp.Follow_Up_Rule__c);
        Communication_Template__c commTemplate = getCommTemplate(rule);

        Contact dealerContact = FollowUpMessagingService.getPrimaryContact(followUp.Onboarding__r.Account__c);
        if (dealerContact == null || String.isBlank(dealerContact.Email)) {
            markFollowUpFailed(followUpQueueId, 'No contact email available for onboarding account');
            return;
        }

        // Build email request from communication template
        EmailCommSendRequestDTO req = new EmailCommSendRequestDTO();
        req.communicationTemplateId = commTemplate != null ? commTemplate.Id : null;
        req.emailTemplateId = commTemplate != null ? commTemplate.Email_Template_Id__c : null;
        req.subject = commTemplate != null ? commTemplate.Email_Subject__c : 'Onboarding Follow-Up';
        req.toAddress = dealerContact.Email;
        req.recipientId = dealerContact.Id;
        req.relatedRecordId = followUp.Onboarding__c;
        req.logSync = true;

        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(req);
        if (result == null || result.status != 'Success') {
            String errorMsg = result != null ? result.errorMessage : 'Unknown error';
            markFollowUpFailed(followUpQueueId, 'Email send failed: ' + errorMsg);
            return;
        }

        // Update follow-up on success
        followUp.Status__c = 'Sent';
        followUp.Last_Attempt_Date__c = DateTime.now();
        followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
        followUp.Consecutive_Failures__c = 0;
        update followUp;

        FollowUpFatigueService.updateAttemptTracking(followUpQueueId, true);
    }

    /**
     * Retry failed follow-ups
     * Called by FollowUpRetryHandler when Platform Event is received
     * @param followUpQueueIds List of Follow_Up_Queue__c record IDs to retry
     */
    public static void retryFailedFollowUps(List<Id> followUpQueueIds) {
        if (followUpQueueIds == null || followUpQueueIds.isEmpty()) {
            return;
        }

        List<Follow_Up_Queue__c> followUps = [
            SELECT Id, Follow_Up_Type__c, Onboarding__c,
                   Attempt_Count__c, Last_Attempt_Date__c, Status__c
            FROM Follow_Up_Queue__c
            WHERE Id IN :followUpQueueIds
              AND Status__c = 'Pending Retry'
        ];

        if (followUps.isEmpty()) {
            return;
        }

        for (Follow_Up_Queue__c fq : followUps) {
            try {
                if (fq.Follow_Up_Type__c == 'SMS') {
                    sendSMSFollowUp(fq.Id);
                } else if (fq.Follow_Up_Type__c == 'Email') {
                    sendEmailFollowUp(fq.Id);
                } else {
                    markFollowUpFailed(fq.Id, 'Unknown follow-up type: ' + fq.Follow_Up_Type__c);
                }
            } catch (Exception e) {
                markFollowUpFailed(fq.Id, 'Retry failed: ' + e.getMessage());
                // LoggingUtil.logError('FollowUpRetry', 'retryFailedFollowUps', e.getMessage(), e.getStackTraceString());
            }
        }
    }

    /**
     * Mark follow-up as failed
     * @param followUpQueueId Follow_Up_Queue__c record ID
     * @param errorMessage Error message
     */
    public static void markFollowUpFailed(Id followUpQueueId, String errorMessage) {
        Follow_Up_Queue__c followUp = [
            SELECT Id, Status__c, Consecutive_Failures__c, Attempt_Count__c, Last_Attempt_Date__c, Error_Message__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];

        followUp.Status__c = 'Failed';
        followUp.Consecutive_Failures__c = (followUp.Consecutive_Failures__c == null ? 0 : followUp.Consecutive_Failures__c) + 1;
        followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
        followUp.Last_Attempt_Date__c = DateTime.now();
        followUp.Error_Message__c = errorMessage;
        
        update followUp;
    }

    /**
     * Get message content for follow-up
     * TODO: Get from Follow_Up_Rule__mdt template when available
     * @param followUp Follow_Up_Queue__c record
     * @return Message content string
     */
    private static String getMessageContent(Follow_Up_Queue__c followUp, Follow_Up_Rule__mdt rule, Communication_Template__c commTemplate) {
        if (commTemplate != null && !String.isBlank(commTemplate.Message_Body__c)) {
            return commTemplate.Message_Body__c;
        }
        if (rule != null && !String.isBlank(rule.Trigger_Condition__c)) {
            return 'Reminder: ' + rule.Trigger_Condition__c;
        }
        return 'Please complete your onboarding requirement. If you have questions, contact your onboarding representative.';
    }

    /**
     * Get default messaging channel ID
     * TODO: Get from Custom Metadata or Custom Setting
     * @return MessagingChannel ID or null
     */
    private static Id getIdIfValid(String maybeId) {
        if (String.isBlank(maybeId)) {
            return null;
        }
        try {
            return (Id)maybeId;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Determine SMS provider from rule or template
     * NOTE: Add SMS_Provider__c field to Follow_Up_Rule__mdt to configure provider per rule
     * For now, defaults to SalesforceMessaging if Messaging_Channel__c exists, otherwise Twilio
     */
    private static String determineSMSProvider(Follow_Up_Rule__mdt rule, Communication_Template__c commTemplate) {
        // Check if SMS_Provider__c field exists on rule (will be null if field doesn't exist)
        // If field exists and has value, use it
        // Otherwise, default based on whether Messaging_Channel__c is configured
        
        Id messagingChannelId = getIdIfValid(
            commTemplate != null ? commTemplate.Messaging_Channel_Id__c : 
            rule != null ? rule.Messaging_Channel__c : null
        );
        
        // If Messaging Channel is configured, use Salesforce Messaging
        // Otherwise, default to Twilio
        // TODO: Once SMS_Provider__c field is added to Follow_Up_Rule__mdt, use that instead
        return messagingChannelId != null ? 'SalesforceMessaging' : 'Twilio';
    }

    /**
     * Build provider configuration map based on provider type
     */
    private static Map<String, Object> buildProviderConfig(
        String providerType,
        Follow_Up_Rule__mdt rule,
        Communication_Template__c commTemplate
    ) {
        Map<String, Object> config = new Map<String, Object>();
        
        if (providerType == 'SalesforceMessaging') {
            Id messagingChannelId = getIdIfValid(
                commTemplate != null ? commTemplate.Messaging_Channel_Id__c : 
                rule != null ? rule.Messaging_Channel__c : null
            );
            config.put('messagingChannelId', messagingChannelId);
            
            Id templateId = getIdIfValid(
                commTemplate != null ? commTemplate.Messaging_Template_Id__c : 
                rule != null ? rule.Messaging_Template__c : null
            );
            if (templateId != null) {
                config.put('templateId', templateId);
            }
        } else if (providerType == 'Twilio') {
            // Get from phone number from rule or template
            // NOTE: Add Twilio_From_Phone__c field to Follow_Up_Rule__mdt or Communication_Template__c
            // For now, use a default or get from custom metadata
            String fromPhone = getTwilioFromPhone(rule, commTemplate);
            if (String.isNotBlank(fromPhone)) {
                config.put('fromPhoneNumber', fromPhone);
            }
            
            // Optional: Account SID and Auth Token (if not in Named Credential)
            // These can be added to Follow_Up_Rule__mdt if needed
        }
        
        return config;
    }

    /**
     * Get Twilio from phone number from Twilio_Configuration__mdt
     * Uses the first active configuration record
     */
    private static String getTwilioFromPhone(Follow_Up_Rule__mdt rule, Communication_Template__c commTemplate) {
        try {
            // Query Twilio_Configuration__mdt for active configuration
            List<Twilio_Configuration__mdt> configs = [
                SELECT From_Phone_Number__c, Named_Credential__c
                FROM Twilio_Configuration__mdt
                WHERE Active__c = true
                LIMIT 1
            ];
            
            if (!configs.isEmpty()) {
                return configs[0].From_Phone_Number__c;
            }
        } catch (Exception e) {
            // Twilio_Configuration__mdt may not exist yet - log and return null
            System.debug('Twilio_Configuration__mdt not found or not accessible: ' + e.getMessage());
        }
        
        // Fallback: Check if Twilio_From_Phone__c field exists on rule or template
        // TODO: Once Twilio_From_Phone__c field is added to Follow_Up_Rule__mdt or Communication_Template__c, retrieve it here
        return null;
    }

    /**
     * Get Twilio Account SID from configuration
     * NOTE: Account SID is required for Twilio API calls (used in URL path)
     */
    private static String getTwilioAccountSid(Follow_Up_Rule__mdt rule, Communication_Template__c commTemplate) {
        // TODO: Add Account_SID__c field to Twilio_Configuration__mdt or Follow_Up_Rule__mdt
        // For now, return null (will cause validation error, which is expected)
        // Account SID should be provided in providerConfig or stored in Named Credential username
        return null;
    }

    /**
     * Get Twilio Named Credential name from configuration
     */
    private static String getTwilioNamedCredential(Follow_Up_Rule__mdt rule, Communication_Template__c commTemplate) {
        try {
            List<Twilio_Configuration__mdt> configs = [
                SELECT Named_Credential__c
                FROM Twilio_Configuration__mdt
                WHERE Active__c = true
                LIMIT 1
            ];
            
            if (!configs.isEmpty() && String.isNotBlank(configs[0].Named_Credential__c)) {
                return configs[0].Named_Credential__c;
            }
        } catch (Exception e) {
            System.debug('Could not get Named Credential from Twilio_Configuration__mdt: ' + e.getMessage());
        }
        
        return null; // Will use default
    }

    /**
     * Validate provider configuration
     */
    private static String validateProviderConfig(String providerType, Map<String, Object> providerConfig) {
        if (providerType == 'SalesforceMessaging') {
            Id messagingChannelId = (Id)providerConfig.get('messagingChannelId');
            if (messagingChannelId == null) {
                return 'No messaging channel configured for Salesforce Messaging';
            }
        } else if (providerType == 'Twilio') {
            String fromPhone = (String)providerConfig.get('fromPhoneNumber');
            if (String.isBlank(fromPhone)) {
                return 'From phone number is required for Twilio. Add Twilio_From_Phone__c field to Follow_Up_Rule__mdt.';
            }
        }
        return null; // Valid
    }

    private static Follow_Up_Rule__mdt getRuleByDeveloperName(String developerName) {
        if (String.isBlank(developerName)) {
            return null;
        }
        List<Follow_Up_Rule__mdt> rules = [
            SELECT DeveloperName, Trigger_Condition__c, Follow_Up_Type__c,
                   Initial_Delay_Days__c, Escalation_Schedule__c,
                   Messaging_Channel__c, Messaging_Template__c,
                   Max_Attempts_Per_Window__c, Fatigue_Window_Days__c, Fatigue_Suppression_Enabled__c,
                   Active__c
            FROM Follow_Up_Rule__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        return rules.isEmpty() ? null : rules[0];
    }

    private static Communication_Template__c getCommTemplate(Follow_Up_Rule__mdt rule) {
        if (rule == null || String.isBlank(rule.Messaging_Template__c)) {
            return null;
        }
        List<Communication_Template__c> comms = [
            SELECT Id, Name, Communication_Type__c,
                   Email_Subject__c, Email_Template_Id__c,
                   Messaging_Template_Id__c, Messaging_Channel_Id__c, Message_Body__c
            FROM Communication_Template__c
            WHERE Id = :rule.Messaging_Template__c
            LIMIT 1
        ];
        return comms.isEmpty() ? null : comms[0];
    }
}
