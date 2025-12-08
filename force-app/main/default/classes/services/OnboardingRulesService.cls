public with sharing class OnboardingRulesService {
    
    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rule__c> getRulesEngineRecords(Id engineId) {
        return OnboardingRulesRepository.fetchRulesEngineRecords(engineId);
    }

    @AuraEnabled
    public static Onboarding_Status_Rule__c createOrUpdateRule(Onboarding_Status_Rule__c rule) {
        return OnboardingRulesRepository.upsertRule(rule);
    }

    @AuraEnabled
    public static void deleteRule(Id ruleId) {
        OnboardingRulesRepository.deleteRule(ruleId);
    }

    public class OnboardingEvaluationContext {
        public Map<Id, Onboarding_Requirement__c> requirementsByVPR;
        public Id vendorProgramId;
        public List<Id> groupIds;
    }

    public static OnboardingEvaluationContext getEvaluationContext(Id onboardingId) {
        Onboarding__c onboarding = OnboardingRulesRepository.fetchOnboardingWithRequirements(onboardingId);
        
        if (onboarding == null) return null;
        
        OnboardingEvaluationContext context = new OnboardingEvaluationContext();
        context.vendorProgramId = onboarding.Vendor_Customization__c;
        
        context.requirementsByVPR = new Map<Id, Onboarding_Requirement__c>();
        for (Onboarding_Requirement__c req : onboarding.Onboarding_Requirements__r) {
            context.requirementsByVPR.put(req.Vendor_Program_Requirement__c, req);
        }
        
        context.groupIds = getVendorProgramGroupIds(context.vendorProgramId);
        
        return context;
    }

    public static List<Onboarding_Status_Rules_Engine__c> getRulesForGroups(List<Id> groupIds) {
        return OnboardingRulesRepository.fetchRulesForGroups(groupIds);
    }

    public static Map<Id, Map<Id, Onboarding_Requirement__c>> getRequirementsByVPRBulk(Set<Id> onboardingIds) {
        Map<Id, Map<Id, Onboarding_Requirement__c>> result = new Map<Id, Map<Id, Onboarding_Requirement__c>>();
        
        List<Onboarding_Requirement__c> requirements = OnboardingRulesRepository.fetchRequirementsByOnboardingIds(onboardingIds);
        
        for (Onboarding_Requirement__c req : requirements) {
            if (!result.containsKey(req.Onboarding__c)) {
                result.put(req.Onboarding__c, new Map<Id, Onboarding_Requirement__c>());
            }
            if (req.Vendor_Program_Requirement__c != null) {
                result.get(req.Onboarding__c).put(req.Vendor_Program_Requirement__c, req);
            }
        }
        
        return result;
    }

    public static Map<Id, Id> getVendorProgramIdsBulk(Set<Id> onboardingIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        
        List<Onboarding__c> onboardings = OnboardingRulesRepository.fetchOnboardingsByIds(onboardingIds);
        
        for (Onboarding__c ob : onboardings) {
            result.put(ob.Id, ob.Vendor_Customization__c);
        }
        
        return result;
    }

    public static Map<Id, List<Id>> getVendorProgramGroupIdsBulk(Set<Id> vendorProgramIds) {
        Map<Id, List<Id>> result = new Map<Id, List<Id>>();
        
        List<Vendor_Program_Group_Member__c> members = OnboardingRulesRepository.fetchGroupMembersByVendorProgramIds(vendorProgramIds);
        
        for (Vendor_Program_Group_Member__c member : members) {
            if (!result.containsKey(member.Required_Program__c)) {
                result.put(member.Required_Program__c, new List<Id>());
            }
            result.get(member.Required_Program__c).add(member.Vendor_Program_Group__c);
        }
        
        return result;
    }
    
    public static List<Id> getVendorProgramGroupIds(Id vendorProgramId) {
        List<Id> groupIds = new List<Id>();
        
        List<Vendor_Program_Group_Member__c> members = OnboardingRulesRepository.fetchGroupMembersByVendorProgramId(vendorProgramId);
        
        for (Vendor_Program_Group_Member__c member : members) {
            groupIds.add(member.Vendor_Program_Group__c);
        }
        
        return groupIds;
    }

    /**
     * Gets rules engines by vendor program group and requirement group
     * @param vendorProgramGroupId Vendor Program Group ID
     * @param requirementGroupId Requirement Group ID
     * @return List of rules engines
     */
    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rules_Engine__c> getRulesEngines(Id vendorProgramGroupId, Id requirementGroupId) {
        return OnboardingRulesRepository.fetchRulesEnginesByGroups(vendorProgramGroupId, requirementGroupId);
    }

    /**
     * Gets rules engines by vendor program group only
     * @param vendorProgramGroupId Vendor Program Group ID
     * @return List of rules engines
     */
    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rules_Engine__c> getRulesEnginesByVendorProgramGroup(Id vendorProgramGroupId) {
        return OnboardingRulesRepository.fetchRulesEnginesByVendorProgramGroup(vendorProgramGroupId);
    }

    /**
     * Gets a single rules engine by ID
     * @param ruleId Rules engine ID
     * @return Rules engine or null if not found
     */
    @AuraEnabled(cacheable=true)
    public static Onboarding_Status_Rules_Engine__c getRulesEngine(Id ruleId) {
        return OnboardingRulesRepository.fetchRulesEngineById(ruleId);
    }

    /**
     * Gets conditions (rules) for a rules engine
     * @param ruleId Rules engine ID
     * @return List of status rules
     */
    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rule__c> getConditions(Id ruleId) {
        return OnboardingRulesRepository.fetchConditionsByRuleId(ruleId);
    }

    /**
     * Saves (updates) rules engines in bulk
     * @param rulesEngines List of rules engines to update
     */
    @AuraEnabled
    public static void saveRulesEngines(List<Onboarding_Status_Rules_Engine__c> rulesEngines) {
        if (rulesEngines == null || rulesEngines.isEmpty()) {
            return;
        }
        OnboardingRulesRepository.updateRulesEngines(rulesEngines);
    }

    /**
     * Saves (upserts) a single rules engine
     * @param rulesEngine Rules engine to upsert
     * @return Upserted rules engine
     */
    @AuraEnabled
    public static Onboarding_Status_Rules_Engine__c saveRulesEngine(Onboarding_Status_Rules_Engine__c rulesEngine) {
        ValidationHelper.requireRecord(rulesEngine, 'Rules engine');
        return OnboardingRulesRepository.upsertRulesEngine(rulesEngine);
    }

    /**
     * Saves (upserts) conditions in bulk
     * @param conditions List of status rules to upsert
     */
    @AuraEnabled
    public static void saveConditions(List<Onboarding_Status_Rule__c> conditions) {
        if (conditions == null || conditions.isEmpty()) {
            return;
        }
        OnboardingRulesRepository.upsertConditions(conditions);
    }
}