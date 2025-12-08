@isTest
private class OnboardingStatusEvaluatorTest {

    private static Onboarding__c createTestOnboarding() {
        TestDataFactoryWrapper.AccountContactWrapper accountContactWrapper = TestDataFactory.createAccountContact(true);
        TestDataFactoryWrapper.VendorCustomizationWrapper vendorCustomizationWrapper = TestDataFactory.createDraftVendorCustomizationWrapper(true);

        return TestDataFactory.createOnboarding(accountContactWrapper.account, vendorCustomizationWrapper.customization, true);
    }

    @isTest
    static void testEvaluateAndApplyStatusWithProgress_FallbackComplete() {
        Onboarding__c onboarding = createTestOnboarding();

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper setup =
            TestDataFactory.createAllOnboardingRule(
                onboarding,
                2,
                'IgnoredByFallback',
                false, // override off so rules won't apply
                true
            );

        for (Onboarding_Requirement__c req : setup.requirements) {
            req.Status__c = 'Setup Complete';
        }
        update setup.requirements;

        Test.startTest();
        OnboardingStatusEvaluator.evaluateAndApplyStatusWithProgress(onboarding);
        Test.stopTest();

        onboarding = [SELECT Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals('Setup Complete', onboarding.Onboarding_Status__c);
    }

    @isTest
    static void testEvaluateAndApplyStatusWithProgress_FallbackInProcess() {
        Onboarding__c onboarding = createTestOnboarding();

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper setup =
            TestDataFactory.createAllOnboardingRule(
                onboarding,
                2,
                'IgnoredByFallback',
                false,
                true
            );

        setup.requirements[0].Status__c = 'In Process';
        setup.requirements[1].Status__c = 'New';
        update setup.requirements;

        Test.startTest();
        OnboardingStatusEvaluator.evaluateAndApplyStatusWithProgress(onboarding);
        Test.stopTest();

        onboarding = [SELECT Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals('In Process', onboarding.Onboarding_Status__c);
    }

    @isTest
    static void testEvaluateAndApplyStatus_ALL() {
        Onboarding__c onboarding = createTestOnboarding();

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper =
            TestDataFactory.createAllOnboardingRule(
                onboarding,
                2,
                'In Process',
                true,
                true
            );

        // Set requirements to match expected rule state
        for (Onboarding_Requirement__c onboardingRequirement : onboardingRulesSetupWrapper.requirements) {
            onboardingRequirement.Status__c = 'Setup Complete';
        }
        update onboardingRulesSetupWrapper.requirements;

        Test.startTest();
        OnboardingStatusEvaluator.evaluateAndApplyStatus(onboarding);
        Test.stopTest();

        onboarding = [SELECT Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals('In Process', onboarding.Onboarding_Status__c);
    }

    @isTest
    static void testEvaluateAndApplyStatus_ANY() {
        Onboarding__c onboarding = createTestOnboarding();

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper =
            TestDataFactory.createAnyOnboardingRule(
                onboarding,
                3,
                'Pending Initial Review',
                true,
                true
            );

        onboardingRulesSetupWrapper.requirements[0].Status__c = 'Setup Complete';
        onboardingRulesSetupWrapper.requirements[1].Status__c = 'New';
        onboardingRulesSetupWrapper.requirements[2].Status__c = 'New';
        update onboardingRulesSetupWrapper.requirements;

        Test.startTest();
        OnboardingStatusEvaluator.evaluateAndApplyStatus(onboarding);
        Test.stopTest();

        onboarding = [SELECT Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals('Pending Initial Review', onboarding.Onboarding_Status__c);
    }

    @isTest
    static void testEvaluateAndApplyStatus_CUSTOM() {
        Onboarding__c onboarding = createTestOnboarding();

        List<String> expectedStatuses = new List<String>{ 'Setup Complete', 'Setup Complete', 'In Process' };

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper =
            TestDataFactory.createCustomOnboardingRule(
                onboarding,
                expectedStatuses,
                '1 && 2',
                'Pending Initial Review',
                true,
                true,
                3
            );

        onboardingRulesSetupWrapper.requirements[0].Status__c = 'Setup Complete';
        onboardingRulesSetupWrapper.requirements[1].Status__c = 'Setup Complete';
        onboardingRulesSetupWrapper.requirements[2].Status__c = 'New';
        update onboardingRulesSetupWrapper.requirements;

        Test.startTest();
        OnboardingStatusEvaluator.evaluateAndApplyStatus(onboarding);
        Test.stopTest();

        onboarding = [SELECT Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals('Pending Initial Review', onboarding.Onboarding_Status__c);
    }

    @isTest
    static void testEvaluateAndApplyStatus_NoMatch() {
        Onboarding__c onboarding = createTestOnboarding();

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper =
            TestDataFactory.createAllOnboardingRule(
                onboarding,
                2,
                'Pending Sales',
                true,
                true
            );

        for (Onboarding_Requirement__c onboardingRequirement : onboardingRulesSetupWrapper.requirements) {
            onboardingRequirement.Status__c = 'New';
        }
        update onboardingRulesSetupWrapper.requirements;

        Test.startTest();
        OnboardingStatusEvaluator.evaluateAndApplyStatus(onboarding);
        Test.stopTest();

        onboarding = [SELECT Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals(null, onboarding.Onboarding_Status__c);
    }

    @isTest
    static void testEvaluateAndApplyStatus_OverrideFalse() {
        Onboarding__c onboarding = createTestOnboarding();

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper =
            TestDataFactory.createAllOnboardingRule(
                onboarding,
                2,
                'Setup Complete',
                false,   // SHOULD NOT override
                true
            );

        for (Onboarding_Requirement__c onboardingRequirement : onboardingRulesSetupWrapper.requirements) {
            onboardingRequirement.Status__c = 'Setup Complete';
        }
        update onboardingRulesSetupWrapper.requirements;

        Test.startTest();
        OnboardingStatusEvaluator.evaluateAndApplyStatus(onboarding);
        Test.stopTest();

        onboarding = [SELECT Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals(null, onboarding.Onboarding_Status__c);
    }
}