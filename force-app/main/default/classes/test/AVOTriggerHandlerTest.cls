@isTest
private class AVOTriggerHandlerTest {

    @isTest
    static void preventsCompleteWhenRequirementsOpen() {
        Account acct = TestDataFactory.createAccount('AVO Test', true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            TestVendorFactory.createVendor(true), 'Active', true, null, true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(acct, vendorProgram, true);

        // Create an open requirement
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, null);
        req.Status__c = 'In Process';
        update req;

        Account_Vendor_Program_Onboarding__c avo = new Account_Vendor_Program_Onboarding__c(
            Account__c = acct.Id,
            Onboarding__c = onboarding.Id,
            Status__c = 'Intake'
        );
        insert avo;

        avo.Status__c = 'Complete';

        Test.startTest();
        Database.SaveResult sr = Database.update(avo, false);
        Test.stopTest();

        System.assertEquals(false, sr.isSuccess(), 'Update should fail when requirements are open');
        System.assert(sr.getErrors()[0].getMessage().contains('open requirements'),
            'Error should mention open requirements');
    }

    @isTest
    static void allowsCompleteWhenRequirementsClosed() {
        Account acct = TestDataFactory.createAccount('AVO Closed Req', true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            TestVendorFactory.createVendor(true), 'Active', true, null, true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(acct, vendorProgram, true);

        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, null);
        req.Status__c = 'Complete';
        update req;

        Account_Vendor_Program_Onboarding__c avo = new Account_Vendor_Program_Onboarding__c(
            Account__c = acct.Id,
            Onboarding__c = onboarding.Id,
            Status__c = 'Intake'
        );
        insert avo;

        avo.Status__c = 'Complete';

        Test.startTest();
        update avo;
        Test.stopTest();
    }

    @isTest
    static void requiresReasonWhenClosedLost() {
        Account acct = TestDataFactory.createAccount('AVO Closed Lost', true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            TestVendorFactory.createVendor(true), 'Active', true, null, true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(acct, vendorProgram, true);

        Account_Vendor_Program_Onboarding__c avo = new Account_Vendor_Program_Onboarding__c(
            Account__c = acct.Id,
            Onboarding__c = onboarding.Id,
            Status__c = 'Intake'
        );
        insert avo;

        avo.Status__c = 'Closed Lost';

        Test.startTest();
        Database.SaveResult sr = Database.update(avo, false);
        Test.stopTest();

        System.assertEquals(false, sr.isSuccess(), 'Update should fail without reason');
        System.assert(sr.getErrors()[0].getMessage().contains('Reason for Return'),
            'Error should mention reason requirement');

        avo.Reason_for_Return__c = 'Customer withdrew';
        Test.startTest();
        update avo;
        Test.stopTest();
    }
}
