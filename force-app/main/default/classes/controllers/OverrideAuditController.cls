/**
 * Controller to fetch override audit logs for admin dashboard.
 */
public with sharing class OverrideAuditController {
    @AuraEnabled(cacheable=true)
    public static List<OverrideLogDTO> getOverrideLogs(String dateRange) {
        List<OverrideLogDTO> logs = new List<OverrideLogDTO>();
        DateTime startDate = getStartDate(dateRange);

        List<Onboarding_External_Override_Log__c> records = [
            SELECT Id, Name, Onboarding__c, Onboarding__r.Name,
                   Override_Action__c, Source_System__c, Request_ID__c,
                   Reason__c, Allowed_Programs__c, Previous_Status__c, New_Status__c,
                   Requested_By__c, Processed_By__c, Processed_By__r.Name, Processed_Date__c
            FROM Onboarding_External_Override_Log__c
            WHERE CreatedDate >= :startDate
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];

        for (Onboarding_External_Override_Log__c rec : records) {
            OverrideLogDTO dto = new OverrideLogDTO();
            dto.id = rec.Id;
            dto.name = rec.Name;
            dto.onboardingName = rec.Onboarding__r != null ? rec.Onboarding__r.Name : null;
            dto.action = rec.Override_Action__c;
            dto.source = rec.Source_System__c;
            dto.requestId = rec.Request_ID__c;
            dto.reason = rec.Reason__c;
            dto.allowedPrograms = rec.Allowed_Programs__c;
            dto.previousStatus = rec.Previous_Status__c;
            dto.newStatus = rec.New_Status__c;
            dto.requestedBy = rec.Requested_By__c;
            dto.processedBy = rec.Processed_By__r != null ? rec.Processed_By__r.Name : null;
            dto.processedDate = rec.Processed_Date__c;
            logs.add(dto);
        }
        return logs;
    }

    private static DateTime getStartDate(String range) {
        if (range == 'LAST_7_DAYS') return DateTime.now().addDays(-7);
        if (range == 'LAST_30_DAYS') return DateTime.now().addDays(-30);
        if (range == 'LAST_90_DAYS') return DateTime.now().addDays(-90);
        return DateTime.now().addYears(-10);
    }

    public class OverrideLogDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String onboardingName;
        @AuraEnabled public String action;
        @AuraEnabled public String source;
        @AuraEnabled public String requestId;
        @AuraEnabled public String reason;
        @AuraEnabled public String allowedPrograms;
        @AuraEnabled public String previousStatus;
        @AuraEnabled public String newStatus;
        @AuraEnabled public String requestedBy;
        @AuraEnabled public String processedBy;
        @AuraEnabled public DateTime processedDate;
    }
}