trigger ClearingHouseStatusTrigger on Clearing_House__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Clearing_House__c');    
    }
}