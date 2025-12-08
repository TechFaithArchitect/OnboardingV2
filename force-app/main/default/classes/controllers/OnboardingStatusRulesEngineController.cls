public with sharing class OnboardingStatusRulesEngineController {

    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rules_Engine__c> getRules(Id vendorProgramGroupId, Id requirementGroupId) {
        return OnboardingRulesService.getRulesEngines(vendorProgramGroupId, requirementGroupId);
    }

    @AuraEnabled
    public static void saveRules(List<Onboarding_Status_Rules_Engine__c> rules) {
        OnboardingRulesService.saveRulesEngines(rules);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getVendorProgramGroups() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Vendor_Program_Group__c vendorProgramGroup : [
            SELECT Id, Name 
            FROM Vendor_Program_Group__c 
            ORDER BY Name 
            LIMIT 1000
        ]) {
            options.add(new Map<String, String>{
                'value' => vendorProgramGroup.Id,
                'label' => vendorProgramGroup.Name
            });
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRequirementGroups() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup : [
            SELECT Id, Name 
            FROM Vendor_Program_Requirement_Group__c 
            ORDER BY Name 
            LIMIT 1000
        ]) {
            options.add(new Map<String, String>{
                'value' => vendorProgramRequirementGroup.Id,
                'label' => vendorProgramRequirementGroup.Name
            });
        }
        return options;
    }
}

