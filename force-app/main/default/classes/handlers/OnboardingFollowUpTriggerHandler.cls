public with sharing class OnboardingFollowUpTriggerHandler {

    private static final Set<String> TARGET_STATUSES = new Set<String>{
        'Incomplete', 'Not Started', 'In Progress', 'Partially_Completed', 'Needs_Correction'
    };

    public static void handleAfter(List<Onboarding__c> newRecords, Map<Id, Onboarding__c> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> onboardingIds = new Set<Id>();

        for (Onboarding__c ob : newRecords) {
            // Only enqueue if status is in target list
            if (ob.Onboarding_Status__c != null && TARGET_STATUSES.contains(ob.Onboarding_Status__c)) {
                if (Trigger.isInsert) {
                    onboardingIds.add(ob.Id);
                } else {
                    Onboarding__c oldRec = oldMap != null ? oldMap.get(ob.Id) : null;
                    if (oldRec == null || ob.Onboarding_Status__c != oldRec.Onboarding_Status__c) {
                        onboardingIds.add(ob.Id);
                    }
                }
            }
        }

        if (!onboardingIds.isEmpty()) {
            FollowUpDetectionService.enqueueFollowUps(onboardingIds);
        }
    }
}
