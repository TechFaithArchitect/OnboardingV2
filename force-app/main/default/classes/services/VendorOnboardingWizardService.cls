/**
 * Facade service that delegates to domain-specific services
 * Maintains backward compatibility while improving code organization
 * @deprecated Use domain-specific services directly (VendorService, VendorProgramService, etc.)
 */
public with sharing class VendorOnboardingWizardService {

    // -------------------------------
    // Vendor - Delegates to VendorService
    // -------------------------------

    public static List<Vendor__c> searchVendors(String vendorName) {
        return VendorService.searchVendors(vendorName);
    }

    public static Id createVendor(Vendor__c vendor) {
        return VendorService.createVendor(vendor);
    }

    /**
     * Gets all vendors with their associated vendor programs for hierarchical display.
     */
    public static List<Vendor__c> getVendorsWithPrograms() {
        return VendorService.getVendorsWithPrograms();
    }

    /**
     * Gets vendors with programs filtered by search text.
     */
    public static List<Vendor__c> searchVendorsWithPrograms(String searchText) {
        return VendorService.searchVendorsWithPrograms(searchText);
    }

    // -------------------------------
    // Vendor Program - Delegates to VendorProgramService
    // -------------------------------

    public static List<Vendor_Customization__c> searchVendorPrograms(String vendorProgramName) {
        return VendorProgramService.searchVendorPrograms(vendorProgramName);
    }

    public static List<Vendor_Customization__c> getRecentVendorPrograms(Integer limitCount) {
        return VendorProgramService.getRecentVendorPrograms(limitCount);
    }

    public static Id createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId) {
        return VendorProgramService.createVendorProgram(vendorProgram, vendorId);
    }

    // -------------------------------
    // Vendor Program Group - Delegates to VendorProgramGroupService
    // -------------------------------

    public static List<Vendor_Program_Group__c> searchVendorProgramGroups(String vendorProgramGroupName) {
        return VendorProgramGroupService.searchVendorProgramGroups(vendorProgramGroupName);
    }

    public static List<Vendor_Program_Group__c> getAllVendorProgramGroups() {
        return VendorProgramGroupService.getAllVendorProgramGroups();
    }

    public static Id getVendorProgramGroupForVendorProgram(Id vendorProgramId) {
        return VendorProgramService.getVendorProgramGroupForVendorProgram(vendorProgramId);
    }

    public static Id getVendorProgramRequirementGroupForVendorProgram(Id vendorProgramId) {
        return VendorProgramService.getVendorProgramRequirementGroupForVendorProgram(vendorProgramId);
    }

    public static Id createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup) {
        return VendorProgramGroupService.createVendorProgramGroup(vendorProgramGroup);
    }

    /**
     * Gets a default Logic_Type__c value for Vendor_Program_Group__c.
     * Tries to get the default picklist value, falls back to 'ALL'.
     */
    private static String getDefaultLogicType() {
        return VendorProgramGroupService.getDefaultLogicType();
    }

    // -------------------------------
    // Vendor Program Requirement Group - Delegates to VendorProgramRequirementGroupService
    // -------------------------------

    public static List<Vendor_Program_Requirement_Group__c> searchVendorProgramRequirementGroups(String requirementGroupName) {
        return VendorProgramRequirementGroupService.searchVendorProgramRequirementGroups(requirementGroupName);
    }

    public static List<Vendor_Program_Requirement_Group__c> getAllVendorProgramRequirementGroups() {
        return VendorProgramRequirementGroupService.getAllVendorProgramRequirementGroups();
    }

    public static Id createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup) {
        return VendorProgramRequirementGroupService.createVendorProgramRequirementGroup(vendorProgramRequirementGroup);
    }

    public static void finalizeVendorProgram(Id vendorProgramId, Id vendorId, Id vendorProgramGroupId, Id vendorProgramRequirementGroupId) {
        VendorProgramService.finalizeVendorProgram(vendorProgramId, vendorId, vendorProgramGroupId, vendorProgramRequirementGroupId);
    }

    // -------------------------------
    // Vendor Program Requirement - Delegates to VendorProgramRequirementService
    // -------------------------------

    public static List<Vendor_Program_Requirement__c> searchVendorProgramRequirements(String vendorProgramRequirements) {
        return VendorProgramRequirementService.searchVendorProgramRequirements(vendorProgramRequirements);
    }

    public static Id createVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement) {
        return VendorProgramRequirementService.createVendorProgramRequirement(vendorProgramRequirement);
    }

    public static BulkCreateRequirementsResult bulkCreateRequirementsFromTemplates(
        Id vendorProgramId,
        List<Id> templateIds,
        String defaultStatus,
        Boolean defaultIsRequired
    ) {
        VendorProgramRequirementService.BulkCreateRequirementsResult serviceResult = 
            VendorProgramRequirementService.bulkCreateRequirementsFromTemplates(
                vendorProgramId,
                templateIds,
                defaultStatus,
                defaultIsRequired
            );
        
        // Convert service result to facade result for backward compatibility
        BulkCreateRequirementsResult result = new BulkCreateRequirementsResult();
        result.success = serviceResult.success;
        result.createdRequirementIds = serviceResult.createdRequirementIds;
        result.skippedTemplateIds = serviceResult.skippedTemplateIds;
        result.errorMessage = serviceResult.errorMessage;
        
        return result;
    }

    public static void updateRequirementSequences(List<Vendor_Program_Requirement__c> requirements) {
        VendorProgramRequirementService.updateRequirementSequences(requirements);
    }

    /**
     * Result class for bulk create operations
     * Delegates to VendorProgramRequirementService.BulkCreateRequirementsResult
     */
    public class BulkCreateRequirementsResult {
        public Boolean success = false;
        public List<Id> createdRequirementIds = new List<Id>();
        public List<Id> skippedTemplateIds = new List<Id>();
        public String errorMessage;
    }
    
    public static List<Vendor_Program_Requirement__c> getRecentVendorProgramRequirements(Id vendorProgramId) {
        return VendorProgramRequirementService.getRecentVendorProgramRequirements(vendorProgramId);
    }

    public static List<Vendor_Program_Requirement__c> getRequirementsByGroup(Id requirementGroupId) {
        return VendorProgramRequirementService.getRequirementsByGroup(requirementGroupId);
    }

    public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesByGroup(Id requirementGroupId) {
        return OnboardingRequirementSetService.getTemplatesByGroup(requirementGroupId);
    }

    public static void deleteVendorProgramRequirement(Id requirementId) {
        VendorProgramRequirementService.deleteVendorProgramRequirement(requirementId);
    }

    // -------------------------------
    // Onboarding Status Rules Engine - Delegates to StatusRulesEngineService
    // -------------------------------

    public static List<Onboarding_Status_Rules_Engine__c> searchStatusRulesEngines(String onboardingStatusRulesEngine) {
        return StatusRulesEngineService.searchStatusRulesEngines(onboardingStatusRulesEngine);
    }

    public static Id createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine) {
        return StatusRulesEngineService.createOnboardingStatusRulesEngine(onboardingStatusRulesEngine);
    }

    public static Onboarding_Status_Rules_Engine__c getStatusRulesEngineById(Id engineId) {
        return StatusRulesEngineService.getStatusRulesEngineById(engineId);
    }

    // -------------------------------
    // Onboarding Status Rules - Delegates to StatusRulesEngineService
    // -------------------------------

    public static Id createStatusRule(Onboarding_Status_Rule__c rule) {
        return StatusRulesEngineService.createStatusRule(rule);
    }

    public static List<Onboarding_Status_Rule__c> searchStatusRules(String nameSearchText) {
        return StatusRulesEngineService.searchStatusRules(nameSearchText);
    }

    // -------------------------------
    // Communication Templates - Delegates to CommunicationTemplateService
    // -------------------------------

    public static List<Communication_Template__c> getCommunicationTemplates() {
        return CommunicationTemplateService.getCommunicationTemplates();
    }

    public static void linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId) {
        CommunicationTemplateService.linkCommunicationTemplateToVendorProgram(vendorProgramId, templateId);
    }

    // -------------------------------
    // Onboarding Requirement Set - Delegates to OnboardingRequirementSetService
    // -------------------------------

    public static Id createOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet) {
        return OnboardingRequirementSetService.createOnboardingRequirementSet(requirementSet);
    }

    public static List<Onboarding_Requirement_Set__c> getOnboardingRequirementSets() {
        return OnboardingRequirementSetService.getOnboardingRequirementSets();
    }

    public static List<Onboarding_Requirement_Set__c> searchOnboardingRequirementSets(String searchText, Id vendorProgramId) {
        return OnboardingRequirementSetService.searchOnboardingRequirementSets(searchText, vendorProgramId);
    }

    /**
     * Gets all Requirement Sets with their associated Templates for hierarchical display.
     */
    public static List<Onboarding_Requirement_Set__c> getRequirementSetsWithTemplates() {
        return OnboardingRequirementSetService.getRequirementSetsWithTemplates();
    }

    /**
     * Gets Requirement Sets with Templates filtered by search text.
     */
    public static List<Onboarding_Requirement_Set__c> searchRequirementSetsWithTemplates(String searchText) {
        return OnboardingRequirementSetService.searchRequirementSetsWithTemplates(searchText);
    }

    public static void linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId) {
        OnboardingRequirementSetService.linkRequirementSetToVendorProgram(requirementSetId, vendorProgramId);
    }

    public static Id createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId) {
        return OnboardingRequirementSetService.createRequirementSetFromExisting(existingRequirementSetId, vendorProgramId);
    }

    public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesForRequirementSet(Id requirementSetId) {
        return OnboardingRequirementSetService.getTemplatesForRequirementSet(requirementSetId);
    }

    public static Id createRequirementFromTemplate(Id templateId, Id vendorProgramId) {
        return OnboardingRequirementSetService.createRequirementFromTemplate(templateId, vendorProgramId);
    }

    // -------------------------------
    // Requirement Group Linking (Step 5) - Delegates to OnboardingRequirementSetService
    // -------------------------------

    public static List<Vendor_Program_Group_Member__c> getHistoricalGroupMembers(Id requirementSetId) {
        return OnboardingRequirementSetService.getHistoricalGroupMembers(requirementSetId);
    }

    public static List<Onboarding_Status_Rules_Engine__c> getHistoricalStatusRulesEngines(Id requirementSetId) {
        return OnboardingRequirementSetService.getHistoricalStatusRulesEngines(requirementSetId);
    }


    public static Id createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical) {
        return OnboardingRequirementSetService.createRequirementGroupComponents(vendorProgramId, requirementSetId, useHistorical);
    }

    // -------------------------------
    // Onboarding Requirement Templates - Delegates to OnboardingRequirementSetService
    // -------------------------------

    public static Id createOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template) {
        // Delegate to service which handles junction linking
        // Note: Requirement sets must be linked via junction after template creation
        return OnboardingRequirementSetService.createOnboardingRequirementTemplate(template, new List<Id>());
    }

    public static void updateOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template) {
        OnboardingRequirementSetService.updateOnboardingRequirementTemplate(template);
    }

    public static List<Map<String, Object>> getAvailableOnboardingStatusFields() {
        return OnboardingRequirementSetService.getAvailableOnboardingStatusFields();
    }

    public static List<Map<String, Object>> getAvailableOnboardingStatusFields(Id excludeTemplateId) {
        return OnboardingRequirementSetService.getAvailableOnboardingStatusFields(excludeTemplateId);
    }

    public static List<Map<String, String>> getPicklistValuesForOnboardingField(String fieldApiName) {
        return OnboardingRequirementSetService.getPicklistValuesForOnboardingField(fieldApiName);
    }

    public static List<Vendor_Program_Onboarding_Req_Template__c> getRequirementTemplatesForSet(Id requirementSetId) {
        return OnboardingRequirementSetService.getRequirementTemplatesForSet(requirementSetId);
    }

    public static void updateRequirementTemplateGroupLinks(Id requirementGroupId, List<Id> templateIdsToLink, List<Id> templateIdsToUnlink) {
        OnboardingRequirementSetService.updateRequirementTemplateGroupLinks(requirementGroupId, templateIdsToLink, templateIdsToUnlink);
    }

    /**
     * Gets a requirement set by ID for display when resuming/navigating back.
     */
    public static Onboarding_Requirement_Set__c getRequirementSetById(Id requirementSetId) {
        return OnboardingRequirementSetService.getRequirementSetById(requirementSetId);
    }

    /**
     * Gets context data for resuming the onboarding flow.
     * Retrieves requirementSetId and other context from the vendor program.
     */
    public static Map<String, Object> getOnboardingContext(Id vendorProgramId) {
        return OnboardingRequirementSetService.getOnboardingContext(vendorProgramId);
    }

    public static void assignTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds) {
        OnboardingRequirementSetService.assignTemplatesToRequirementGroup(requirementGroupId, templateIds);
    }

    // -------------------------------
    // Recipient Groups - Delegates to RecipientGroupService
    // -------------------------------

    public static List<Recipient_Group__c> searchRecipientGroups(String recipientGroupName) {
        return RecipientGroupService.searchRecipientGroups(recipientGroupName);
    }

    public static Id createRecipientGroup(Recipient_Group__c recipientGroup) {
        return RecipientGroupService.createRecipientGroup(recipientGroup);
    }

    public static Id createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember) {
        return RecipientGroupService.createRecipientGroupMember(recipientGroupMember);
    }

    // -------------------------------
    // Vendor Program Recipient Groups - Delegates to RecipientGroupService
    // -------------------------------

    public static List<Vendor_Program_Recipient_Group__c> searchVendorProgramRecipientGroups(String vprgName) {
        return RecipientGroupService.searchVendorProgramRecipientGroups(vprgName);
    }

    public static Id createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId) {
        return RecipientGroupService.createVendorProgramRecipientGroupLink(vendorProgramId, recipientGroupId);
    }

    public static List<Vendor_Program_Recipient_Group__c> getRecipientGroupsForVendorProgram(Id vendorProgramId) {
        return RecipientGroupService.getRecipientGroupsForVendorProgram(vendorProgramId);
    }

    public static List<Recipient_Group_Member__c> getRecipientGroupMembers(Id recipientGroupId) {
        return RecipientGroupService.getRecipientGroupMembers(recipientGroupId);
    }

    public static Id createVendorProgramRecipientGroupWithTemplate(
        Id vendorProgramId, 
        Id recipientGroupId, 
        Id communicationTemplateId,
        String triggerCondition
    ) {
        return RecipientGroupService.createVendorProgramRecipientGroupWithTemplate(
            vendorProgramId,
            recipientGroupId,
            communicationTemplateId,
            triggerCondition
        );
    }

    // -------------------------------
    // Misc: Assignable Users, Roles, Groups
    // -------------------------------
    public static List<Territory_Role_Assignment__c> getTerritoryRoleAssignments() {
        return VendorOnboardingWizardRepository.getTerritoryRoleAssignments();
    }

    public static List<User> getAssignableUsers() {
        return VendorOnboardingWizardRepository.getAssignableUsers();
    }

    public static List<Group> getPublicGroups() {
        return VendorOnboardingWizardRepository.getPublicGroups();
    }

    // -------------------------------
    // Onboarding Component Library
    // -------------------------------

    public static void syncComponentLibrary() {
        List<String> components = new List<String>{
            'vendorProgramOnboardingVendor',
            'vendorProgramOnboardingVendorProgramSearchOrCreate',
            'vendorProgramOnboardingVendorProgramCreate',
            'vendorProgramOnboardingVendorProgramGroup',
            'vendorProgramOnboardingVendorProgramRequirementGroup',
            'vendorProgramOnboardingVendorProgramRecipientGroup',
            'vendorProgramOnboardingRecipientGroup',
            'vendorProgramOnboardingRecipientGroupMembers',
            'vendorProgramOnboardingTrainingRequirements',
            'vendorProgramOnboardingRequiredCredentials',
            'vendorProgramOnboardingRequirementSet',
            'vendorProgramOnboardingReqTemplate',
            'vendorProgramOnboardingVendorProgramRequirements',
            'vendorProgramOnboardingStatusRulesEngine',
            'vendorProgramOnboardingStatusRuleBuilder',
            'vendorProgramOnboardingCommunicationTemplate'
        };

        VendorOnboardingWizardRepository.upsertOnboardingComponents(components);
    }

    // -------------------------------
    // Default Onboarding Process Setup
    // -------------------------------

    /**
     * Creates the default "Vendor Program Onboarding" process if it doesn't exist.
     * Also creates all 16 stages linked to the component library entries in the correct order.
     * This is an admin utility function to initialize the default onboarding flow.
     */
    public static Id initializeDefaultVendorProgramOnboardingProcess() {
        // Step 1: Check if process already exists
        List<Onboarding_Application_Process__c> existingProcesses = OnboardingApplicationRepository.fetchActiveProcessesByName('Vendor Program Onboarding');
        if (existingProcesses != null && !existingProcesses.isEmpty()) {
            return existingProcesses[0].Id;
        }

        // Step 2: Ensure component library is synced first
        syncComponentLibrary();

        // Step 3: Get component library entries
        Map<String, Id> componentLibraryMap = VendorOnboardingWizardRepository.getComponentLibraryByApiName();
        
        // Step 4: Create the process
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Vendor Program Onboarding',
            Description__c = 'Default onboarding process for vendor programs. Includes all 16 wizard stages.',
            Active__c = true
        );
        OnboardingApplicationRepository.insertProcess(process);

        // Step 5: Define stages in order with labels
        List<StageDefinition> stageDefinitions = new List<StageDefinition>{
            new StageDefinition(1, 'Select Vendor', 'vendorProgramOnboardingVendor', true),
            new StageDefinition(2, 'Search or Create Vendor Program', 'vendorProgramOnboardingVendorProgramSearchOrCreate', true),
            new StageDefinition(3, 'Create Vendor Program', 'vendorProgramOnboardingVendorProgramCreate', true),
            new StageDefinition(4, 'Vendor Program Group', 'vendorProgramOnboardingVendorProgramGroup', true),
            new StageDefinition(5, 'Vendor Program Requirement Group', 'vendorProgramOnboardingVendorProgramRequirementGroup', true),
            new StageDefinition(6, 'Vendor Program Recipient Group', 'vendorProgramOnboardingVendorProgramRecipientGroup', true),
            new StageDefinition(7, 'Recipient Group', 'vendorProgramOnboardingRecipientGroup', true),
            new StageDefinition(8, 'Recipient Group Members', 'vendorProgramOnboardingRecipientGroupMembers', true),
            new StageDefinition(9, 'Training Requirements', 'vendorProgramOnboardingTrainingRequirements', true),
            new StageDefinition(10, 'Required Credentials', 'vendorProgramOnboardingRequiredCredentials', true),
            new StageDefinition(11, 'Select or Create Requirement Set', 'vendorProgramOnboardingRequirementSet', true),
            new StageDefinition(12, 'Create Requirement Template', 'vendorProgramOnboardingReqTemplate', true),
            new StageDefinition(13, 'Vendor Program Requirements', 'vendorProgramOnboardingVendorProgramRequirements', true),
            new StageDefinition(14, 'Status Rules Engine', 'vendorProgramOnboardingStatusRulesEngine', true),
            new StageDefinition(15, 'Status Rule Builder', 'vendorProgramOnboardingStatusRuleBuilder', true),
            new StageDefinition(16, 'Communication Template', 'vendorProgramOnboardingCommunicationTemplate', true)
        };

        // Step 6: Create stages
        List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>();

        for (StageDefinition stageDef : stageDefinitions) {
            Id componentLibraryId = componentLibraryMap.get(stageDef.componentApiName);
            
            if (componentLibraryId == null) {
                System.debug(LoggingLevel.WARN, 'Component library entry not found for: ' + stageDef.componentApiName);
                continue;
            }

            Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
                Name = stageDef.label,
                Label__c = stageDef.label,
                Display_Order__c = stageDef.displayOrder,
                Onboarding_Application_Process__c = process.Id,
                Onboarding_Component_Library__c = componentLibraryId,
                Required__c = stageDef.required
                // Next_Stage__c will be set after insert
            );

            stages.add(stage);
        }

        // Step 7: Insert stages (first pass without Next_Stage links)
        OnboardingApplicationRepository.insertStages(stages);

        // Step 8: Update Next_Stage links (each stage points to the next one in sequence)
        // Stage at index i points to stage at index i+1
        for (Integer i = 0; i < stages.size() - 1; i++) {
            stages[i].Next_Stage__c = stages[i + 1].Id;
        }
        // Last stage (index stages.size()-1) has no next stage (remains null)

        OnboardingApplicationRepository.updateStages(stages);

        return process.Id;
    }

    /**
     * Inner class to define stage metadata
     */
    private class StageDefinition {
        Integer displayOrder;
        String label;
        String componentApiName;
        Boolean required;

        StageDefinition(Integer displayOrder, String label, String componentApiName, Boolean required) {
            this.displayOrder = displayOrder;
            this.label = label;
            this.componentApiName = componentApiName;
            this.required = required;
        }
    }
}