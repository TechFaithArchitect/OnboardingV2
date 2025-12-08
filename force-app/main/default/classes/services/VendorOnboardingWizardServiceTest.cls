@isTest
private class VendorOnboardingWizardServiceTest {

    @isTest
    static void testSearchVendors() {
        // Arrange
        Vendor__c vendor1 = TestVendorFactory.createVendor(true);
        vendor1.Name = 'Test Vendor Search';
        update vendor1;
        
        // Act
        Test.startTest();
        List<Vendor__c> result = VendorOnboardingWizardService.searchVendors('Test Vendor');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should find vendors');
    }

    @isTest
    static void testCreateVendor() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(false);
        vendor.Name = 'New Test Vendor';
        
        // Act
        Test.startTest();
        Id vendorId = VendorOnboardingWizardService.createVendor(vendor);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, vendorId, 'Vendor ID should be returned');
        Vendor__c created = [SELECT Id, Active__c FROM Vendor__c WHERE Id = :vendorId];
        System.assertEquals(false, created.Active__c, 'Vendor should be saved as draft');
    }

    @isTest
    static void testSearchVendorPrograms() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        
        // Act
        Test.startTest();
        List<Vendor_Customization__c> result = VendorOnboardingWizardService.searchVendorPrograms('Test Vendor');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testCreateVendorProgram() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, null, null, null, false);
        
        // Act
        Test.startTest();
        Id programId = VendorOnboardingWizardService.createVendorProgram(vendorProgram, vendor.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, programId, 'Program ID should be returned');
        Vendor_Customization__c created = [SELECT Id, Vendor__c, Active__c, Status__c 
                                           FROM Vendor_Customization__c WHERE Id = :programId];
        System.assertEquals(vendor.Id, created.Vendor__c, 'Should link to vendor');
        System.assertEquals(false, created.Active__c, 'Should be saved as draft');
        System.assertEquals('Draft', created.Status__c, 'Status should be Draft');
    }

    @isTest
    static void testSearchVendorProgramGroups() {
        // Arrange
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        
        // Act
        Test.startTest();
        List<Vendor_Program_Group__c> result = VendorOnboardingWizardService.searchVendorProgramGroups('Test Group');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testCreateVendorProgramGroup() {
        // Arrange
        Vendor_Program_Group__c vendorProgramGroup = new Vendor_Program_Group__c();
        
        // Act
        Test.startTest();
        Id vendorProgramGroupId = VendorOnboardingWizardService.createVendorProgramGroup(vendorProgramGroup);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, vendorProgramGroupId, 'Vendor Program Group ID should be returned');
    }

    @isTest
    static void testSearchVendorProgramRequirementGroups() {
        // Arrange
        Vendor_Program_Requirement_Group__c reqGroup = TestVendorProgramRequirementGroupFactory.create(true);
        
        // Act
        Test.startTest();
        List<Vendor_Program_Requirement_Group__c> result = VendorOnboardingWizardService.searchVendorProgramRequirementGroups('Test Requirement');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testCreateVendorProgramRequirementGroup() {
        // Arrange
        Vendor_Program_Requirement_Group__c reqGroup = new Vendor_Program_Requirement_Group__c();
        
        // Act
        Test.startTest();
        Id reqGroupId = VendorOnboardingWizardService.createVendorProgramRequirementGroup(reqGroup);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, reqGroupId, 'Requirement Group ID should be returned');
    }

    @isTest
    static void testFinalizeVendorProgram() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true);
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Vendor_Program_Requirement_Group__c reqGroup = TestVendorProgramRequirementGroupFactory.create(true);
        
        // Act
        Test.startTest();
        VendorOnboardingWizardService.finalizeVendorProgram(
            vendorProgram.Id, vendor.Id, vendorProgramGroup.Id, reqGroup.Id
        );
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Finalization should complete successfully');
    }

    @isTest
    static void testSearchVendorProgramRequirements() {
        // Arrange
        Vendor_Program_Requirement__c req = TestVendorProgramRequirementFactory.create(true);
        
        // Act
        Test.startTest();
        List<Vendor_Program_Requirement__c> result = VendorOnboardingWizardService.searchVendorProgramRequirements('Test Requirement');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testCreateVendorProgramRequirement() {
        // Arrange
        Vendor_Program_Requirement__c req = new Vendor_Program_Requirement__c();
        
        // Act
        Test.startTest();
        Id reqId = VendorOnboardingWizardService.createVendorProgramRequirement(req);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, reqId, 'Requirement ID should be returned');
    }

    @isTest
    static void testSearchStatusRulesEngines() {
        // Arrange
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(true);
        engine.Name = 'Test Rules Engine Search';
        update engine;
        
        // Act
        Test.startTest();
        List<Onboarding_Status_Rules_Engine__c> result = VendorOnboardingWizardService.searchStatusRulesEngines('Test Rules');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testCreateOnboardingStatusRulesEngine() {
        // Arrange
        Onboarding_Status_Rules_Engine__c engine = new Onboarding_Status_Rules_Engine__c(
            Name = 'New Test Rules Engine',
            Evaluation_Logic__c = 'ALL'
        );
        
        // Act
        Test.startTest();
        Id engineId = VendorOnboardingWizardService.createOnboardingStatusRulesEngine(engine);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, engineId, 'Engine ID should be returned');
    }

    @isTest
    static void testCreateStatusRule() {
        // Arrange
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Status_Rule__c rule = new Onboarding_Status_Rule__c(
            Parent_Rule__c = engine.Id,
            Requirement__c = vpr.Id,
            Expected_Status__c = 'Complete',
            Rule_Number__c = 1
        );
        
        // Act
        Test.startTest();
        Id ruleId = VendorOnboardingWizardService.createStatusRule(rule);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, ruleId, 'Rule ID should be returned');
    }

    @isTest
    static void testSearchStatusRules() {
        // Arrange
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Status_Rule__c rule = TestOnboardingRulesFactory.create(true, engine, vpr, 'Complete', 1);
        
        // Act
        Test.startTest();
        List<Onboarding_Status_Rule__c> result = VendorOnboardingWizardService.searchStatusRules('Complete');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetCommunicationTemplates() {
        // Act
        Test.startTest();
        List<Communication_Template__c> result = VendorOnboardingWizardService.getCommunicationTemplates();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testLinkCommunicationTemplateToVendorProgram() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Communication_Template__c template = TestCommTemplateFactory.createTemplate(true);
        
        // Act
        Test.startTest();
        VendorOnboardingWizardService.linkCommunicationTemplateToVendorProgram(vendorProgram.Id, template.Id);
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Link should complete successfully');
    }

    @isTest
    static void testCreateOnboardingRequirementSet() {
        // Arrange
        Onboarding_Requirement_Set__c reqSet = new Onboarding_Requirement_Set__c();
        
        // Act
        Test.startTest();
        Id reqSetId = VendorOnboardingWizardService.createOnboardingRequirementSet(reqSet);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, reqSetId, 'Requirement Set ID should be returned');
        Onboarding_Requirement_Set__c created = [SELECT Id, Status__c FROM Onboarding_Requirement_Set__c WHERE Id = :reqSetId];
        System.assertEquals('Draft', created.Status__c, 'Status should be Draft');
    }

    @isTest
    static void testGetOnboardingRequirementSets() {
        // Act
        Test.startTest();
        List<Onboarding_Requirement_Set__c> result = VendorOnboardingWizardService.getOnboardingRequirementSets();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testCreateOnboardingRequirementTemplate() {
        // Arrange
        Onboarding_Requirement_Set__c reqSet = TestOnboardingRequirementSetFactory.create(true);
        Vendor_Program_Requirement_Group__c reqGroup = TestVendorProgramRequirementGroupFactory.create(true);
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(false, reqSet, reqGroup);
        
        // Act
        Test.startTest();
        Id templateId = VendorOnboardingWizardService.createOnboardingRequirementTemplate(template);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, templateId, 'Template ID should be returned');
    }

    @isTest
    static void testGetRequirementTemplatesForSet() {
        // Arrange
        Onboarding_Requirement_Set__c reqSet = TestOnboardingRequirementSetFactory.create(true);
        
        // Act
        Test.startTest();
        List<Vendor_Program_Onboarding_Req_Template__c> result = VendorOnboardingWizardService.getRequirementTemplatesForSet(reqSet.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testAssignTemplatesToRequirementGroup() {
        // Arrange
        Vendor_Program_Requirement_Group__c reqGroup = TestVendorProgramRequirementGroupFactory.create(true);
        Onboarding_Requirement_Set__c reqSet = TestOnboardingRequirementSetFactory.create(true);
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(true, reqSet, reqGroup);
        List<Id> templateIds = new List<Id>{ template.Id };
        
        // Act
        Test.startTest();
        VendorOnboardingWizardService.assignTemplatesToRequirementGroup(reqGroup.Id, templateIds);
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Assignment should complete successfully');
    }

    @isTest
    static void testSearchRecipientGroups() {
        // Arrange
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(true);
        
        // Act
        Test.startTest();
        List<Recipient_Group__c> result = VendorOnboardingWizardService.searchRecipientGroups('Test Recipient');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testCreateRecipientGroup() {
        // Arrange
        Recipient_Group__c recipientGroup = new Recipient_Group__c();
        
        // Act
        Test.startTest();
        Id recipientGroupId = VendorOnboardingWizardService.createRecipientGroup(recipientGroup);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, recipientGroupId, 'Recipient Group ID should be returned');
    }

    @isTest
    static void testCreateRecipientGroupMember() {
        // Arrange
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(true);
        Recipient_Group_Member__c member = new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup.Id
        );
        
        // Act
        Test.startTest();
        Id memberId = VendorOnboardingWizardService.createRecipientGroupMember(member);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, memberId, 'Member ID should be returned');
    }

    @isTest
    static void testSearchVendorProgramRecipientGroups() {
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
        List<Vendor_Program_Recipient_Group__c> result = VendorOnboardingWizardService.searchVendorProgramRecipientGroups('Test');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testCreateVendorProgramRecipientGroupLink() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(true);
        
        // Act
        Test.startTest();
        Id linkId = VendorOnboardingWizardService.createVendorProgramRecipientGroupLink(vendorProgram.Id, recipientGroup.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, linkId, 'Link ID should be returned');
    }

    @isTest
    static void testGetTerritoryRoleAssignments() {
        // Act
        Test.startTest();
        List<Territory_Role_Assignment__c> result = VendorOnboardingWizardService.getTerritoryRoleAssignments();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetAssignableUsers() {
        // Act
        Test.startTest();
        List<User> result = VendorOnboardingWizardService.getAssignableUsers();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetPublicGroups() {
        // Act
        Test.startTest();
        List<Group> result = VendorOnboardingWizardService.getPublicGroups();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testSyncComponentLibrary() {
        // Act
        Test.startTest();
        VendorOnboardingWizardService.syncComponentLibrary();
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Sync should complete successfully');
    }
}
