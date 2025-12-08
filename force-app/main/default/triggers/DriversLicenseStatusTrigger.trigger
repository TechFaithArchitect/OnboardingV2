trigger DriversLicenseStatusTrigger on License__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'License__c');
    }
}