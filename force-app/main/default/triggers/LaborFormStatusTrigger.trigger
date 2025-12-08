trigger LaborFormStatusTrigger on Labor_Form__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Labor_Form__c');
    }
}