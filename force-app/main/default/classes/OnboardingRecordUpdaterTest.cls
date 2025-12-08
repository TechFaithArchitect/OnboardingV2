@IsTest
private class OnboardingRecordUpdaterTest {
    @IsTest static void testRun_withAllStatuses() {
        // 1) Create parent Account
        Account acct = new Account(Name = 'Test Acct');
        insert acct;

        // 2) Insert Onboarding__c (MD lookup)
        Onboarding__c ob = new Onboarding__c(
            Assigned_Team__c = 'Sales',
            Account__c      = acct.Id
        );
        insert ob;
        
        // 3) Prepare the wrapper with new values
        OnboardingRecordUpdater.OnboardingUpdateWrapper wrapper =
            new OnboardingRecordUpdater.OnboardingUpdateWrapper();
        wrapper.OnboardingRecordId                 = ob.Id;
        wrapper.OnboardingAssignedTeam             = 'Sales';
        wrapper.ContractStatus                     = 'Draft';
        wrapper.CreditCheckStatus                  = 'Incomplete';
        wrapper.ComplianceStatus                   = 'In Progress';
        wrapper.BackgroundCheckStatus              = 'Incomplete';
        wrapper.BusinessLicenseStatus              = 'Complete';
        wrapper.ClearingHouseStatus                = 'Incomplete';
        wrapper.DriversLicenseStatus               = 'Complete';
        wrapper.ERPSetupStatus                     = 'Complete';
        wrapper.LaborFormStatus                    = 'Incomplete';
        wrapper.NetTermsStatus                     = 'Incomplete';
        wrapper.VendorOrderEntryPlatformStatus     = 'Incomplete';
        wrapper.PersonalGuaranteeStatus            = 'Not Started';
        wrapper.ChuzoAgreementStatus               = 'Not Started';
        wrapper.TermsConditionsStatus              = 'Not Started';
        wrapper.OnboardingInsuranceStatus          = 'Complete';
        
        // 4) Call the invocable method
        Test.startTest();
            OnboardingRecordUpdater.run(
                new List<OnboardingRecordUpdater.OnboardingUpdateWrapper>{ wrapper }
            );
        Test.stopTest();
        
        // 5) Verify updates
        ob = [SELECT
                Assigned_Team__c,
                Contract_Status__c,
                Credit_Check_Status__c,
                Compliance_Status__c,
                Background_Check_Status__c,
                Business_License_Status__c,
                Clearing_House_Status__c,
                Drivers_Licenses_Status__c,
                ERP_Setup_Status__c,
                Labor_Form_Status__c,
                Net_Terms_Status__c,
                Vendor_Order_Entry_Setup_Status__c,
                Personal_Guarantee_Status__c,
                Chuzo_Agreement_Status__c,
                Terms_Conditions_Status__c,
                Insurance_Status__c
              FROM Onboarding__c
              WHERE Id = :ob.Id];
              
        System.assertEquals('Sales',      ob.Assigned_Team__c);
        System.assertEquals('Draft',      ob.Contract_Status__c);
        System.assertEquals('Incomplete', ob.Credit_Check_Status__c);
        System.assertEquals('In Progress', ob.Compliance_Status__c);
        System.assertEquals('Incomplete', ob.Background_Check_Status__c);
        System.assertEquals('Complete',   ob.Business_License_Status__c);
        System.assertEquals('Incomplete',   ob.Clearing_House_Status__c);
        System.assertEquals('Complete',   ob.Drivers_Licenses_Status__c);
        System.assertEquals('Complete',   ob.ERP_Setup_Status__c);
        System.assertEquals('Incomplete', ob.Labor_Form_Status__c);
        System.assertEquals('Incomplete', ob.Net_Terms_Status__c);
        System.assertEquals('Incomplete', ob.Vendor_Order_Entry_Setup_Status__c);
        System.assertEquals('Not Started',ob.Personal_Guarantee_Status__c);
        System.assertEquals('Not Started',ob.Chuzo_Agreement_Status__c);
        System.assertEquals('Not Started',ob.Terms_Conditions_Status__c);
        System.assertEquals('Complete',   ob.Insurance_Status__c);
    }
}