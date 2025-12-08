/**
 * Controller for Onboarding Admin Dashboard
 * Provides system health metrics and monitoring data
 */
public with sharing class OnboardingAdminDashboardController {

    /**
     * Get system health metrics for the admin dashboard
     * @return SystemHealthMetrics wrapper with all metrics
     */
    @AuraEnabled(cacheable=true)
    public static SystemHealthMetrics getSystemHealthMetrics() {
        SystemHealthMetrics metrics = new SystemHealthMetrics();
        
        // Validation failures (last 24 hours)
        DateTime last24h = DateTime.now().addHours(-24);
        DateTime last48h = DateTime.now().addHours(-48);
        
        // Count validation failures in last 24h
        // Note: Validation_Failure__c object will be created in Phase 1
        // For now, return 0 or query from existing failure tracking
        metrics.validationFailures24h = getValidationFailureCount(last24h);
        metrics.validationFailuresTrend = metrics.validationFailures24h - getValidationFailureCount(last48h);
        
        // Message failures (last 24 hours)
        metrics.messageFailures24h = getMessageFailureCount(last24h);
        metrics.messageFailuresTrend = metrics.messageFailures24h - getMessageFailureCount(last48h);
        
        // Webhook failures (last 24 hours)
        // Note: AdobeSyncFailure__c will be created in Phase 3
        metrics.webhookFailures24h = getWebhookFailureCount(last24h);
        metrics.webhookFailuresTrend = metrics.webhookFailures24h - getWebhookFailureCount(last48h);
        
        // Platform Event volume (last hour)
        DateTime last1h = DateTime.now().addHours(-1);
        metrics.platformEventVolume1h = getPlatformEventVolume(last1h);
        
        // Active follow-up queues
        metrics.activeFollowUpQueues = getActiveFollowUpQueueCount();
        
        // Override operations (last 7 days)
        // Note: Onboarding_External_Override_Log__c will be created in Phase 4
        DateTime last7d = DateTime.now().addDays(-7);
        metrics.overrideOperations7d = getOverrideOperationCount(last7d);
        
        return metrics;
    }

    /**
     * Get validation failure count for time period
     * Placeholder - will query Validation_Failure__c in Phase 1
     */
    private static Integer getValidationFailureCount(DateTime since) {
        // TODO: Query Validation_Failure__c when object is created
        // SELECT COUNT() FROM Validation_Failure__c WHERE CreatedDate >= :since AND Status__c = 'Failed'
        return 0;
    }

    /**
     * Get message failure count from Follow_Up_Queue__c
     */
    private static Integer getMessageFailureCount(DateTime since) {
        try {
            return [
                SELECT COUNT()
                FROM Follow_Up_Queue__c
                WHERE Status__c = 'Failed'
                  AND CreatedDate >= :since
                LIMIT 10000
            ];
        } catch (Exception e) {
            System.debug('Error counting message failures: ' + e.getMessage());
            return 0;
        }
    }

    /**
     * Get webhook failure count
     * Placeholder - will query AdobeSyncFailure__c in Phase 3
     */
    private static Integer getWebhookFailureCount(DateTime since) {
        // TODO: Query AdobeSyncFailure__c when object is created
        // SELECT COUNT() FROM AdobeSyncFailure__c WHERE CreatedDate >= :since AND Status__c != 'Resolved'
        return 0;
    }

    /**
     * Get Platform Event volume
     * Note: Platform Event monitoring requires Event Monitoring (Salesforce Shield)
     */
    private static Integer getPlatformEventVolume(DateTime since) {
        // Platform Event volume monitoring requires Event Monitoring
        // For now, return 0 or implement custom tracking
        // TODO: Implement Platform Event volume tracking via Event Monitoring or custom object
        return 0;
    }

    /**
     * Get count of active follow-up queues
     */
    private static Integer getActiveFollowUpQueueCount() {
        try {
            return [
                SELECT COUNT()
                FROM Follow_Up_Queue__c
                WHERE Status__c IN ('Pending', 'Pending Retry')
                  AND Is_Archived__c = false
                LIMIT 10000
            ];
        } catch (Exception e) {
            System.debug('Error counting active follow-up queues: ' + e.getMessage());
            return 0;
        }
    }

    /**
     * Get override operation count
     * Placeholder - will query Onboarding_External_Override_Log__c in Phase 4
     */
    private static Integer getOverrideOperationCount(DateTime since) {
        // TODO: Query Onboarding_External_Override_Log__c when object is created
        // SELECT COUNT() FROM Onboarding_External_Override_Log__c WHERE Processed_Date__c >= :since
        return 0;
    }

    /**
     * Get validation failures with filtering and grouping
     * Note: Validation_Failure__c object will be created in Phase 1
     * @param groupBy Grouping option: 'rule', 'user', or 'requirement'
     * @param filters Map of filter criteria
     * @return List of ValidationFailureDTO records
     */
    @AuraEnabled(cacheable=false)
    public static List<ValidationFailureDTO> getValidationFailures(String groupBy, Map<String, Object> filters) {
        // TODO: Query Validation_Failure__c when object is created in Phase 1
        // For now, return empty list
        List<ValidationFailureDTO> failures = new List<ValidationFailureDTO>();
        
        /*
        DateTime startDate = getStartDateForFilter((String)filters.get('dateRange'));
        
        String query = 'SELECT Id, Name, Rule_Name__c, Requirement_Field__c, Status__c, ' +
                      'Error_Message__c, CreatedDate, Retry_Count__c, ' +
                      'Requirement_Field__r.Name, CreatedBy.Name ' +
                      'FROM Validation_Failure__c ' +
                      'WHERE Status__c = \'Failed\' ' +
                      'AND CreatedDate >= :startDate ' +
                      'ORDER BY CreatedDate DESC ' +
                      'LIMIT 1000';
        
        List<Validation_Failure__c> records = Database.query(query);
        for (Validation_Failure__c failure : records) {
            failures.add(new ValidationFailureDTO(failure));
        }
        */
        
        return failures;
    }

    /**
     * Retry validation for a specific failure
     * @param failureId Validation_Failure__c record ID
     * @return Success message
     */
    @AuraEnabled
    public static String retryValidation(Id failureId) {
        // TODO: Implement retry logic when Validation_Failure__c is created
        // This will trigger re-validation of the field value
        return 'Retry initiated (to be implemented in Phase 1)';
    }

    /**
     * Get start date for filter
     */
    private static DateTime getStartDateForFilter(String filter) {
        if (filter == 'LAST_24_HOURS') {
            return DateTime.now().addHours(-24);
        } else if (filter == 'LAST_7_DAYS') {
            return DateTime.now().addDays(-7);
        } else if (filter == 'LAST_30_DAYS') {
            return DateTime.now().addDays(-30);
        }
        return DateTime.now().addYears(-10); // All time
    }

    /**
     * Wrapper class for system health metrics
     */
    public class SystemHealthMetrics {
        @AuraEnabled public Integer validationFailures24h = 0;
        @AuraEnabled public Integer validationFailuresTrend = 0;
        @AuraEnabled public Integer messageFailures24h = 0;
        @AuraEnabled public Integer messageFailuresTrend = 0;
        @AuraEnabled public Integer webhookFailures24h = 0;
        @AuraEnabled public Integer webhookFailuresTrend = 0;
        @AuraEnabled public Integer platformEventVolume1h = 0;
        @AuraEnabled public Integer activeFollowUpQueues = 0;
        @AuraEnabled public Integer overrideOperations7d = 0;
    }

    /**
     * DTO for validation failure records
     */
    public class ValidationFailureDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String ruleName;
        @AuraEnabled public String requirementFieldName;
        @AuraEnabled public String status;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public Integer retryCount;

        public ValidationFailureDTO() {
            // Default constructor for AuraEnabled
        }

        // TODO: Add constructor that takes Validation_Failure__c when object is created
        /*
        public ValidationFailureDTO(Validation_Failure__c failure) {
            this.id = failure.Id;
            this.ruleName = failure.Rule_Name__c;
            this.requirementFieldName = failure.Requirement_Field__r?.Name;
            this.status = failure.Status__c;
            this.errorMessage = failure.Error_Message__c;
            this.createdDate = failure.CreatedDate;
            this.retryCount = failure.Retry_Count__c != null ? failure.Retry_Count__c.intValue() : 0;
        }
        */
    }

    /**
     * Get messaging issues from Follow_Up_Queue__c
     * @param groupBy Grouping option: 'type', 'status', or 'onboarding'
     * @param filters Map of filter criteria
     * @return List of MessagingIssueDTO records
     */
    @AuraEnabled(cacheable=false)
    public static List<MessagingIssueDTO> getMessagingIssues(String groupBy, Map<String, Object> filters) {
        List<MessagingIssueDTO> issues = new List<MessagingIssueDTO>();
        
        DateTime startDate = getStartDateForFilter((String)filters.get('dateRange'));
        String statusFilter = (String)filters.get('status');
        String typeFilter = (String)filters.get('type');
        
        String query = 'SELECT Id, Name, Follow_Up_Type__c, Status__c, ' +
                      'Onboarding__c, Onboarding__r.Name, ' +
                      'Onboarding__r.Account__c, Onboarding__r.Account__r.Name, ' +
                      'Trigger_Reason__c, CreatedDate, ' +
                      'Attempt_Count__c, Last_Attempt_Date__c, ' +
                      'Consecutive_Failures__c ' +
                      'FROM Follow_Up_Queue__c ' +
                      'WHERE CreatedDate >= :startDate ' +
                      'AND Is_Archived__c = false ';
        
        if (statusFilter != null && statusFilter != '') {
            query += 'AND Status__c = :statusFilter ';
        } else {
            // Default to showing failed and pending retry
            query += 'AND Status__c IN (\'Failed\', \'Pending Retry\', \'Pending\') ';
        }
        
        if (typeFilter != null && typeFilter != '') {
            query += 'AND Follow_Up_Type__c = :typeFilter ';
        }
        
        query += 'ORDER BY CreatedDate DESC LIMIT 1000';
        
        List<Follow_Up_Queue__c> records = Database.query(query);
        for (Follow_Up_Queue__c issue : records) {
            issues.add(new MessagingIssueDTO(issue));
        }
        
        return issues;
    }

    /**
     * Retry messaging for a specific issue
     * @param issueId Follow_Up_Queue__c record ID
     * @return Success message
     */
    @AuraEnabled
    public static String retryMessaging(Id issueId) {
        try {
            Follow_Up_Queue__c issue = [
                SELECT Id, Status__c, Attempt_Count__c
                FROM Follow_Up_Queue__c
                WHERE Id = :issueId
                LIMIT 1
            ];
            
            // Reset status to Pending Retry
            issue.Status__c = 'Pending Retry';
            issue.Attempt_Count__c = (issue.Attempt_Count__c == null ? 0 : issue.Attempt_Count__c) + 1;
            update issue;
            
            // TODO: Trigger Platform Event or Queueable to retry the messaging
            // FollowUpRetryTrigger__e event = new FollowUpRetryTrigger__e(Follow_Up_Queue_Id__c = issueId);
            // EventBus.publish(event);
            
            return 'Retry initiated successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retry messaging: ' + e.getMessage());
        }
    }

    /**
     * Dismiss a messaging issue
     * @param issueId Follow_Up_Queue__c record ID
     * @return Success message
     */
    @AuraEnabled
    public static String dismissMessagingIssue(Id issueId) {
        try {
            Follow_Up_Queue__c issue = [
                SELECT Id, Status__c
                FROM Follow_Up_Queue__c
                WHERE Id = :issueId
                LIMIT 1
            ];
            
            issue.Status__c = 'Resolved';
            issue.Is_Archived__c = true;
            update issue;
            
            return 'Issue dismissed successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Failed to dismiss issue: ' + e.getMessage());
        }
    }

    /**
     * DTO for messaging issue records
     */
    public class MessagingIssueDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String followUpType;
        @AuraEnabled public String status;
        @AuraEnabled public String onboardingId;
        @AuraEnabled public String onboardingName;
        @AuraEnabled public String accountName;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer attemptCount;
        @AuraEnabled public DateTime lastAttemptDate;
        @AuraEnabled public DateTime createdDate;

        public MessagingIssueDTO(Follow_Up_Queue__c issue) {
            this.id = issue.Id;
            this.followUpType = issue.Follow_Up_Type__c;
            this.status = issue.Status__c;
            this.onboardingId = issue.Onboarding__c;
            this.onboardingName = issue.Onboarding__r?.Name;
            this.accountName = issue.Onboarding__r?.Account__r?.Name;
            this.errorMessage = issue.Trigger_Reason__c; // Using Trigger_Reason__c as error message placeholder
            this.attemptCount = issue.Attempt_Count__c != null ? issue.Attempt_Count__c.intValue() : 0;
            this.lastAttemptDate = issue.Last_Attempt_Date__c;
            this.createdDate = issue.CreatedDate;
        }
    }

    /**
     * Get Adobe sync failures
     * Note: AdobeSyncFailure__c object will be created in Phase 3
     * @param groupBy Grouping option: 'type', 'status', or 'onboarding'
     * @param filters Map of filter criteria
     * @return List of AdobeSyncFailureDTO records
     */
    @AuraEnabled(cacheable=false)
    public static List<AdobeSyncFailureDTO> getAdobeSyncFailures(String groupBy, Map<String, Object> filters) {
        // TODO: Query AdobeSyncFailure__c when object is created in Phase 3
        // For now, return empty list
        List<AdobeSyncFailureDTO> failures = new List<AdobeSyncFailureDTO>();
        
        /*
        DateTime startDate = getStartDateForFilter((String)filters.get('dateRange'));
        String statusFilter = (String)filters.get('status');
        String typeFilter = (String)filters.get('type');
        
        String query = 'SELECT Id, Name, Failure_Type__c, Status__c, ' +
                      'Onboarding__c, Onboarding__r.Name, ' +
                      'Onboarding__r.Account__c, Onboarding__r.Account__r.Name, ' +
                      'Error_Message__c, CreatedDate, ' +
                      'Retry_Count__c, Last_Retry_Date__c ' +
                      'FROM AdobeSyncFailure__c ' +
                      'WHERE CreatedDate >= :startDate ' +
                      'AND Status__c != \'Resolved\' ';
        
        if (statusFilter != null && statusFilter != '') {
            query += 'AND Status__c = :statusFilter ';
        }
        
        if (typeFilter != null && typeFilter != '') {
            query += 'AND Failure_Type__c = :typeFilter ';
        }
        
        query += 'ORDER BY CreatedDate DESC LIMIT 1000';
        
        List<AdobeSyncFailure__c> records = Database.query(query);
        for (AdobeSyncFailure__c failure : records) {
            failures.add(new AdobeSyncFailureDTO(failure));
        }
        */
        
        return failures;
    }

    /**
     * Retry Adobe sync for a specific failure
     * @param failureId AdobeSyncFailure__c record ID
     * @return Success message
     */
    @AuraEnabled
    public static String retryAdobeSync(Id failureId) {
        // TODO: Implement retry logic when AdobeSyncFailure__c is created
        // This will trigger Platform Event to retry the webhook
        return 'Retry initiated (to be implemented in Phase 3)';
    }

    /**
     * Mark Adobe sync failure as resolved
     * @param failureId AdobeSyncFailure__c record ID
     * @return Success message
     */
    @AuraEnabled
    public static String resolveAdobeSyncFailure(Id failureId) {
        // TODO: Implement resolve logic when AdobeSyncFailure__c is created
        return 'Failure resolved (to be implemented in Phase 3)';
    }

    /**
     * DTO for Adobe sync failure records
     */
    public class AdobeSyncFailureDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String failureType;
        @AuraEnabled public String status;
        @AuraEnabled public String onboardingId;
        @AuraEnabled public String onboardingName;
        @AuraEnabled public String accountName;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer retryCount;
        @AuraEnabled public DateTime lastRetryDate;
        @AuraEnabled public DateTime createdDate;

        public AdobeSyncFailureDTO() {
            // Default constructor for AuraEnabled
        }

        // TODO: Add constructor that takes AdobeSyncFailure__c when object is created
        /*
        public AdobeSyncFailureDTO(AdobeSyncFailure__c failure) {
            this.id = failure.Id;
            this.failureType = failure.Failure_Type__c;
            this.status = failure.Status__c;
            this.onboardingId = failure.Onboarding__c;
            this.onboardingName = failure.Onboarding__r?.Name;
            this.accountName = failure.Onboarding__r?.Account__r?.Name;
            this.errorMessage = failure.Error_Message__c;
            this.retryCount = failure.Retry_Count__c != null ? failure.Retry_Count__c.intValue() : 0;
            this.lastRetryDate = failure.Last_Retry_Date__c;
            this.createdDate = failure.CreatedDate;
        }
        */
    }
}

