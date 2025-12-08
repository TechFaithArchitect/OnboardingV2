public without sharing class ChuzoPersonAccountNewModalController {
    @AuraEnabled
    public static void createPersonAccount(String jsonRequest){
        try {
            ChuzoPersonAccountNewModalController.Wrapper wrapperRequest = (ChuzoPersonAccountNewModalController.Wrapper) JSON.deserialize(jsonRequest, ChuzoPersonAccountNewModalController.Wrapper.Class);
            Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            Account newPersonAccount = new Account();
            newPersonAccount.RecordTypeId = personAccountRecordTypeId;
            newPersonAccount.FirstName = wrapperRequest.firstName;
            newPersonAccount.LastName = wrapperRequest.lastName;
            newPersonAccount.BillingStreet =  wrapperRequest.streetLineOne;
            newPersonAccount.Billing_Address_Line_2__c = wrapperRequest.streetLineTwo;
            newPersonAccount.BillingCity = wrapperRequest.city;
            newPersonAccount.BillingStateCode = wrapperRequest.state;
            newPersonAccount.BillingCountry = wrapperRequest.country;
            newPersonAccount.BillingPostalCode = wrapperRequest.zip;
            newPersonAccount.ShippingStreet =  wrapperRequest.streetLineOne;
            newPersonAccount.Shipping_Address_Line_2__c = wrapperRequest.streetLineTwo;
            newPersonAccount.ShippingCity = wrapperRequest.city;
            newPersonAccount.ShippingStateCode = wrapperRequest.state;
            newPersonAccount.ShippingCountry = wrapperRequest.country;
            newPersonAccount.ShippingPostalCode = wrapperRequest.zip;
            newPersonAccount.PersonEmail = wrapperRequest.emailOne;
            newPersonAccount.POE_Alternate_Email__pc = wrapperRequest.emailTwo;
            newPersonAccount.Phone = wrapperRequest.phoneOne;
            newPersonAccount.PersonOtherPhone = wrapperRequest.phoneTwo;
            newPersonAccount.Lead_Origin__pc = wrapperRequest.leadOrigin;
            newPersonAccount.Lead_Origin_Other__pc = wrapperRequest.leadOrigin == 'Other' ? wrapperRequest.leadOriginOther : null;
            newPersonAccount.Program_Lead_Type__pc = wrapperRequest.programLeadType;
            newPersonAccount.Program_Lead_Type_Other__pc = wrapperRequest.programLeadType.contains('Other') ? wrapperRequest.programLeadTypeOther : null;
            newPersonAccount.Current_Provider_s__pc = wrapperRequest.currentProviders;
            newPersonAccount.Current_Provider_s_Cost__pc = wrapperRequest.currentProvidersCost;
            newPersonAccount.Under_Contract__pc = wrapperRequest.underContract;
            newPersonAccount.Contract_Expiration_Date__pc = wrapperRequest.contractExpirationDate;
            newPersonAccount.Suggested_Provider_s__pc = wrapperRequest.suggestedProviders;
            newPersonAccount.Suggested_Provider_s_Cost__pc = wrapperRequest.suggestedProvidersCost;
            newPersonAccount.First_Date_Contacted__pc = wrapperRequest.firstDateContacted;
            newPersonAccount.Second_Date_Contacted__pc = wrapperRequest.secondDateContacted;
            newPersonAccount.Third_Date_Contacted__pc = wrapperRequest.thirdDateContacted;
            newPersonAccount.Sold_Date__pc = wrapperRequest.soldDate;
            newPersonAccount.Rating__pc = wrapperRequest.rating;
            newPersonAccount.Opportunity_Stage__pc = wrapperRequest.stage;
            insert newPersonAccount;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private class Wrapper{
        private String firstName {get; set;}
        private String lastName {get; set;}
        private String streetLineOne {get; set;}
        private String streetLineTwo {get; set;}
        private String country {get; set;}
        private String city {get; set;}
        private String state {get; set;}
        private String zip {get; set;}
        private String phoneOne {get; set;}
        private String phoneTwo {get; set;}
        private String emailOne {get; set;}
        private String emailTwo {get; set;}
        private String leadOrigin {get; set;}
        private String leadOriginOther {get; set;}
        private String programLeadType {get; set;}
        private String programLeadTypeOther {get; set;}
        private String currentProviders {get; set;}
        private Decimal currentProvidersCost {get; set;}
        private Boolean underContract {get; set;}
        private Date contractExpirationDate {get; set;}
        private String suggestedProviders {get; set;}
        private Decimal suggestedProvidersCost {get; set;}
        private Date firstDateContacted {get; set;}
        private Date secondDateContacted {get; set;}
        private Date thirdDateContacted {get; set;}
        private Date soldDate {get; set;}
        private String stage {get; set;}
        private String rating {get; set;}
    }
}