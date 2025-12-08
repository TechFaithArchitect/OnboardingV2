trigger ERPSetupStatusTrigger on ERP_Setup__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'ERP_Setup__c');
    }
}