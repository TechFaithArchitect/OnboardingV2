trigger ComplianceStatusTrigger on Dealer_Compliance__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Dealer_Compliance__c');
    }
}