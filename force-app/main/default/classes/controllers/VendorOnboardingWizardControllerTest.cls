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

    @isTest
    static void testSearchGating_respectsPerfectVisionFilter() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Vendor__c pvVendor = new Vendor__c(Name = 'PerfectVision');
        Vendor__c otherVendor = new Vendor__c(Name = 'OtherVendor');
        insert new List<Vendor__c>{ pvVendor, otherVendor };

        Vendor_Program_Group__c gatedGroup = new Vendor_Program_Group__c(
            Name = 'Gated Group',
            Logic_Type__c = 'ALL',
            Requires_NDA__c = true,
            Requires_Program_Base__c = true
        );
        insert gatedGroup;

        Vendor_Customization__c pvProgram = new Vendor_Customization__c(
            Name = 'PV Program',
            Vendor__c = pvVendor.Id,
            Status__c = 'Active',
            Active__c = true
        );
        Vendor_Customization__c otherProgram = new Vendor_Customization__c(
            Name = 'Other Program',
            Vendor__c = otherVendor.Id,
            Status__c = 'Active',
            Active__c = true,
            Vendor_Program_Group__c = gatedGroup.Id
        );
        Vendor_Customization__c inactiveProgram = new Vendor_Customization__c(
            Name = 'Inactive Program',
            Vendor__c = otherVendor.Id,
            Status__c = 'Draft',
            Active__c = false
        );
        insert new List<Vendor_Customization__c>{ pvProgram, otherProgram, inactiveProgram };

        Test.startTest();
        List<Vendor_Customization__c> ineligible = VendorOnboardingWizardController.searchVendorProgramsForAccount(
            acct.Id, 'Program', false, false, false
        );
        List<Vendor_Customization__c> eligible = VendorOnboardingWizardController.searchVendorProgramsForAccount(
            acct.Id, 'Program', true, true, true
        );
        Test.stopTest();

        System.assertEquals(1, ineligible.size(), 'Ineligible should include only programs without prerequisites');
        System.assertEquals(pvProgram.Id, ineligible[0].Id);

        System.assertEquals(1, eligible.size(), 'Eligible should include prerequisite program when account satisfies them');
        System.assertEquals(otherProgram.Id, eligible[0].Id);
        System.assertEquals(true, eligible[0].Active__c, 'Should only return active programs');
        System.assertEquals('Active', eligible[0].Status__c, 'Should only return programs with Active status');
    }

    @isTest
    static void testAccountContactRole_upsert_and_fetch() {
        Account acct = new Account(Name = 'ACR Test Account');
        insert acct;
        Contact c = new Contact(LastName = 'Tester', AccountId = acct.Id, Email = 'test@example.com');
        insert c;

        Test.startTest();
        Id acrId = VendorOnboardingWizardController.upsertAccountContactRelation(acct.Id, c.Id, 'Owner');
        List<VendorOnboardingWizardService.ContactRoleDTO> dtos =
            VendorOnboardingWizardController.getAccountContactsWithRoles(acct.Id);
        Test.stopTest();

        System.assertNotEquals(null, acrId, 'ACR should be inserted');
        System.assertEquals(1, dtos.size(), 'Should return one contact');
        System.assertEquals('Owner', dtos[0].role, 'Role should match upserted value');
        System.assertEquals(true, dtos[0].hasAcr, 'hasAcr should be true after upsert');
    }

    @isTest
    static void testOpportunity_and_ocr_create() {
        Account acct = new Account(Name = 'Opp Test Account');
        insert acct;
        Contact c = new Contact(LastName = 'Tester', AccountId = acct.Id);
        insert c;

        Test.startTest();
        Id oppId = VendorOnboardingWizardController.createOnboardingOpportunity(
            acct.Id,
            'Onboarding Opp',
            'Prospecting',
            Date.today().addDays(5),
            null
        );
        Id ocrId = VendorOnboardingWizardController.upsertOpportunityContactRole(
            oppId,
            c.Id,
            'Owner',
            true
        );
        Test.stopTest();

        OpportunityContactRole ocr = [SELECT OpportunityId, ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE Id = :ocrId];
        System.assertEquals(oppId, ocr.OpportunityId, 'OCR should reference created Opportunity');
        System.assertEquals(c.Id, ocr.ContactId, 'OCR should reference Contact');
        System.assertEquals('Owner', ocr.Role, 'OCR role should match input');
        System.assertEquals(true, ocr.IsPrimary, 'OCR primary flag should match input');
    }

    @isTest
    static void testOnboarding_with_requirements_created() {
        Account acct = new Account(Name = 'Onboarding Test Account');
        insert acct;
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );

        // Create Opp
        Id oppId = VendorOnboardingWizardController.createOnboardingOpportunity(
            acct.Id, 'Onboarding Opp', 'Prospecting', Date.today().addDays(10), null
        );

        Test.startTest();
        VendorOnboardingWizardService.OnboardingWithRequirementsResult result =
            VendorOnboardingWizardController.createOnboardingWithRequirements(
                acct.Id, vendorProgram.Id, oppId
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.onboardingId, 'Onboarding should be created');
        System.assertEquals(0, result.requirementCount, 'Requirement count should be zero when no VPRs exist');

        Onboarding__c ob = [SELECT Account__c, Vendor_Customization__c, Opportunity__c FROM Onboarding__c WHERE Id = :result.onboardingId];
        System.assertEquals(acct.Id, ob.Account__c, 'Onboarding should link Account');
        System.assertEquals(vendorProgram.Id, ob.Vendor_Customization__c, 'Onboarding should link Vendor Program');
        System.assertEquals(oppId, ob.Opportunity__c, 'Onboarding should link Opportunity');
    }
}
