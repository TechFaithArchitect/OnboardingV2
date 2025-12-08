public without sharing class FSL_PicklistValuesController {
    
    @AuraEnabled
    public static String getAvailableVendors() {

        Id accountId = [SELECT Id, Contact.Account.Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Contact.Account.Id;
        String availableVendors = [SELECT Id, Available_FSL_Vendors__c FROM Account WHERE Id = :accountId LIMIT 1].Available_FSL_Vendors__c;

        return availableVendors;
    }

}