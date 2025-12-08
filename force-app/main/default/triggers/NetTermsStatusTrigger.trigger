trigger NetTermsStatusTrigger on Net_Terms__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Net_Terms__c');
    }
}