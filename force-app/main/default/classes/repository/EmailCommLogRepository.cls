public with sharing class EmailCommLogRepository {
    
    /**
     * Inserts a new email communication log record.
     * @param log The Email_Communication_Log__c record to insert
     * @return The inserted record with Id populated
     */
    public static Email_Communication_Log__c insertLog(Email_Communication_Log__c log) {
        insert log;
        return log;
    }
    
    /**
     * Queries for matching email communication logs to detect duplicates.
     * @param contactId Contact ID
     * @param communicationTemplateId Communication Template ID
     * @param onboardingId Onboarding ID
     * @return List of matching logs from the last day
     */
    public static List<Email_Communication_Log__c> getMatchingLogs(
        Id contactId, 
        Id communicationTemplateId, 
        Id onboardingId
    ) {
        return [
            SELECT Id 
            FROM Email_Communication_Log__c
            WHERE Contact__c = :contactId
            AND Communication_Template__c = :communicationTemplateId
            AND Onboarding__c = :onboardingId
            AND CreatedDate = LAST_N_DAYS:1
            LIMIT 1
        ];
    }
}