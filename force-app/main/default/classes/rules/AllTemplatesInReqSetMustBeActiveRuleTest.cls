@isTest
private class AllTemplatesInReqSetMustBeActiveRuleTest {

    @isTest
    static void testApply_WithAllActiveTemplates_ShouldPass() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Create active template
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(true);
        template.Active__c = true;
        update template;

        // Create requirement with active template
        Vendor_Program_Requirement__c req = TestDataFactory.createVendorProgramRequirement(
            vendorProgram, true, true
        );
        req.Requirement_Template__c = template.Id;
        update req;

        AllTemplatesInReqSetMustBeActiveRule rule = new AllTemplatesInReqSetMustBeActiveRule();

        Test.startTest();
        // Should not throw exception
        rule.apply(vendorProgram.Id, 'Vendor_Customization__c');
        Test.stopTest();

        System.assert(true, 'Should pass when all templates are active');
    }

    @isTest
    static void testApply_WithInactiveTemplate_ShouldThrow() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Create inactive template
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(true);
        template.Active__c = false;
        update template;

        // Create requirement with inactive template
        Vendor_Program_Requirement__c req = TestDataFactory.createVendorProgramRequirement(
            vendorProgram, true, true
        );
        req.Requirement_Template__c = template.Id;
        update req;

        AllTemplatesInReqSetMustBeActiveRule rule = new AllTemplatesInReqSetMustBeActiveRule();

        Test.startTest();
        try {
            rule.apply(vendorProgram.Id, 'Vendor_Customization__c');
            System.assert(false, 'Should throw exception for inactive template');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive template');
        }
        Test.stopTest();
    }

    @isTest
    static void testApply_WithNoRequirements_ShouldPass() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        AllTemplatesInReqSetMustBeActiveRule rule = new AllTemplatesInReqSetMustBeActiveRule();

        Test.startTest();
        // Should not throw exception when no requirements exist
        rule.apply(vendorProgram.Id, 'Vendor_Customization__c');
        Test.stopTest();

        System.assert(true, 'Should pass when no requirements exist');
    }

    @isTest
    static void testApply_WithNullTemplate_ShouldPass() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Create requirement without template (null template)
        Vendor_Program_Requirement__c req = TestDataFactory.createVendorProgramRequirement(
            vendorProgram, true, true
        );
        req.Requirement_Template__c = null;
        update req;

        AllTemplatesInReqSetMustBeActiveRule rule = new AllTemplatesInReqSetMustBeActiveRule();

        Test.startTest();
        // Should not throw exception when template is null (skipped)
        rule.apply(vendorProgram.Id, 'Vendor_Customization__c');
        Test.stopTest();

        System.assert(true, 'Should pass when template is null');
    }

    @isTest
    static void testApplyBulk_WithMixedActiveInactive_ShouldThrow() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c program1 = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );
        Vendor_Customization__c program2 = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Program 1: active template
        Vendor_Program_Onboarding_Req_Template__c activeTemplate = TestVdrPrgrmOnboardingReqTemplateFactory.create(true);
        activeTemplate.Active__c = true;
        update activeTemplate;
        Vendor_Program_Requirement__c req1 = TestDataFactory.createVendorProgramRequirement(
            program1, true, true
        );
        req1.Requirement_Template__c = activeTemplate.Id;
        update req1;

        // Program 2: inactive template
        Vendor_Program_Onboarding_Req_Template__c inactiveTemplate = TestVdrPrgrmOnboardingReqTemplateFactory.create(true);
        inactiveTemplate.Active__c = false;
        update inactiveTemplate;
        Vendor_Program_Requirement__c req2 = TestDataFactory.createVendorProgramRequirement(
            program2, true, true
        );
        req2.Requirement_Template__c = inactiveTemplate.Id;
        update req2;

        AllTemplatesInReqSetMustBeActiveRule rule = new AllTemplatesInReqSetMustBeActiveRule();

        Test.startTest();
        try {
            rule.applyBulk(new Set<Id>{ program1.Id, program2.Id }, 'Vendor_Customization__c');
            System.assert(false, 'Should throw exception for inactive template');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive template');
        }
        Test.stopTest();
    }

    @isTest
    static void testApplyBulk_WithEmptySet_ShouldNotThrow() {
        AllTemplatesInReqSetMustBeActiveRule rule = new AllTemplatesInReqSetMustBeActiveRule();

        Test.startTest();
        rule.applyBulk(new Set<Id>(), 'Vendor_Customization__c');
        rule.applyBulk(null, 'Vendor_Customization__c');
        Test.stopTest();

        System.assert(true, 'Should handle empty set gracefully');
    }
}