@isTest
private class OnboardingRulesServiceTest {

    private static Onboarding__c createTestOnboarding() {
        TestDataFactoryWrapper.AccountContactWrapper accountContactWrapper = TestDataFactory.createAccountContact(true);
        TestDataFactoryWrapper.VendorCustomizationWrapper vendorCustomizationWrapper = TestDataFactory.createDraftVendorCustomizationWrapper(true);

        return TestDataFactory.createOnboarding(accountContactWrapper.account, vendorCustomizationWrapper.customization, true);
    }

    @isTest
    static void testCreateAllOnboardingRule_createsExpectedRules() {
        Onboarding__c onboarding = createTestOnboarding();

        Test.startTest();
        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper = TestDataFactory.createAllOnboardingRule(
            onboarding,
            2,
            'Setup Complete',
            true,
            true
        );
        Test.stopTest();

        List<Onboarding_Status_Rule__c> statusRules = [
            SELECT Id, Expected_Status__c, Rule_Number__c, Parent_Rule__c
            FROM Onboarding_Status_Rule__c
            WHERE Parent_Rule__c = :onboardingRulesSetupWrapper.ruleEngine.Id
        ];

        System.assertEquals(2, statusRules.size(), 'Should have created 2 rules');

        for (Integer i = 0; i < statusRules.size(); i++) {
            System.assertEquals('Setup Complete', statusRules[i].Expected_Status__c, 'Expected status should match');
            System.assertEquals(i + 1, statusRules[i].Rule_Number__c, 'Rule number should be sequential');
        }
    }

    @isTest
    static void testCreateAnyOnboardingRule_createsExpectedStatuses() {
        Onboarding__c onboarding = createTestOnboarding();

        Test.startTest();
        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper = TestDataFactory.createAnyOnboardingRule(
            onboarding,
            2,
            'Pending Initial Review',
            true,
            true
        );
        Test.stopTest();

        List<Onboarding_Status_Rule__c> statusRules = [
            SELECT Expected_Status__c
            FROM Onboarding_Status_Rule__c
            WHERE Parent_Rule__c = :onboardingRulesSetupWrapper.ruleEngine.Id
            ORDER BY Rule_Number__c
        ];

        System.assertEquals(2, statusRules.size(), 'Should have created 2 ANY rules');
        System.assertEquals('Setup Complete', statusRules[0].Expected_Status__c);
        System.assertEquals('In Process', statusRules[1].Expected_Status__c);
    }

    @isTest
    static void testCreateCustomOnboardingRule_withCustomLogic() {
        Onboarding__c onboarding = createTestOnboarding();
        List<String> expectedStatuses = new List<String>{ 'Setup Complete', 'Setup Complete', 'In Process' };

        Test.startTest();
        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper = TestDataFactory.createCustomOnboardingRule(
            onboarding,
            expectedStatuses,
            '1 && 2',
            'Pending Initial Review',
            true,
            true,
            3
        );
        Test.stopTest();

        Onboarding_Status_Rules_Engine__c rulesEngine = [
            SELECT Evaluation_Logic__c, Custom_Evaluation_Logic__c, Target_Onboarding_Status__c, Override_Status__c
            FROM Onboarding_Status_Rules_Engine__c
            WHERE Id = :onboardingRulesSetupWrapper.ruleEngine.Id
            LIMIT 1
        ];

        System.assertEquals('CUSTOM', rulesEngine.Evaluation_Logic__c);
        System.assertEquals('1 && 2', rulesEngine.Custom_Evaluation_Logic__c);
        System.assertEquals('Pending Initial Review', rulesEngine.Target_Onboarding_Status__c);
        System.assertEquals(true, rulesEngine.Override_Status__c);
    }

    @isTest
    static void testCreateAllOnboardingRule_createsRequirementsLinkedToCorrectTemplates() {
        Onboarding__c onboarding = createTestOnboarding();

        Test.startTest();
        TestDataFactoryWrapper.OnboardingRulesSetupWrapper onboardingRulesSetupWrapper = TestDataFactory.createAllOnboardingRule(
            onboarding,
            1,
            'Setup Complete',
            true,
            true
        );
        Test.stopTest();

        Onboarding_Requirement__c onboardingRequirement = onboardingRulesSetupWrapper.requirements[0];
        Onboarding_Requirement__c fetchedRequirement = [
            SELECT Id, Status__c, Vendor_Program_Requirement__r.Requirement_Template__r.Requirement_Label__c
            FROM Onboarding_Requirement__c
            WHERE Id = :onboardingRequirement.Id
        ];

        System.assertEquals('New', fetchedRequirement.Status__c);
        System.assertNotEquals(null, fetchedRequirement.Vendor_Program_Requirement__r.Requirement_Template__r.Requirement_Label__c);
    }
}