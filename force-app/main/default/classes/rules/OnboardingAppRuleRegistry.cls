public with sharing class OnboardingAppRuleRegistry {

    // Validation Rules Registry (for other objects)
    public static Map<String, List<OnboardingAppValidationRule>> getValidationRules() {
        return new Map<String, List<OnboardingAppValidationRule>> {
            'Vendor_Program_Recipient_Group__c' => new List<OnboardingAppValidationRule>{
                new RequireParentVersionOnActivationRule(),
                new OnlyOneActiveRecGrpPerPrgrmRule(),
                new RecipientAndProgramMustBeActiveRule(),
                new PreventDupRecGrpAssignmentRule()
            }

            // Add additional validation rule groups here...
        };
    }

    // ✅ Activation Rules Registry
    public static List<OnboardingAppActivationRule> getActivationRulesForObject(String objectApiName) {
        List<OnboardingAppActivationRule> rules = new List<OnboardingAppActivationRule>();

        if (objectApiName == 'Vendor_Program__c') {
            rules.add(new AllChildRequirementsMustBeActiveRule());
            rules.add(new AllTemplatesInReqSetMustBeActiveRule());
        }

        if (objectApiName == 'Vendor_Customization__c') {
            rules.add(new AllRequirementGroupsMustBeActiveRule());
        }

        if (objectApiName == 'Onboarding_Status_Rule__c') {
            rules.add(new AllLinkedEngineMustBeActiveRule());
        }

        if (objectApiName == 'Onboarding_Status_Rules_Engine__c') {
            rules.add(new AllStatusRulesMustBeActiveRule());
            rules.add(new AllStatusRuleGroupMustBeActiveRule());
        }

        return rules;
    }
}
