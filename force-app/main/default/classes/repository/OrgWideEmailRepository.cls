public with sharing class OrgWideEmailRepository {
    @TestVisible private static Map<String, OrgWideEmail__c> testMockEmails;

    public static void setMockEmails(Map<String, OrgWideEmail__c> mocks) {
        testMockEmails = mocks;
    }

    public static Map<String, OrgWideEmail__c> getAll() {
        if (Test.isRunningTest() && testMockEmails != null) {
            return testMockEmails;
        }

        Map<String, OrgWideEmail__c> result = new Map<String, OrgWideEmail__c>();
        for (OrgWideEmail__c o : [
            SELECT Id, Developer_Name__c, Email_Address__c, MasterLabel__c, Active__c
            FROM OrgWideEmail__c
        ]) {
            if (String.isNotBlank(o.Developer_Name__c)) {
                result.put(o.Developer_Name__c, o);
            }
        }
        return result;
    }

    public static void upsertEmails(List<OrgWideEmail__c> records) {
        if (records == null || records.isEmpty()) return;

        List<OrgWideEmail__c> toInsert = new List<OrgWideEmail__c>();
        List<OrgWideEmail__c> toUpdate = new List<OrgWideEmail__c>();

        Map<String, OrgWideEmail__c> existing = getAll();

        for (OrgWideEmail__c rec : records) {
            String key = rec.Developer_Name__c;
            if (existing.containsKey(key)) {
                OrgWideEmail__c old = existing.get(key);
                if (rec.Email_Address__c != old.Email_Address__c ||
                    rec.MasterLabel__c != old.MasterLabel__c ||
                    rec.Active__c != old.Active__c) {
                    rec.Id = old.Id;
                    toUpdate.add(rec);
                }
            } else {
                toInsert.add(rec);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }
}