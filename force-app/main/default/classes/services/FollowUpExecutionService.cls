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
                   Follow_Up_Type__c, Status__c,
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

        // TODO: Get Messaging Channel ID from Follow_Up_Rule__mdt when available
        // For now, use a placeholder or custom setting
        Id messagingChannelId = getDefaultMessagingChannelId();
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
            String messageContent = getMessageContent(followUp);

            // Send SMS
            String smsId = FollowUpMessagingService.sendSMS(
                dealerContact.Id,
                messageContent,
                messagingChannelId,
                null // TODO: Get template ID from Follow_Up_Rule__mdt when available
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

        // TODO: Implement email sending logic
        // Use EmailCommSenderService or similar
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
    private static String getMessageContent(Follow_Up_Queue__c followUp) {
        // TODO: Get from Follow_Up_Rule__mdt.Messaging_Template__c or similar
        // For now, return a default message
        return 'Please complete your onboarding requirement. If you have questions, contact your onboarding representative.';
    }

    /**
     * Get default messaging channel ID
     * TODO: Get from Custom Metadata or Custom Setting
     * @return MessagingChannel ID or null
     */
    private static Id getDefaultMessagingChannelId() {
        // TODO: Query Custom Metadata or Custom Setting for default SMS channel
        // For now, return null (will cause failure, which is expected until configured)
        return null;
    }
}