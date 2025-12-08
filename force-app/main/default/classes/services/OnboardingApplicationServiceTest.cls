@isTest
private class OnboardingApplicationServiceTest {

    @isTest
    static void testSaveProgress() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;

        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Display_Order__c = 1,
            Onboarding_Application_Process__c = process.Id
        );
        insert stage;

        Test.startTest();
        Id progressId = OnboardingApplicationService.saveProgress(process.Id, vendorProgram.Id, stage.Id);
        Test.stopTest();

        System.assertNotEquals(null, progressId, 'Progress ID should be returned from service');
    }
}