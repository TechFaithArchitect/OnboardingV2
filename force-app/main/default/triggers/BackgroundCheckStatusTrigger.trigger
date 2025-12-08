trigger BackgroundCheckStatusTrigger on Background_Check__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Background_Check__c');
    }
}