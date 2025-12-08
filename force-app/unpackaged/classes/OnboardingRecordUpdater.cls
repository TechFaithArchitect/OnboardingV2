public class OnboardingRecordUpdater {
    
    @InvocableMethod(label='Onboarding Record Updater')
    public static void run(List<OnboardingUpdateWrapper> inputList) {
        List<Onboarding__c> onboardingToUpdate = new List<Onboarding__c>();

        for (OnboardingUpdateWrapper input : inputList) {
            if (input.OnboardingRecordId == null) {
                System.debug('Skipping record with no OnboardingRecordId');
                continue;
            }

            Onboarding__c ob = new Onboarding__c(Id = input.OnboardingRecordId);
            System.debug('Preparing update for Onboarding__c Id: ' + input.OnboardingRecordId);

            if (input.OnboardingAssignedTeam != null) {
                ob.Assigned_Team__c = input.OnboardingAssignedTeam;
                System.debug('Assigned_Team__c = ' + input.OnboardingAssignedTeam);
            }
            if (input.OnboardingInsuranceStatus != null) {
                ob.Insurance_Status__c = input.OnboardingInsuranceStatus;
                System.debug('Insurance_Status__c = ' + input.OnboardingInsuranceStatus);
            }
            if (input.ContractStatus != null) {
                ob.Contract_Status__c = input.ContractStatus;
                System.debug('Contract_Status__c = ' + input.ContractStatus);
            }
            if (input.CreditCheckStatus != null) {
                ob.Credit_Check_Status__c = input.CreditCheckStatus;
                System.debug('Credit_Check_Status__c = ' + input.CreditCheckStatus);
            }
            if (input.ComplianceStatus != null) {
                ob.Compliance_Status__c = input.ComplianceStatus;
                System.debug('Compliance_Status__c = ' + input.ComplianceStatus);
            }
            if (input.BackgroundCheckStatus != null) {
                ob.Background_Check_Status__c = input.BackgroundCheckStatus;
                System.debug('Background_Check_Status__c = ' + input.BackgroundCheckStatus);
            }
            if (input.BusinessLicenseStatus != null) {
                ob.Business_License_Status__c = input.BusinessLicenseStatus;
                System.debug('Business_License_Status__c = ' + input.BusinessLicenseStatus);
            }
            if (input.ClearingHouseStatus != null) {
                ob.Clearing_House_Status__c = input.ClearingHouseStatus;
                System.debug('Clearing_House_Status__c = ' + input.ClearingHouseStatus);
            }
            if (input.DriversLicenseStatus != null) {
                ob.Drivers_Licenses_Status__c = input.DriversLicenseStatus;
                System.debug('Drivers_Licenses_Status__c = ' + input.DriversLicenseStatus);
            }
            if (input.ERPSetupStatus != null) {
                ob.ERP_Setup_Status__c = input.ERPSetupStatus;
                System.debug('ERP_Setup_Status__c = ' + input.ERPSetupStatus);
            }
            if (input.LaborFormStatus != null) {
                ob.Labor_Form_Status__c = input.LaborFormStatus;
                System.debug('Labor_Form_Status__c = ' + input.LaborFormStatus);
            }
            if (input.NetTermsStatus != null) {
                ob.Net_Terms_Status__c = input.NetTermsStatus;
                System.debug('Net_Terms_Status__c = ' + input.NetTermsStatus);
            }
            if (input.VendorOrderEntryPlatformStatus != null) {
                ob.Vendor_Order_Entry_Setup_Status__c = input.VendorOrderEntryPlatformStatus;
                System.debug('Vendor_Order_Entry_Setup_Status__c = ' + input.VendorOrderEntryPlatformStatus);
            }
            if (input.PersonalGuaranteeStatus != null) {
                ob.Personal_Guarantee_Status__c = input.PersonalGuaranteeStatus;
                System.debug('Personal_Guarantee_Status__c = ' + input.PersonalGuaranteeStatus);
            }
            if (input.ChuzoAgreementStatus != null) {
                ob.Chuzo_Agreement_Status__c = input.ChuzoAgreementStatus;
                System.debug('Chuzo_Agreement_Status__c = ' + input.ChuzoAgreementStatus);
            }
            if (input.TermsConditionsStatus != null) {
                ob.Terms_Conditions_Status__c = input.TermsConditionsStatus;
                System.debug('Terms_Conditions_Status__c = ' + input.TermsConditionsStatus);
            }
            if (input.InterviewStatus != null) {
                ob.Interview_Status__c = input.InterviewStatus;
                System.debug('Interview_Status__c = ' + input.InterviewStatus);
            }               
            onboardingToUpdate.add(ob);
        }

        if (!onboardingToUpdate.isEmpty()) {
            System.debug('Updating ' + onboardingToUpdate.size() + ' onboarding records.');
            update onboardingToUpdate;
        } else {
            System.debug('No onboarding records to update.');
        }
    }

    public class OnboardingUpdateWrapper {
        @InvocableVariable public Id OnboardingRecordId;
        @InvocableVariable public String OnboardingAssignedTeam;
        @InvocableVariable public String OnboardingInsuranceStatus;
        @InvocableVariable public String ContractStatus;
        @InvocableVariable public String CreditCheckStatus;
        @InvocableVariable public String ComplianceStatus;
        @InvocableVariable public String BackgroundCheckStatus;
        @InvocableVariable public String BusinessLicenseStatus;
        @InvocableVariable public String ClearingHouseStatus;
        @InvocableVariable public String DriversLicenseStatus;
        @InvocableVariable public String ERPSetupStatus;
        @InvocableVariable public String LaborFormStatus;
        @InvocableVariable public String NetTermsStatus;
        @InvocableVariable public String VendorOrderEntryPlatformStatus;
        @InvocableVariable public String PersonalGuaranteeStatus;
        @InvocableVariable public String ChuzoAgreementStatus;
        @InvocableVariable public String TermsConditionsStatus;
        @InvocableVariable public String InterviewStatus;
    }
}