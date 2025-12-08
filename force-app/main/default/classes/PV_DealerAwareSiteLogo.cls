public with sharing class PV_DealerAwareSiteLogo {
    @AuraEnabled(cacheable=true)
    public static String getSiteLogo() {
        User user = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        if (user.AccountId == null) {
            return null;
        }
        List<Account> accounts = [SELECT Logo_Content_Document_Id__c FROM Account WHERE Id = :user.AccountId];
        if (accounts.isEmpty() || accounts[0].Logo_Content_Document_Id__c == null) {
            return null;
        }
        List<ContentDocument> contentDocuments = [SELECT LatestPublishedVersion.VersionDataUrl FROM ContentDocument WHERE Id = :accounts[0].Logo_Content_Document_Id__c];
        return contentDocuments.isEmpty() ? null : contentDocuments[0].LatestPublishedVersion.VersionDataUrl;
    }
}