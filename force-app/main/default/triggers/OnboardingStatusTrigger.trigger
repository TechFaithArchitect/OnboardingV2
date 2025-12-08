trigger OnboardingStatusTrigger on Onboarding__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
        OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap, 'Onboarding__c');
    }
}