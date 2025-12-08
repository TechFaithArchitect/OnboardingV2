public with sharing class OnboardingGetDataHandler {
    public class ResultWrapper {
        @InvocableVariable public Onboarding__c onboardingRecord;
        @InvocableVariable public Contract contractRecord;
        @InvocableVariable public Background_Check__c backgroundCheckRecord;
        @InvocableVariable public License__c businessLicenseRecord;
        @InvocableVariable public Clearing_House__c clearingHouseRecord;
        @InvocableVariable public Dealer_Compliance__c complianceRecord;
        @InvocableVariable public Credit_Check__c creditCheckRecord;
        @InvocableVariable public License__c driversLicenseRecord;
        @InvocableVariable public ERP_Setup__c erpSetupRecord;
        @InvocableVariable public Id learnUponContactEnrollmentId;
        @InvocableVariable public String learnUponStatus;
        @InvocableVariable public Labor_Form__c laborFormRecord;
        @InvocableVariable public Net_Terms__c netTermsRecord;
    }

    @InvocableMethod(label='Get Onboarding Related Records')
    public static List<ResultWrapper> getRelatedRecords(List<Id> recordIds) {
        List<ResultWrapper> results = new List<ResultWrapper>();

        List<Onboarding__c> onboardingRecords = [
            SELECT Id, Name,
                Assigned_Team__c,
                Contract__r.Id, Contract__r.Status, Contract__r.Contract_Type__c,
                Background_Check__r.Id, Background_Check__r.Status__c, Background_Check__r.Account__r.Name,
                Business_License__r.Id, Business_License__r.Status__c,
                Clearing_House__r.Id, Clearing_House__r.Status__c,
                Compliance__r.Id, Compliance__r.Status__c,
                Credit_Check__r.Id, Credit_Check__r.Status__c,
                Drivers_License__r.Id, Drivers_License__r.Status__c,
                ERP_Setup__r.Id, ERP_Setup__r.Status__c,
                Labor_Form__r.Id, Labor_Form__r.Status__c,
                LearnUponContactEnrollment__r.Id, LearnUponContactEnrollment__r.LearnUponP__Status__c,
                Net_Terms__r.Id, Net_Terms__r.Status__c
            FROM Onboarding__c
            WHERE Id IN :recordIds
        ];

        for (Onboarding__c ob : onboardingRecords) {
            ResultWrapper wrap = new ResultWrapper();
            wrap.onboardingRecord = ob;
            wrap.contractRecord = ob.Contract__r;
            wrap.backgroundCheckRecord = ob.Background_Check__r;
            wrap.businessLicenseRecord = ob.Business_License__r;
            wrap.clearingHouseRecord = ob.Clearing_House__r;
            wrap.complianceRecord = ob.Compliance__r;
            wrap.creditCheckRecord = ob.Credit_Check__r;
            wrap.driversLicenseRecord = ob.Drivers_License__r;
            wrap.erpSetupRecord = ob.ERP_Setup__r;
            wrap.learnUponContactEnrollmentId = ob.LearnUponContactEnrollment__r.Id;
            wrap.learnUponStatus = ob.LearnUponContactEnrollment__r.LearnUponP__Status__c;
            wrap.laborFormRecord = ob.Labor_Form__r;
            wrap.netTermsRecord = ob.Net_Terms__r;
            results.add(wrap);
        }

        return results;
    }
}