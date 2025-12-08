trigger LearnUponContactEnrollmentStatusTrigger on LearnUponP__LearnUponContactEnrollment__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'LearnUponP__LearnUponContactEnrollment__c');
    }
}