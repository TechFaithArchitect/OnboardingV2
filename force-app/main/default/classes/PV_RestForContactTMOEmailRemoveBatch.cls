@RestResource(urlMapping='/ContactTMOEmailRemove/*')
global with sharing class PV_RestForContactTMOEmailRemoveBatch {
    @HttpPost
     global static void updateContactEmail() {
        PV_ContactTMOEmailRemoveBatch batch = new PV_ContactTMOEmailRemoveBatch();
        Database.executeBatch(batch);
    }
}