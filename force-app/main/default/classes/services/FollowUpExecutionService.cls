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

        Id messagingChannelId = getIdIfValid(rule != null ? rule.Messaging_Channel__c : null);
        if (messagingChannelId == null) {
            markFollowUpFailed(followUpQueueId, 'No messaging channel configured');
            return;
        }

        // Check if Contact has active messaging endpoint
        if (!FollowUpMessagingService.hasActiveMessagingEndpoint(dealerContact.Id, messagingChannelId)) {
            markFollowUpFailed(followUpQueueId, 'No active messaging endpoint for contact');
            return;
        }

        try {
            // Get message content
            String messageContent = getMessageContent(followUp, rule);

            // Send SMS
            String smsId = FollowUpMessagingService.sendSMS(
                dealerContact.Id,
                messageContent,
                messagingChannelId,
                getIdIfValid(rule != null ? rule.Messaging_Template__c : null)
            );

            // Update Follow_Up_Queue__c
            followUp.Status__c = 'Sent';
            followUp.Last_Attempt_Date__c = DateTime.now();
            followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
            followUp.Consecutive_Failures__c = 0; // Reset on success
            
            // TODO: Store SMS tracking ID if field exists
            // followUp.SMS_Tracking_Id__c = smsId;
            
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
                   Follow_Up_Type__c, Status__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];

        // Placeholder: implement actual email logic when EmailCommSenderService or Messaging Email is available
        markFollowUpFailed(followUpQueueId, 'Email follow-up not yet implemented');
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
    private static void markFollowUpFailed(Id followUpQueueId, String errorMessage) {
        Follow_Up_Queue__c followUp = [
            SELECT Id, Status__c, Consecutive_Failures__c, Attempt_Count__c, Last_Attempt_Date__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];

        followUp.Status__c = 'Failed';
        followUp.Consecutive_Failures__c = (followUp.Consecutive_Failures__c == null ? 0 : followUp.Consecutive_Failures__c) + 1;
        followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
        followUp.Last_Attempt_Date__c = DateTime.now();
        
        // TODO: Store error message if field exists
        // followUp.Error_Message__c = errorMessage;
        
        update followUp;
    }

    /**
     * Get message content for follow-up
     * TODO: Get from Follow_Up_Rule__mdt template when available
     * @param followUp Follow_Up_Queue__c record
     * @return Message content string
     */
    private static String getMessageContent(Follow_Up_Queue__c followUp, Follow_Up_Rule__mdt rule) {
        // If using templates, this would render template content; for now use rule metadata as source
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
}
