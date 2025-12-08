@isTest
private class VendorOnboardingWizardControllerTest {

    @isTest
    static void testVendorMethods() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        vendor.Name = 'Test Vendor';
        update vendor;
        
        Vendor__c newVendor = TestVendorFactory.createVendor(false);
        newVendor.Name = 'New Vendor';
        
        // Act
        Test.startTest();
        List<Vendor__c> searchResult = VendorOnboardingWizardController.searchVendors('Test');
        Id vendorId = VendorOnboardingWizardController.createVendor(newVendor);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, vendorId, 'Vendor ID should be returned');
    }

    @isTest
    static void testVendorProgramMethods() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        
        Vendor_Customization__c newProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, null, null, null, false);
        
        // Act
        Test.startTest();
        List<Vendor_Customization__c> searchResult = VendorOnboardingWizardController.searchVendorPrograms('Test');
        Id programId = VendorOnboardingWizardController.createVendorProgram(newProgram, vendor.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, programId, 'Program ID should be returned');
    }

    @isTest
    static void testVendorProgramGroupMethods() {
        // Arrange
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        
        Vendor_Program_Group__c newVendorProgramGroup = new Vendor_Program_Group__c();
        
        // Act
        Test.startTest();
        List<Vendor_Program_Group__c> searchResult = VendorOnboardingWizardController.searchVendorProgramGroups('Test');
        Id vendorProgramGroupId = VendorOnboardingWizardController.createVendorProgramGroup(newVendorProgramGroup);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, vendorProgramGroupId, 'Vendor Program Group ID should be returned');
    }

    @isTest
    static void testVendorProgramRequirementGroupMethods() {
        // Arrange
        Vendor_Program_Requirement_Group__c reqGroup = TestVendorProgramRequirementGroupFactory.create(true);
        
        Vendor_Program_Requirement_Group__c newReqGroup = new Vendor_Program_Requirement_Group__c();
        
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        
        // Act
        Test.startTest();
        List<Vendor_Program_Requirement_Group__c> searchResult = 
            VendorOnboardingWizardController.searchVendorProgramRequirementGroups('Test');
        Id reqGroupId = VendorOnboardingWizardController.createVendorProgramRequirementGroup(newReqGroup);
        VendorOnboardingWizardController.finalizeVendorProgram(
            vendorProgram.Id, vendor.Id, vendorProgramGroup.Id, reqGroupId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, reqGroupId, 'Requirement Group ID should be returned');
    }

    @isTest
    static void testVendorProgramRequirementMethods() {
        // Arrange
        Vendor_Program_Requirement__c req = TestVendorProgramRequirementFactory.create(true);
        
        Vendor_Program_Requirement__c newReq = new Vendor_Program_Requirement__c();
        
        // Act
        Test.startTest();
        List<Vendor_Program_Requirement__c> searchResult = 
            VendorOnboardingWizardController.searchVendorProgramRequirements('Test');
        Id reqId = VendorOnboardingWizardController.createVendorProgramRequirement(newReq);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, reqId, 'Requirement ID should be returned');
    }

    @isTest
    static void testStatusRulesEngineMethods() {
        // Arrange
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(true);
        engine.Name = 'Test Rules Engine';
        update engine;
        
        Onboarding_Status_Rules_Engine__c newEngine = new Onboarding_Status_Rules_Engine__c(
            Name = 'New Rules Engine',
            Evaluation_Logic__c = 'ALL'
        );
        
        // Act
        Test.startTest();
        List<Onboarding_Status_Rules_Engine__c> searchResult = 
            VendorOnboardingWizardController.searchStatusRulesEngines('Test');
        Id engineId = VendorOnboardingWizardController.createOnboardingStatusRulesEngine(newEngine);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, engineId, 'Engine ID should be returned');
    }

    @isTest
    static void testStatusRuleMethods() {
        // Arrange
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Status_Rule__c rule = TestOnboardingRulesFactory.create(true, engine, vpr, 'Complete', 1);
        
        Onboarding_Status_Rule__c newRule = new Onboarding_Status_Rule__c(
            Parent_Rule__c = engine.Id,
            Requirement__c = vpr.Id,
            Expected_Status__c = 'In Process',
            Rule_Number__c = 2
        );
        
        // Act
        Test.startTest();
        List<Onboarding_Status_Rule__c> searchResult = VendorOnboardingWizardController.searchStatusRules('Complete');
        Id ruleId = VendorOnboardingWizardController.createStatusRule(newRule);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, ruleId, 'Rule ID should be returned');
    }

    @isTest
    static void testCommunicationTemplateMethods() {
        // Arrange
        Communication_Template__c template = TestCommTemplateFactory.createTemplate(true);
        
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        
        // Act
        Test.startTest();
        List<Communication_Template__c> templates = VendorOnboardingWizardController.getCommunicationTemplates();
        VendorOnboardingWizardController.linkCommunicationTemplateToVendorProgram(vendorProgram.Id, template.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, templates, 'Templates should not be null');
    }

    @isTest
    static void testRequirementSetMethods() {
        // Arrange
        Onboarding_Requirement_Set__c reqSet = TestOnboardingRequirementSetFactory.create(true);
        Onboarding_Requirement_Set__c newReqSet = new Onboarding_Requirement_Set__c();
        
        Vendor_Program_Requirement_Group__c reqGroup = TestVendorProgramRequirementGroupFactory.create(true);
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(true, reqSet, reqGroup);
        
        // Act
        Test.startTest();
        Id reqSetId = VendorOnboardingWizardController.createOnboardingRequirementSet(newReqSet);
        List<Onboarding_Requirement_Set__c> reqSets = VendorOnboardingWizardController.getOnboardingRequirementSets();
        Id templateId = VendorOnboardingWizardController.createOnboardingRequirementTemplate(template);
        List<Vendor_Program_Onboarding_Req_Template__c> templates = 
            VendorOnboardingWizardController.getRequirementTemplatesForSet(reqSet.Id);
        VendorOnboardingWizardController.assignTemplatesToRequirementGroup(
            reqGroup.Id, new List<Id>{ templateId });
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, reqSetId, 'Requirement Set ID should be returned');
        System.assertNotEquals(null, reqSets, 'Requirement Sets should not be null');
        System.assertNotEquals(null, templateId, 'Template ID should be returned');
        System.assertNotEquals(null, templates, 'Templates should not be null');
    }

    @isTest
    static void testRecipientGroupMethods() {
        // Arrange
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(true);
        
        Recipient_Group__c newRecipientGroup = new Recipient_Group__c();
        
        // Act
        Test.startTest();
        List<Recipient_Group__c> searchResult = VendorOnboardingWizardController.searchRecipientGroups('Test');
        Id recipientGroupId = VendorOnboardingWizardController.createRecipientGroup(newRecipientGroup);
        Recipient_Group_Member__c memberToCreate = new Recipient_Group_Member__c(Recipient_Group__c = recipientGroupId);
        Id memberId = VendorOnboardingWizardController.createRecipientGroupMember(memberToCreate);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, recipientGroupId, 'Recipient Group ID should be returned');
        System.assertNotEquals(null, memberId, 'Member ID should be returned');
    }

    @isTest
    static void testVendorProgramRecipientGroupMethods() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(true);
        Vendor_Program_Recipient_Group__c vprg = TestVendorProgramRecipientGroupFactory.create(true);
        vprg.Vendor_Program__c = vendorProgram.Id;
        vprg.Recipient_Group__c = recipientGroup.Id;
        update vprg;
        
        // Act
        Test.startTest();
        List<Vendor_Program_Recipient_Group__c> searchResult = 
            VendorOnboardingWizardController.searchVendorProgramRecipientGroups('Test');
        Id linkId = VendorOnboardingWizardController.createVendorProgramRecipientGroupLink(vendorProgram.Id, recipientGroup.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, searchResult, 'Search result should not be null');
        System.assertNotEquals(null, linkId, 'Link ID should be returned');
    }

    @isTest
    static void testAssignableEntityMethods() {
        // Act
        Test.startTest();
        List<Territory_Role_Assignment__c> territoryRoles = 
            VendorOnboardingWizardController.getTerritoryRoleAssignments();
        List<User> users = VendorOnboardingWizardController.getAssignableUsers();
        List<Group> publicGroups = VendorOnboardingWizardController.getPublicGroups();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, territoryRoles, 'Territory roles should not be null');
        System.assertNotEquals(null, users, 'Users should not be null');
        System.assertNotEquals(null, publicGroups, 'Public groups should not be null');
    }

    @isTest
    static void testSyncRendererComponents() {
        // Act
        Test.startTest();
        VendorOnboardingWizardController.syncRendererComponents(new List<Id>());
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Sync should complete successfully');
    }
}

