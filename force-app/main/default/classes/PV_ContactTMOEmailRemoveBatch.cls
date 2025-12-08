public class PV_ContactTMOEmailRemoveBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,name,TMO_Email__c FROM contact where TMO_Email__c != null';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Contact> contactList){
        List<Contact> updatedContactList = new List<Contact>();
        for(Contact contacts: contactList){
            contacts.TMO_Email__c = '';
            updatedContactList.add(contacts);
        }
        update updatedContactList;
    }
    
    public void finish(Database.BatchableContext BC){
    }
}