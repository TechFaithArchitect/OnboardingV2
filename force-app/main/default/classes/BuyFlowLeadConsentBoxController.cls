public with sharing class BuyFlowLeadConsentBoxController {
    @AuraEnabled
    public static Boolean isHomeConciergeEnabled(String opportunityId) {
        Opportunity opp = [SELECT Id, Owner.Contact.Account.Home_Concierge_Enabled__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

        return opp.Owner.Contact.Account.Home_Concierge_Enabled__c;
    }
}