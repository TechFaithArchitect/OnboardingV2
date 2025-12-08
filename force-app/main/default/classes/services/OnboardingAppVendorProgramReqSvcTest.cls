@isTest
private class OnboardingAppVendorProgramReqSvcTest {

    @isTest
    static void testCreateAndRetrieveRequiredCredential() {

        // -------------------------------
        // Setup Vendor Program
        // -------------------------------
        TestDataFactoryWrapper.VendorCustomizationWrapper wrapper =
            TestDataFactory.createDraftVendorCustomizationWrapper(true);

        // -------------------------------
        // Create test Required Credential
        // -------------------------------
        Required_Credential__c req = new Required_Credential__c(
            Is_Required__c = true,
            Notes__c = 'Test required credential',
            Sequence__c = 1,
            Vendor_Customization__c = wrapper.customization.Id
        );

        Test.startTest();
        Id createdId = OnboardingAppVendorProgramReqSvc.createRequiredCredential(req);
        List<Required_Credential__c> results =
            OnboardingAppVendorProgramReqSvc.getRequiredCredentials(wrapper.customization.Id);
        Test.stopTest();

        System.assertNotEquals(null, createdId,
            'Required Credential ID should not be null');
        System.assertEquals(1, results.size(),
            'Should return exactly 1 required credential');
    }


    @isTest
    static void testCreateAndRetrieveTrainingRequirement() {

        // -------------------------------
        // Setup Vendor Program
        // -------------------------------
        TestDataFactoryWrapper.VendorCustomizationWrapper wrapper =
            TestDataFactory.createDraftVendorCustomizationWrapper(true);

        // -------------------------------
        // Setup Training System
        // -------------------------------
        Training_System__c trainingSystem = TestTrainingSystemFactory.create(true);

        // -------------------------------
        // Create Training Requirement
        // -------------------------------
        Training_Requirement__c trainingRequirement = new Training_Requirement__c(
            External_Course_Code__c = 'COURSE-100',
            External_Course_Name__c = 'Test Course',
            Training_Code__c = 'INT-001',
            Sequence__c = 1,
            Is_Required__c = true,
            Vendor_Customization__c = wrapper.customization.Id,
            Training_System__c = trainingSystem.Id
        );

        Test.startTest();
        Id createdId = OnboardingAppVendorProgramReqSvc.createTrainingRequirement(trainingRequirement);
        List<Training_Requirement__c> results =
            OnboardingAppVendorProgramReqSvc.getTrainingRequirements(wrapper.customization.Id);
        Test.stopTest();

        System.assertNotEquals(null, createdId,
            'Training Requirement ID should not be null');
        System.assertEquals(1, results.size(),
            'Should return exactly 1 training requirement');
    }
}