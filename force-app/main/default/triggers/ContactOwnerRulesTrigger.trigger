trigger ContactOwnerRulesTrigger on Contact (before insert, before update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    ContactOwnerRulesHandler.applyAuthorizationRules(Trigger.new);
    }
}