@isTest
private class OnboardingRuleEvaluatorTest {

    @isTest
    static void testEvaluateRule_ALL_True() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestAccountFactory.create('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = 'Complete';
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = 'Complete';
        update req2;
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, 'ALL', null, 'In Process');
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, 'Complete', 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, 'Complete', 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c 
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'ALL logic should return true when all conditions match');
    }

    @isTest
    static void testEvaluateRule_ALL_False() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestAccountFactory.create('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = 'Complete';
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = 'New'; // Different status
        update req2;
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, 'ALL', null, 'In Process');
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, 'Complete', 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, 'Complete', 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c 
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'ALL logic should return false when not all conditions match');
    }

    @isTest
    static void testEvaluateRule_ANY_True() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestAccountFactory.create('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = 'Complete';
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = 'New';
        update req2;
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, 'ANY', null, 'In Process');
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, 'Complete', 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, 'Complete', 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c 
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'ANY logic should return true when at least one condition matches');
    }

    @isTest
    static void testEvaluateRule_ANY_False() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestAccountFactory.create('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = 'New';
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = 'New';
        update req2;
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, 'ANY', null, 'In Process');
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, 'Complete', 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, 'Complete', 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c 
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'ANY logic should return false when no conditions match');
    }

    @isTest
    static void testEvaluateRule_CUSTOM() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestAccountFactory.create('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = 'Complete';
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = 'New';
        update req2;
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, 'CUSTOM', null, 'In Process');
        rule.Custom_Evaluation_Logic__c = '1 OR 2';
        update rule;
        
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, 'Complete', 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, 'Complete', 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c 
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert - Since rule1 matches (Complete = Complete) and rule2 doesn't (New != Complete),
        // expression becomes "true OR false" which should evaluate to true
        System.assertEquals(true, result, 'CUSTOM logic should evaluate expression correctly');
    }

    @isTest
    static void testEvaluate_SimpleExpression() {
        // Act
        Test.startTest();
        Boolean result1 = OnboardingRuleEvaluator.evaluate('true');
        Boolean result2 = OnboardingRuleEvaluator.evaluate('false');
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result1, 'Should evaluate true expression');
        System.assertEquals(false, result2, 'Should evaluate false expression');
    }

    @isTest
    static void testEvaluate_WithContext() {
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluate('true', new Map<String, Object>());
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Should evaluate expression with context');
    }

    @isTest
    static void testEvaluateRule_MissingRequirement() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, 'ALL', null, 'In Process');
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, 'Complete', 1);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c 
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        // Empty map - requirement doesn't exist
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>();
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should return false when requirement is missing');
    }

    @isTest
    static void testEvaluateRule_InvalidLogic() {
        // Arrange
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, 'INVALID', null, 'In Process');
        rule.Evaluation_Logic__c = 'INVALID';
        update rule;
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c 
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>();
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should return false for invalid logic');
    }
}