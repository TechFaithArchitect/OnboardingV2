@isTest
private class OnboardingStatusRuleControllerTest {

    @isTest
    static void testGetRules() {
        // Arrange
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            true, null, vendorProgramGroup, 'ALL', null, 'In Process');
        
        // Act
        Test.startTest();
        List<Onboarding_Status_Rules_Engine__c> result = OnboardingStatusRuleController.getRules(vendorProgramGroup.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return rules');
        System.assertEquals(vendorProgramGroup.Id, result[0].Vendor_Program_Group__c, 'Should filter by vendor program group');
    }

    @isTest
    static void testGetRule() {
        // Arrange
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true);
        rule.Custom_Evaluation_Logic__c = '1 AND 2';
        update rule;
        
        // Act
        Test.startTest();
        Onboarding_Status_Rules_Engine__c result = OnboardingStatusRuleController.getRule(rule.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(rule.Id, result.Id, 'Should return correct rule');
        System.assertEquals('1 AND 2', result.Custom_Evaluation_Logic__c, 'Should include custom logic');
    }

    @isTest
    static void testGetConditions() {
        // Arrange
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Status_Rule__c condition1 = TestOnboardingRulesFactory.create(true, rule, vpr, 'Complete', 1);
        Onboarding_Status_Rule__c condition2 = TestOnboardingRulesFactory.create(true, rule, vpr, 'In Process', 2);
        
        // Act
        Test.startTest();
        List<Onboarding_Status_Rule__c> result = OnboardingStatusRuleController.getConditions(rule.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 2, 'Should return conditions');
        System.assertEquals(1, result[0].Rule_Number__c, 'Should be ordered by rule number');
    }

    @isTest
    static void testSaveRule() {
        // Arrange
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Onboarding_Status_Rules_Engine__c rule = new Onboarding_Status_Rules_Engine__c(
            Vendor_Program_Group__c = vendorProgramGroup.Id,
            Evaluation_Logic__c = 'ALL',
            Override_Status__c = true
        );
        
        // Act
        Test.startTest();
        OnboardingStatusRuleController.saveRule(rule);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, rule.Id, 'Rule should have an ID');
        Onboarding_Status_Rules_Engine__c saved = [
            SELECT Id, Evaluation_Logic__c, Override_Status__c 
            FROM Onboarding_Status_Rules_Engine__c 
            WHERE Id = :rule.Id
        ];
        System.assertEquals('ALL', saved.Evaluation_Logic__c, 'Evaluation logic should be saved');
        System.assertEquals(true, saved.Override_Status__c, 'Override status should be saved');
    }

    @isTest
    static void testSaveConditions() {
        // Arrange
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Status_Rule__c condition1 = TestOnboardingRulesFactory.create(false, rule, vpr, 'Complete', 1);
        Onboarding_Status_Rule__c condition2 = TestOnboardingRulesFactory.create(false, rule, vpr, 'In Process', 2);
        List<Onboarding_Status_Rule__c> conditions = new List<Onboarding_Status_Rule__c>{ condition1, condition2 };
        
        // Act
        Test.startTest();
        OnboardingStatusRuleController.saveConditions(conditions);
        Test.stopTest();
        
        // Assert
        List<Onboarding_Status_Rule__c> saved = [
            SELECT Id, Rule_Number__c, Expected_Status__c 
            FROM Onboarding_Status_Rule__c 
            WHERE Parent_Rule__c = :rule.Id
            ORDER BY Rule_Number__c
        ];
        System.assert(saved.size() >= 2, 'Should save conditions');
    }

    @isTest
    static void testDeleteCondition() {
        // Arrange
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Status_Rule__c condition = TestOnboardingRulesFactory.create(true, rule, vpr, 'Complete', 1);
        
        // Act
        Test.startTest();
        OnboardingStatusRuleController.deleteCondition(condition.Id);
        Test.stopTest();
        
        // Assert
        List<Onboarding_Status_Rule__c> remaining = [
            SELECT Id 
            FROM Onboarding_Status_Rule__c 
            WHERE Id = :condition.Id
        ];
        System.assertEquals(0, remaining.size(), 'Condition should be deleted');
    }
}