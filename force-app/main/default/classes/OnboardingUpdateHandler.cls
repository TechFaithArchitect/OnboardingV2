public with sharing class OnboardingUpdateHandler {

    public class StatusUpdateInput {
        @InvocableVariable public Id contractId;
        @InvocableVariable public String contractStatus;

        @InvocableVariable public Id backgroundCheckId;
        @InvocableVariable public String backgroundCheckStatus;

        @InvocableVariable public Id businessLicenseId;
        @InvocableVariable public String businessLicenseStatus;

        @InvocableVariable public Id driversLicenseId;
        @InvocableVariable public String driversLicenseStatus;

        @InvocableVariable public Id clearingHouseId;
        @InvocableVariable public String clearingHouseStatus;

        @InvocableVariable public Id complianceId;
        @InvocableVariable public String complianceStatus;

        @InvocableVariable public Id creditCheckId;
        @InvocableVariable public String creditCheckStatus;

        @InvocableVariable public Id erpSetupId;
        @InvocableVariable public String erpSetupStatus;

        @InvocableVariable public Id laborFormId;
        @InvocableVariable public String laborFormStatus;

        @InvocableVariable public Id netTermsId;
        @InvocableVariable public String netTermsStatus;

        @InvocableVariable public Id personalGuaranteeId;
        @InvocableVariable public String personalGuaranteeStatus;

        @InvocableVariable public Id chuzoAgreementId;
        @InvocableVariable public String chuzoAgreementStatus;
    }

    @InvocableMethod(label = 'Update Status Fields Only')
    public static void updateStatuses(List<StatusUpdateInput> inputs) {
        List<Contract> contracts = new List<Contract>();
        List<Background_Check__c> backgrounds = new List<Background_Check__c>();
        List<License__c> licenses = new List<License__c>();
        List<Clearing_House__c> clearings = new List<Clearing_House__c>();
        List<Dealer_Compliance__c> compliances = new List<Dealer_Compliance__c>();
        List<Credit_Check__c> credits = new List<Credit_Check__c>();
        List<ERP_Setup__c> erps = new List<ERP_Setup__c>();
        List<Labor_Form__c> labors = new List<Labor_Form__c>();
        List<Net_Terms__c> netTerms = new List<Net_Terms__c>();
        List<Personal_Guarantee__c> guarantees = new List<Personal_Guarantee__c>();
        List<Chuzo_Agreement__c> chuzos = new List<Chuzo_Agreement__c>();

        for (StatusUpdateInput input : inputs) {
            if (isValid(input.contractId, input.contractStatus))
                contracts.add(new Contract(Id = input.contractId, Status = input.contractStatus));

            if (isValid(input.backgroundCheckId, input.backgroundCheckStatus))
                backgrounds.add(new Background_Check__c(Id = input.backgroundCheckId, Status__c = input.backgroundCheckStatus));

            if (isValid(input.businessLicenseId, input.businessLicenseStatus))
                licenses.add(new License__c(Id = input.businessLicenseId, Status__c = input.businessLicenseStatus));

            if (isValid(input.driversLicenseId, input.driversLicenseStatus))
                licenses.add(new License__c(Id = input.driversLicenseId, Status__c = input.driversLicenseStatus));

            if (isValid(input.clearingHouseId, input.clearingHouseStatus))
                clearings.add(new Clearing_House__c(Id = input.clearingHouseId, Status__c = input.clearingHouseStatus));

            if (isValid(input.complianceId, input.complianceStatus))
                compliances.add(new Dealer_Compliance__c(Id = input.complianceId, Status__c = input.complianceStatus));

            if (isValid(input.creditCheckId, input.creditCheckStatus))
                credits.add(new Credit_Check__c(Id = input.creditCheckId, Status__c = input.creditCheckStatus));

            if (isValid(input.erpSetupId, input.erpSetupStatus))
                erps.add(new ERP_Setup__c(Id = input.erpSetupId, Status__c = input.erpSetupStatus));

            if (isValid(input.laborFormId, input.laborFormStatus))
                labors.add(new Labor_Form__c(Id = input.laborFormId, Status__c = input.laborFormStatus));

            if (isValid(input.netTermsId, input.netTermsStatus))
                netTerms.add(new Net_Terms__c(Id = input.netTermsId, Status__c = input.netTermsStatus));

            if (isValid(input.personalGuaranteeId, input.personalGuaranteeStatus))
                guarantees.add(new Personal_Guarantee__c(Id = input.personalGuaranteeId, Status__c = input.personalGuaranteeStatus));

            if (isValid(input.chuzoAgreementId, input.chuzoAgreementStatus))
                chuzos.add(new Chuzo_Agreement__c(Id = input.chuzoAgreementId, Status__c = input.chuzoAgreementStatus));
        }

        try {
            if (!contracts.isEmpty()) update contracts;
            if (!backgrounds.isEmpty()) update backgrounds;
            if (!licenses.isEmpty()) update licenses;
            if (!clearings.isEmpty()) update clearings;
            if (!compliances.isEmpty()) update compliances;
            if (!credits.isEmpty()) update credits;
            if (!erps.isEmpty()) update erps;
            if (!labors.isEmpty()) update labors;
            if (!netTerms.isEmpty()) update netTerms;
            if (!guarantees.isEmpty()) update guarantees;
            if (!chuzos.isEmpty()) update chuzos;
        } catch (Exception ex) {
            System.debug('Error during status update: ' + ex.getMessage());
            // Optionally throw custom Flow error here if needed
        }
    }

    private static Boolean isValid(Id idVal, String statusVal) {
        // Ensure idVal is a valid 18-char Id and status is not blank
        return idVal != null &&
               String.valueOf(idVal).trim().length() == 18 &&
               String.isNotBlank(statusVal);
    }
}