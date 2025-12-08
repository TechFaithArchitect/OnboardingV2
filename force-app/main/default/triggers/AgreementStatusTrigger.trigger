trigger AgreementStatusTrigger on echosign_dev1__SIGN_Agreement__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'echosign_dev1__SIGN_Agreement__c');
    }
}