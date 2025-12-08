trigger PersonalGuaranteeStatusTrigger on Personal_Guarantee__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Personal_Guarantee__c');
    }
}