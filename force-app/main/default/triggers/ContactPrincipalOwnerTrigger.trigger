trigger ContactPrincipalOwnerTrigger on Contact (before insert, before update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    ContactPrincipalOwnerTriggerHandler.checkPrincipalOwnerLimit(Trigger.new, Trigger.oldMap);
    }
}