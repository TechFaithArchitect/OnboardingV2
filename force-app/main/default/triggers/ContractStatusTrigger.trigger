trigger ContractStatusTrigger on Contract (after update) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Contract');
}