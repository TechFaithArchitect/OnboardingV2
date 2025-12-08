trigger InsuranceStatusTrigger on Dealer_Insurance__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Dealer_Insurance__c');
    }
}