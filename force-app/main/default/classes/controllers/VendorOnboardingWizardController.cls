public with sharing class VendorOnboardingWizardController {

    // -------------------------------
    // Vendor
    // -------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Vendor__c> searchVendors(String vendorNameSearchText) {
        return VendorOnboardingWizardService.searchVendors(vendorNameSearchText);
    }

    @AuraEnabled
    public static Id createVendor(Vendor__c vendor) {
        return VendorOnboardingWizardService.createVendor(vendor);
    }

    // -------------------------------
    // Vendor Program
    // -------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Customization__c> searchVendorPrograms(String vendorProgramNameSearchText) {
        return VendorOnboardingWizardService.searchVendorPrograms(vendorProgramNameSearchText);
    }

    /**
     * Account-aware vendor program search with eligibility gating.
     * If eligibilityPassed is false/null, only programs where Vendor__r.Name = 'PerfectVision' are returned.
     * If true, programs where Vendor__r.Name != 'PerfectVision' are returned.
     */
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Customization__c> searchVendorProgramsForAccount(
        Id accountId,
        String vendorProgramNameSearchText,
        Boolean eligibilityPassed,
        Boolean accountHasNda,
        Boolean accountHasProgramBase
    ) {
        return VendorOnboardingWizardService.searchVendorProgramsForAccount(
            accountId,
            vendorProgramNameSearchText,
            eligibilityPassed,
            accountHasNda,
            accountHasProgramBase
        );
    }

    /**
     * Returns NDA/Base Application eligibility for a given Account.
     */
    @AuraEnabled(cacheable=true)
    public static VendorOnboardingWizardService.VendorProgramEligibilityResult getVendorProgramEligibilityForAccount(Id accountId) {
        return VendorOnboardingWizardService.getVendorProgramEligibilityForAccount(accountId);
    }

    @AuraEnabled(cacheable=true)
    public static List<VendorOnboardingWizardService.ContactRoleDTO> getAccountContactsWithRoles(Id accountId) {
        return VendorOnboardingWizardService.getAccountContactsWithRoles(accountId);
    }

    @AuraEnabled
    public static Id upsertAccountContactRelation(Id accountId, Id contactId, String role) {
        return VendorOnboardingWizardService.upsertAccountContactRelation(accountId, contactId, role);
    }

    // -------------------------------
    // Onboarding Opportunity + OCR + AVO
    // -------------------------------
    @AuraEnabled
    public static Id createOnboardingOpportunity(
        Id accountId,
        String name,
        String stageName,
        Date closeDate,
        Id recordTypeId
    ) {
        return VendorOnboardingWizardService.createOnboardingOpportunity(
            accountId, name, stageName, closeDate, recordTypeId
        );
    }

    @AuraEnabled
    public static Id upsertOpportunityContactRole(Id opportunityId, Id contactId, String role, Boolean isPrimary) {
        return VendorOnboardingWizardService.upsertOpportunityContactRole(opportunityId, contactId, role, isPrimary);
    }

    @AuraEnabled
    public static Id createAccountVendorProgramOnboarding(
        Id accountId,
        Id onboardingId,
        Id opportunityId,
        String status,
        Id primaryContactId
    ) {
        return VendorOnboardingWizardService.createAccountVendorProgramOnboarding(
            accountId, onboardingId, opportunityId, status, primaryContactId
        );
    }

    @AuraEnabled
    public static VendorOnboardingWizardService.OnboardingWithRequirementsResult createOnboardingWithRequirements(
        Id accountId,
        Id vendorProgramId,
        Id opportunityId
    ) {
        return VendorOnboardingWizardService.createOnboardingWithRequirements(accountId, vendorProgramId, opportunityId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Vendor_Customization__c> getRecentVendorPrograms(Integer limitCount) {
        return VendorOnboardingWizardService.getRecentVendorPrograms(limitCount);
    }

    @AuraEnabled
    public static Id createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId) {
        return VendorOnboardingWizardService.createVendorProgram(vendorProgram, vendorId);
    }

    // -------------------------------
    // Vendor Program Group
    // -------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Group__c> searchVendorProgramGroups(String vendorProgramGroupNameSearchText) {
        return VendorOnboardingWizardService.searchVendorProgramGroups(vendorProgramGroupNameSearchText);
    }

    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Group__c> getAllVendorProgramGroups() {
        return VendorOnboardingWizardService.getAllVendorProgramGroups();
    }

    @AuraEnabled(cacheable=true)
    public static Id getVendorProgramGroupForVendorProgram(Id vendorProgramId) {
        return VendorOnboardingWizardService.getVendorProgramGroupForVendorProgram(vendorProgramId);
    }

    @AuraEnabled(cacheable=true)
    public static Id getVendorProgramRequirementGroupForVendorProgram(Id vendorProgramId) {
        return VendorOnboardingWizardService.getVendorProgramRequirementGroupForVendorProgram(vendorProgramId);
    }

    @AuraEnabled
    public static Id createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup) {
        return VendorOnboardingWizardService.createVendorProgramGroup(vendorProgramGroup);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getLogicTypePicklistValues() {
        return PicklistHelper.getPicklistValuesByField(
            Vendor_Program_Group__c.Logic_Type__c,
            new List<String>{'ALL', 'AND', 'OR'}
        );
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getStatusPicklistValues() {
        return getPicklistValues('Vendor_Program_Requirement_Group__c', 'Status__c', new List<String>{'Active', 'Inactive', 'Draft'});
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRetailOptionPicklistValues() {
        return getPicklistValues('Vendor_Customization__c', 'Retail_Option__c', new List<String>{'National Agent', 'National Retail', 'Amendment', 'N/A'});
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getBusinessVerticalPicklistValues() {
        return getPicklistValues('Vendor_Customization__c', 'Business_Vertical__c', new List<String>{'National Agent', 'National Agent and D2D', 'D2D', 'National Retail', 'National Retail and National Agent', 'National Retail and D2D', 'National Retail, National Agent, and D2D', 'N/A'});
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getGroupTypePicklistValues() {
        return getPicklistValues('Recipient_Group__c', 'Group_Type__c', new List<String>{'User', 'Public Group', 'Role'});
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getEvaluationLogicPicklistValues() {
        return getPicklistValues('Onboarding_Status_Rules_Engine__c', 'Evaluation_Logic__c', new List<String>{'ALL', 'ANY', 'CUSTOM'});
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRequiredStatusPicklistValues() {
        return getPicklistValues('Onboarding_Status_Rules_Engine__c', 'Required_Status__c', new List<String>{'New', 'In Process', 'Pending Review', 'Complete'});
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTargetOnboardingStatusPicklistValues() {
        return getPicklistValues('Onboarding_Status_Rules_Engine__c', 'Target_Onboarding_Status__c', new List<String>{'New', 'In Process', 'Pending Review', 'Complete'});
    }

    /**
     * Private helper method that delegates to PicklistHelper
     * Maintains backward compatibility for existing method calls
     * @deprecated Use PicklistHelper.getPicklistValuesWithFallback directly
     */
    private static List<Map<String, String>> getPicklistValues(String objectName, String fieldName, List<String> fallbackValues) {
        return PicklistHelper.getPicklistValuesWithFallback(objectName, fieldName, fallbackValues);
    }

    // -------------------------------
    // Vendor Program Requirement Group
    // -------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Requirement_Group__c> searchVendorProgramRequirementGroups(String requirementGroupNameSearchText) {
        return VendorOnboardingWizardService.searchVendorProgramRequirementGroups(requirementGroupNameSearchText);
    }

    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Requirement_Group__c> getAllVendorProgramRequirementGroups() {
        return VendorOnboardingWizardService.getAllVendorProgramRequirementGroups();
    }

    @AuraEnabled
    public static Id createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup) {
        return VendorOnboardingWizardService.createVendorProgramRequirementGroup(vendorProgramRequirementGroup);
    }

    @AuraEnabled
    public static void finalizeVendorProgram(
        Id vendorProgramId,
        Id vendorId,
        Id vendorProgramGroupId,
        Id vendorProgramRequirementGroupId
    ) {
        VendorOnboardingWizardService.finalizeVendorProgram(
            vendorProgramId,
            vendorId,
            vendorProgramGroupId,
            vendorProgramRequirementGroupId
        );
    }

    // -------------------------------
    // Vendor Program Requirement Group
    // -------------------------------
    
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Requirement__c> searchVendorProgramRequirements(String vendorProgramRequirements) {
        return VendorOnboardingWizardService.searchVendorProgramRequirements(vendorProgramRequirements);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Requirement__c> getRecentVendorProgramRequirements(Id vendorProgramId) {
        return VendorOnboardingWizardService.getRecentVendorProgramRequirements(vendorProgramId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Requirement__c> getRequirementsByGroup(Id requirementGroupId) {
        return VendorOnboardingWizardService.getRequirementsByGroup(requirementGroupId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesByGroup(Id requirementGroupId) {
        return VendorOnboardingWizardService.getTemplatesByGroup(requirementGroupId);
    }

    @AuraEnabled
    public static Id createVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement) {
        return VendorOnboardingWizardService.createVendorProgramRequirement(vendorProgramRequirement);
    }

    @AuraEnabled
    public static void deleteVendorProgramRequirement(Id requirementId) {
        VendorOnboardingWizardService.deleteVendorProgramRequirement(requirementId);
    }

    @AuraEnabled
    public static Map<String, Object> bulkCreateRequirementsFromTemplates(
        Id vendorProgramId,
        List<Id> templateIds,
        String defaultStatus,
        Boolean defaultIsRequired
    ) {
        VendorOnboardingWizardService.BulkCreateRequirementsResult result = 
            VendorOnboardingWizardService.bulkCreateRequirementsFromTemplates(
                vendorProgramId,
                templateIds,
                defaultStatus,
                defaultIsRequired
            );
        
        return new Map<String, Object>{
            'success' => result.success,
            'createdRequirementIds' => result.createdRequirementIds,
            'skippedTemplateIds' => result.skippedTemplateIds,
            'errorMessage' => result.errorMessage
        };
    }

    @AuraEnabled
    public static void updateRequirementSequences(List<Vendor_Program_Requirement__c> requirements) {
        VendorOnboardingWizardService.updateRequirementSequences(requirements);
    }

    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Requirement__c> getRequirementsForVendorProgram(Id vendorProgramId) {
        return VendorOnboardingWizardService.getRecentVendorProgramRequirements(vendorProgramId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getVendorProgramRequirementStatusPicklistValues() {
        return getPicklistValues('Vendor_Program_Requirement__c', 'Status__c', new List<String>{'Active', 'Draft', 'Inactive'});
    }

    // -------------------------------
    // Onboarding Status Rules Engine
    // -------------------------------

    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rules_Engine__c> searchStatusRulesEngines(String nameSearchText) {
        return VendorOnboardingWizardService.searchStatusRulesEngines(nameSearchText);
    }

    @AuraEnabled
    public static Id createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine) {
        return VendorOnboardingWizardService.createOnboardingStatusRulesEngine(onboardingStatusRulesEngine);
    }

    @AuraEnabled(cacheable=true)
    public static Onboarding_Status_Rules_Engine__c getStatusRulesEngineById(Id engineId) {
        return VendorOnboardingWizardService.getStatusRulesEngineById(engineId);
    }

    // -------------------------------
    // Onboarding Status Rules
    // -------------------------------

    @AuraEnabled
    public static Id createStatusRule(Onboarding_Status_Rule__c rule) {
        return VendorOnboardingWizardService.createStatusRule(rule);
    }

    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rule__c> searchStatusRules(String nameSearchText) {
        return VendorOnboardingWizardService.searchStatusRules(nameSearchText);
    }

    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rule__c> getStatusRulesByEngine(Id engineId) {
        return OnboardingRulesService.getRulesEngineRecords(engineId);
    }

    @AuraEnabled
    public static Onboarding_Status_Rule__c upsertStatusRule(Onboarding_Status_Rule__c rule) {
        return OnboardingRulesService.createOrUpdateRule(rule);
    }

    @AuraEnabled
    public static void deleteStatusRule(Id ruleId) {
        OnboardingRulesService.deleteRule(ruleId);
    }

    // -------------------------------
    // Communication Templates
    // -------------------------------

    @AuraEnabled(cacheable=true)
    public static List<Communication_Template__c> getCommunicationTemplates() {
        return VendorOnboardingWizardService.getCommunicationTemplates();
    }

    @AuraEnabled
    public static void linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId) {
        VendorOnboardingWizardService.linkCommunicationTemplateToVendorProgram(vendorProgramId, templateId);
    }

    // -------------------------------
    // Onboarding Requirement Set + Templates
    // -------------------------------

    @AuraEnabled
    public static Id createOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet) {
        return VendorOnboardingWizardService.createOnboardingRequirementSet(requirementSet);
    }

    @AuraEnabled
    public static Id createOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template) {
        // Delegate to service which handles junction linking
        return VendorOnboardingWizardService.createOnboardingRequirementTemplate(template);
    }
    
    /**
     * Links a template to one or more requirement sets via junction object
     */
    @AuraEnabled
    public static List<Id> linkTemplateToRequirementSets(Id templateId, List<Id> requirementSetIds) {
        if (requirementSetIds == null || requirementSetIds.isEmpty()) {
            return new List<Id>();
        }
        return RequirementSetTemplateService.linkTemplatesToRequirementSet(new List<Id>{ templateId }, requirementSetIds[0]);
    }
    
    /**
     * Links a requirement set to one or more vendor programs via junction object
     */
    @AuraEnabled
    public static List<Id> linkRequirementSetToVendorPrograms(Id requirementSetId, List<Id> vendorProgramIds) {
        if (vendorProgramIds == null || vendorProgramIds.isEmpty()) {
            return new List<Id>();
        }
        return VendorProgramRequirementSetService.linkRequirementSetsToVendorProgram(
            new List<Id>{ requirementSetId }, 
            vendorProgramIds[0]
        );
    }
    
    /**
     * Gets all requirement sets that a template is linked to
     */
    @AuraEnabled(cacheable=true)
    public static List<Id> getRequirementSetsForTemplate(Id templateId) {
        return RequirementSetTemplateService.getRequirementSetsForTemplate(templateId);
    }
    
    /**
     * Gets all vendor programs that a requirement set is linked to
     */
    @AuraEnabled(cacheable=true)
    public static List<Id> getVendorProgramsForRequirementSet(Id requirementSetId) {
        return VendorProgramRequirementSetService.getVendorProgramsForRequirementSet(requirementSetId);
    }
    
    /**
     * Unlinks a template from a requirement set
     */
    @AuraEnabled
    public static void unlinkTemplateFromRequirementSet(Id templateId, Id requirementSetId) {
        RequirementSetTemplateService.unlinkTemplateFromRequirementSet(templateId, requirementSetId);
    }
    
    /**
     * Unlinks a requirement set from a vendor program
     */
    @AuraEnabled
    public static void unlinkRequirementSetFromVendorProgram(Id requirementSetId, Id vendorProgramId) {
        VendorProgramRequirementSetService.unlinkRequirementSetFromVendorProgram(vendorProgramId, requirementSetId);
    }

    @AuraEnabled
    public static void updateOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template) {
        VendorOnboardingWizardService.updateOnboardingRequirementTemplate(template);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAvailableOnboardingStatusFields() {
        return OnboardingRequirementSetService.getAvailableOnboardingStatusFields();
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAvailableOnboardingStatusFieldsForEdit(Id templateId) {
        return OnboardingRequirementSetService.getAvailableOnboardingStatusFields(templateId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValuesForOnboardingField(String fieldApiName) {
        return OnboardingRequirementSetService.getPicklistValuesForOnboardingField(fieldApiName);
    }

    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Requirement_Set__c> getOnboardingRequirementSets() {
        return VendorOnboardingWizardService.getOnboardingRequirementSets();
    }

    @AuraEnabled
    public static List<Onboarding_Requirement_Set__c> searchOnboardingRequirementSets(String searchText, Id vendorProgramId) {
        return VendorOnboardingWizardService.searchOnboardingRequirementSets(searchText, vendorProgramId);
    }

    /**
     * Gets all Requirement Sets with their associated Templates for hierarchical display.
     */
    @AuraEnabled(cacheable=true)
    public static List<RequirementSetHierarchyDTO> getRequirementSetsWithTemplates() {
        List<Onboarding_Requirement_Set__c> requirementSets = VendorOnboardingWizardService.getRequirementSetsWithTemplates();
        return buildRequirementSetHierarchy(requirementSets);
    }

    /**
     * Searches Requirement Sets with Templates by name or template label.
     */
    @AuraEnabled(cacheable=true)
    public static List<RequirementSetHierarchyDTO> searchRequirementSetsWithTemplates(String searchText) {
        List<Onboarding_Requirement_Set__c> requirementSets = VendorOnboardingWizardService.searchRequirementSetsWithTemplates(searchText);
        return buildRequirementSetHierarchy(requirementSets);
    }

    /**
     * Builds hierarchical DTO structure for tree-grid display.
     * Uses junction objects to fetch templates for each requirement set.
     */
    private static List<RequirementSetHierarchyDTO> buildRequirementSetHierarchy(List<Onboarding_Requirement_Set__c> requirementSets) {
        List<RequirementSetHierarchyDTO> hierarchy = new List<RequirementSetHierarchyDTO>();
        
        // Get all requirement set IDs
        Set<Id> requirementSetIds = new Set<Id>();
        for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
            requirementSetIds.add(reqSet.Id);
        }
        
        // Fetch templates via junction object (new approach)
        Map<Id, List<Vendor_Program_Onboarding_Req_Template__c>> templatesByRequirementSet = new Map<Id, List<Vendor_Program_Onboarding_Req_Template__c>>();
        
        if (!requirementSetIds.isEmpty()) {
            // Get template IDs via junction
            Map<Id, Set<Id>> templateIdsByRequirementSet = new Map<Id, Set<Id>>();
            for (Requirement_Set_Template__c junction : [
                SELECT Onboarding_Requirement_Set__c, Requirement_Template__c
                FROM Requirement_Set_Template__c
                WHERE Onboarding_Requirement_Set__c IN :requirementSetIds
            ]) {
                if (!templateIdsByRequirementSet.containsKey(junction.Onboarding_Requirement_Set__c)) {
                    templateIdsByRequirementSet.put(junction.Onboarding_Requirement_Set__c, new Set<Id>());
                }
                templateIdsByRequirementSet.get(junction.Onboarding_Requirement_Set__c).add(junction.Requirement_Template__c);
            }
            
            // Fetch full template records
            Set<Id> allTemplateIds = new Set<Id>();
            for (Set<Id> templateIds : templateIdsByRequirementSet.values()) {
                allTemplateIds.addAll(templateIds);
            }
            
            if (!allTemplateIds.isEmpty()) {
                Map<Id, Vendor_Program_Onboarding_Req_Template__c> templateMap = new Map<Id, Vendor_Program_Onboarding_Req_Template__c>([
                    SELECT Id, Requirement_Label__c, Requirement_Type__c, Status__c, Is_Current_Version__c,
                           CreatedDate, LastModifiedDate
                    FROM Vendor_Program_Onboarding_Req_Template__c
                    WHERE Id IN :allTemplateIds
                ]);
                
                // Build map of requirement set to templates
                for (Id reqSetId : requirementSetIds) {
                    templatesByRequirementSet.put(reqSetId, new List<Vendor_Program_Onboarding_Req_Template__c>());
                    if (templateIdsByRequirementSet.containsKey(reqSetId)) {
                        for (Id templateId : templateIdsByRequirementSet.get(reqSetId)) {
                            if (templateMap.containsKey(templateId)) {
                                templatesByRequirementSet.get(reqSetId).add(templateMap.get(templateId));
                            }
                        }
                    }
                }
            }
        }
        
        // Build hierarchy DTOs
        for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
            RequirementSetHierarchyDTO reqSetDTO = new RequirementSetHierarchyDTO();
            reqSetDTO.id = reqSet.Id;
            reqSetDTO.name = reqSet.Name;
            reqSetDTO.displayLabel = reqSet.Display_Label__c; // Use Display Label instead of Name
            reqSetDTO.recordType = 'requirementSet';
            reqSetDTO.status = reqSet.Status__c != null ? reqSet.Status__c : 'Draft';
            
            List<Vendor_Program_Onboarding_Req_Template__c> templates = templatesByRequirementSet.get(reqSet.Id);
            reqSetDTO.templateCount = templates != null ? templates.size() : 0;
            reqSetDTO.createdDate = reqSet.CreatedDate;
            reqSetDTO.lastModifiedDate = reqSet.LastModifiedDate;
            reqSetDTO.children = new List<RequirementSetHierarchyDTO>();
            
            // Add templates as children
            if (templates != null && !templates.isEmpty()) {
                for (Vendor_Program_Onboarding_Req_Template__c template : templates) {
                    RequirementSetHierarchyDTO templateDTO = new RequirementSetHierarchyDTO();
                    templateDTO.id = template.Id;
                    templateDTO.name = template.Requirement_Label__c;
                    templateDTO.recordType = 'template';
                    templateDTO.status = template.Status__c != null ? template.Status__c : 'Draft';
                    templateDTO.requirementType = template.Requirement_Type__c;
                    templateDTO.isCurrentVersion = template.Is_Current_Version__c;
                    templateDTO.createdDate = template.CreatedDate;
                    templateDTO.lastModifiedDate = template.LastModifiedDate;
                    templateDTO.parentId = reqSet.Id;
                    templateDTO.children = null; // Templates are leaf nodes
                    
                    reqSetDTO.children.add(templateDTO);
                }
            }
            
            hierarchy.add(reqSetDTO);
        }
        
        return hierarchy;
    }

    @AuraEnabled(cacheable=true)
    public static Onboarding_Requirement_Set__c getRequirementSetById(Id requirementSetId) {
        return VendorOnboardingWizardService.getRequirementSetById(requirementSetId);
    }

    @AuraEnabled
    public static void linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId) {
        VendorOnboardingWizardService.linkRequirementSetToVendorProgram(requirementSetId, vendorProgramId);
    }

    @AuraEnabled
    public static Id createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId) {
        return VendorOnboardingWizardService.createRequirementSetFromExisting(existingRequirementSetId, vendorProgramId);
    }

    @AuraEnabled
    public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesForRequirementSet(Id requirementSetId) {
        return VendorOnboardingWizardService.getTemplatesForRequirementSet(requirementSetId);
    }

    @AuraEnabled
    public static Id createRequirementFromTemplate(Id templateId, Id vendorProgramId) {
        return VendorOnboardingWizardService.createRequirementFromTemplate(templateId, vendorProgramId);
    }

    @AuraEnabled
    public static List<Vendor_Program_Group_Member__c> getHistoricalGroupMembers(Id requirementSetId) {
        return VendorOnboardingWizardService.getHistoricalGroupMembers(requirementSetId);
    }

    @AuraEnabled
    public static Id createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical) {
        return VendorOnboardingWizardService.createRequirementGroupComponents(vendorProgramId, requirementSetId, useHistorical);
    }

    @AuraEnabled
    public static List<Onboarding_Status_Rules_Engine__c> getHistoricalStatusRulesEngines(Id requirementSetId) {
        return VendorOnboardingWizardService.getHistoricalStatusRulesEngines(requirementSetId);
    }


    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Onboarding_Req_Template__c> getRequirementTemplatesForSet(Id requirementSetId) {
        return VendorOnboardingWizardService.getRequirementTemplatesForSet(requirementSetId);
    }

    @AuraEnabled
    public static void updateRequirementTemplateGroupLinks(Id requirementGroupId, List<Id> templateIdsToLink, List<Id> templateIdsToUnlink) {
        VendorOnboardingWizardService.updateRequirementTemplateGroupLinks(requirementGroupId, templateIdsToLink, templateIdsToUnlink);
    }

    @AuraEnabled
    public static void assignTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds) {
        VendorOnboardingWizardService.assignTemplatesToRequirementGroup(requirementGroupId, templateIds);
    }

    // -------------------------------
    // Recipient Groups
    // -------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Recipient_Group__c> searchRecipientGroups(String recipientGroupNameSearchText) {
        return VendorOnboardingWizardService.searchRecipientGroups(recipientGroupNameSearchText);
    }

    @AuraEnabled
    public static Id createRecipientGroup(Recipient_Group__c recipientGroup) {
        return VendorOnboardingWizardService.createRecipientGroup(recipientGroup);
    }

    @AuraEnabled
    public static Id createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember) {
        return VendorOnboardingWizardService.createRecipientGroupMember(recipientGroupMember);
    }

    // -------------------------------
    // Vendor Program Recipient Groups
    // -------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Recipient_Group__c> searchVendorProgramRecipientGroups(String vprgNameSearchText) {
        return VendorOnboardingWizardService.searchVendorProgramRecipientGroups(vprgNameSearchText);
    }

    @AuraEnabled
    public static Id createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId) {
        return VendorOnboardingWizardService.createVendorProgramRecipientGroupLink(vendorProgramId, recipientGroupId);
    }

    @AuraEnabled
    public static List<Vendor_Program_Recipient_Group__c> getRecipientGroupsForVendorProgram(Id vendorProgramId) {
        return VendorOnboardingWizardService.getRecipientGroupsForVendorProgram(vendorProgramId);
    }

    @AuraEnabled
    public static List<Recipient_Group_Member__c> getRecipientGroupMembers(Id recipientGroupId) {
        return VendorOnboardingWizardService.getRecipientGroupMembers(recipientGroupId);
    }

    @AuraEnabled
    public static Id createVendorProgramRecipientGroupWithTemplate(
        Id vendorProgramId, 
        Id recipientGroupId, 
        Id communicationTemplateId,
        String triggerCondition
    ) {
        return VendorOnboardingWizardService.createVendorProgramRecipientGroupWithTemplate(
            vendorProgramId, 
            recipientGroupId, 
            communicationTemplateId,
            triggerCondition
        );
    }

    /**
     * Checks if the current user is an admin based on permission set assignment.
     * Checks for "Onboarding Application - Administrator" permission set.
     * @return True if user has Administrator permission set
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserAdmin() {
        return VendorProgramStatusMapper.isCurrentUserAdmin();
    }

    /**
     * Gets context data for resuming the onboarding flow.
     * Retrieves requirementSetId and other context from the vendor program.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOnboardingContext(Id vendorProgramId) {
        return VendorOnboardingWizardService.getOnboardingContext(vendorProgramId);
    }

    // -------------------------------
    // Assignable Entities
    // -------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Territory_Role_Assignment__c> getTerritoryRoleAssignments() {
        return VendorOnboardingWizardService.getTerritoryRoleAssignments();
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getAssignableUsers() {
        return VendorOnboardingWizardService.getAssignableUsers();
    }

    @AuraEnabled(cacheable=true)
    public static List<Group> getPublicGroups() {
        return VendorOnboardingWizardService.getPublicGroups();
    }

    // -------------------------------
    // Onboarding Component Library
    // -------------------------------

    @InvocableMethod(label='Sync Onboarding Components' description='Populates Onboarding_Component_Library__c with wizard renderer components.')
    public static void syncRendererComponents(List<Id> dummy) {
        VendorOnboardingWizardService.syncComponentLibrary();
    }

    // -------------------------------
    // Component Library Sync (for LWC)
    // -------------------------------

    @AuraEnabled
    public static String syncComponentLibrary() {
        try {
            VendorOnboardingWizardService.syncComponentLibrary();
            return 'Component Library synced successfully. All 10 wizard components are now available in the library.';
        } catch (Exception e) {
            throw new AuraHandledException('Failed to sync Component Library: ' + e.getMessage());
        }
    }

    // -------------------------------
    // Default Process Initialization (Admin Utility)
    // -------------------------------

    /**
     * Creates the default "Vendor Program Onboarding" process with all 10 stages if it doesn't exist.
     * This is an admin utility function similar to syncComponentLibrary().
     * 
     * @return The ID of the created or existing process
     */
    @AuraEnabled
    public static String initializeDefaultProcess() {
        try {
            Id processId = VendorOnboardingWizardService.initializeDefaultVendorProgramOnboardingProcess();
            return 'Default Vendor Program Onboarding process created successfully with all 10 stages. Process ID: ' + processId;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to initialize default process: ' + e.getMessage());
        }
    }

    // -------------------------------
    // Health Check
    // -------------------------------
    @AuraEnabled(cacheable=true)
    public static List<OnboardingHealthService.HealthItem> runOnboardingHealthCheck() {
        return OnboardingHealthService.runHealthCheck();
    }

    // -------------------------------
    // Initialize Vendor Program Onboarding
    // -------------------------------

    /**
     * Creates a Vendor Program, links it to a Process, and initializes the onboarding progress.
     * This sets up everything needed for the onboarding flow to start automatically.
     * For existing vendor programs with a vendor, it will skip vendor selection stages.
     */
    @AuraEnabled
    public static void initializeVendorProgramOnboarding(Id vendorProgramId, Id processId) {
        if (vendorProgramId == null || processId == null) {
            throw new AuraHandledException('Vendor Program ID and Process ID are required.');
        }

        // Check if progress already exists - if so, don't reset it (resume from saved progress)
        Onboarding_Application_Progress__c existingProgress = OnboardingApplicationRepository.fetchProgress(vendorProgramId, processId);
        if (existingProgress != null) {
            return; // Already initialized - flow engine will resume from Current_Stage__c
        }

        // Get stages to determine starting point
        List<Onboarding_Application_Stage__c> stages = OnboardingApplicationRepository.fetchStagesForProcess(processId);
        Id startingStageId = stages.isEmpty() ? null : stages[0].Id;

        // Check if vendor program already has a vendor - if so, skip vendor selection stages
        try {
            List<Vendor_Customization__c> programs = [
                SELECT Id, Vendor__c
                FROM Vendor_Customization__c
                WHERE Id = :vendorProgramId
                LIMIT 1
            ];

            if (!programs.isEmpty() && programs[0].Vendor__c != null) {
                // Vendor program exists and has a vendor - skip vendor selection stages
                // Find first non-vendor-selection stage
                for (Onboarding_Application_Stage__c stage : stages) {
                    String componentName = stage.Onboarding_Component_Library__r?.Component_API_Name__c;
                    // Skip: vendorProgramOnboardingVendor and vendorProgramOnboardingVendorProgramSearchOrCreate
                    if (componentName != 'vendorProgramOnboardingVendor' && 
                        componentName != 'vendorProgramOnboardingVendorProgramSearchOrCreate') {
                        startingStageId = stage.Id;
                        break;
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error checking vendor program data: ' + e.getMessage());
            // Continue with first stage if error
        }

        // Create progress record with appropriate starting stage
        Onboarding_Application_Progress__c progress = new Onboarding_Application_Progress__c(
            Vendor_Program__c = vendorProgramId,
            Onboarding_Application_Process__c = processId,
            Current_Stage__c = startingStageId
        );

        OnboardingApplicationRepository.upsertProgress(progress);
    }

    /**
     * DTO for Requirement Set hierarchy structure (Requirement Set with nested Templates)
     */
    public class RequirementSetHierarchyDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String displayLabel; // Display_Label__c field for Requirement Sets
        @AuraEnabled public String recordType; // 'requirementSet' or 'template'
        @AuraEnabled public String status;
        @AuraEnabled public Integer templateCount;
        @AuraEnabled public String requirementType; // For templates
        @AuraEnabled public Boolean isCurrentVersion; // For templates
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public DateTime lastModifiedDate;
        @AuraEnabled public String parentId;
        @AuraEnabled public List<RequirementSetHierarchyDTO> children; // Note: Apex doesn't allow _ prefix, will map to _children in JS
    }
}