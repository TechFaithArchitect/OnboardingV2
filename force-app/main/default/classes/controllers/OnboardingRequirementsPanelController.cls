public with sharing class OnboardingRequirementsPanelController {

    @AuraEnabled(cacheable=true)
    public static List<OnboardingApplicationService.RequirementDTO> getRequirements(Id onboardingId) {
        return OnboardingApplicationService.getRequirements(onboardingId);
    }

    @AuraEnabled
    public static void updateRequirementStatuses(List<OnboardingApplicationService.RequirementDTO> updates) {
        OnboardingApplicationService.updateRequirementStatuses(updates);
    }

    @AuraEnabled
    public static void runRuleEvaluation(Id onboardingId) {
        OnboardingApplicationService.runRuleEvaluation(onboardingId);
    }
}

