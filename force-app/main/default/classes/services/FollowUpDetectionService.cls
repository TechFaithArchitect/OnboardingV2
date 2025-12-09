public with sharing class FollowUpDetectionService {

    @TestVisible private static List<Follow_Up_Rule__mdt> TEST_RULES;

    /**
     * Enqueue follow-ups for the given onboarding records based on active Follow_Up_Rule__mdt.
     * @param onboardingIds Set of Onboarding__c Ids
     */
    public static void enqueueFollowUps(Set<Id> onboardingIds) {
        if (onboardingIds == null || onboardingIds.isEmpty()) {
            return;
        }

        List<Follow_Up_Rule__mdt> rules = getActiveRules();
        if (rules.isEmpty()) {
            return;
        }

        Map<Id, Onboarding__c> onboardings = new Map<Id, Onboarding__c>([
            SELECT Id, Account__c
            FROM Onboarding__c
            WHERE Id IN :onboardingIds
        ]);

        DateTime now = DateTime.now();
        List<Follow_Up_Queue__c> toInsert = new List<Follow_Up_Queue__c>();

        for (Onboarding__c ob : onboardings.values()) {
            // Suppression check at account level
            if (FollowUpFatigueService.isSuppressedAccount(ob.Account__c)) {
                continue;
            }

            for (Follow_Up_Rule__mdt rule : rules) {
                DateTime nextAttempt = now;
                if (rule.Initial_Delay_Days__c != null) {
                    nextAttempt = now.addDays(rule.Initial_Delay_Days__c.intValue());
                }

                Follow_Up_Queue__c fq = new Follow_Up_Queue__c(
                    Onboarding__c = ob.Id,
                    Follow_Up_Type__c = rule.Follow_Up_Type__c,
                    Status__c = 'Pending',
                    Trigger_Reason__c = rule.Trigger_Condition__c,
                    Next_Attempt_Date__c = nextAttempt,
                    Follow_Up_Rule__c = rule.DeveloperName,
                    Priority__c = 'Medium'
                );
                toInsert.add(fq);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    @TestVisible
    private static List<Follow_Up_Rule__mdt> getActiveRules() {
        if (Test.isRunningTest() && TEST_RULES != null) {
            return TEST_RULES;
        }
        return [
            SELECT DeveloperName, Follow_Up_Type__c, Trigger_Condition__c,
                   Initial_Delay_Days__c, Escalation_Schedule__c,
                   Messaging_Channel__c, Messaging_Template__c,
                   Max_Attempts_Per_Window__c, Fatigue_Window_Days__c, Fatigue_Suppression_Enabled__c,
                   Active__c
            FROM Follow_Up_Rule__mdt
            WHERE Active__c = true
        ];
    }
}
