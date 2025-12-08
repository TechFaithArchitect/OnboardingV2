public with sharing class EmailCommDedupeUtil {
    @TestVisible
    private static List<Email_Communication_Log__c> getMatchingLogs(EmailCommSendRequestDTO req) {
        if (Test.isRunningTest() && mockLogs != null) {
            return mockLogs;
        } else {
            return EmailCommLogRepository.getMatchingLogs(
                req.contactId,
                req.communicationTemplateId,
                req.onboardingId
            );
        }
    }

    public static Boolean isDuplicate(EmailCommSendRequestDTO req) {
        List<Email_Communication_Log__c> matches = getMatchingLogs(req);
        return !matches.isEmpty();
    }
    
    @TestVisible private static List<Email_Communication_Log__c> mockLogs;
    public static void setMockLogs(List<Email_Communication_Log__c> mocks) {
        mockLogs = mocks;
    }
}
