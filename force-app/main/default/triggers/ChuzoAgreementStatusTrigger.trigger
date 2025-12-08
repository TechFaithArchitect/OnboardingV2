trigger ChuzoAgreementStatusTrigger on Chuzo_Agreement__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Chuzo_Agreement__c');
    }
}