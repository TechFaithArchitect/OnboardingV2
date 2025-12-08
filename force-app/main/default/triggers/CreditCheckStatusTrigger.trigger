trigger CreditCheckStatusTrigger on Credit_Check__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Credit_Check__c');
    }
}