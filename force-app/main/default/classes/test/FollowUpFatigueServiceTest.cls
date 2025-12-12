@isTest
private class FollowUpFatigueServiceTest {

    @isTest
    static void shouldSuppressWhenAttemptsExceedWindow() {
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true);

        // Two follow-ups within window totaling > default maxAttempts (3)
        List<Follow_Up_Queue__c> queues = new List<Follow_Up_Queue__c>{
            new Follow_Up_Queue__c(
                Onboarding_Requirement__c = req.Id,
                Attempt_Count__c = 2,
                Last_Attempt_Date__c = DateTime.now().addDays(-1),
                Is_Archived__c = false
            ),
            new Follow_Up_Queue__c(
                Onboarding_Requirement__c = req.Id,
                Attempt_Count__c = 2,
                Last_Attempt_Date__c = DateTime.now().addDays(-2),
                Is_Archived__c = false
            )
        };
        insert queues;

        Test.startTest();
        Boolean suppressed = FollowUpFatigueService.shouldSuppressDueToFatigue(req.Id, null);
        Test.stopTest();

        System.assertEquals(true, suppressed, 'Should suppress when attempts exceed default max');
    }

    @isTest
    static void shouldNotSuppressWhenBelowThreshold() {
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true);
        Follow_Up_Queue__c queue = new Follow_Up_Queue__c(
            Onboarding_Requirement__c = req.Id,
            Attempt_Count__c = 1,
            Last_Attempt_Date__c = DateTime.now().addDays(-1),
            Is_Archived__c = false
        );
        insert queue;

        Test.startTest();
        Boolean suppressed = FollowUpFatigueService.shouldSuppressDueToFatigue(req.Id, null);
        Test.stopTest();

        System.assertEquals(false, suppressed, 'Should not suppress when attempts under max');
    }

    @isTest
    static void applyAndRemoveSuppressionUpdatesQueue() {
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true);
        Follow_Up_Queue__c queue = new Follow_Up_Queue__c(
            Onboarding_Requirement__c = req.Id,
            Attempt_Count__c = 1,
            Last_Attempt_Date__c = DateTime.now(),
            Is_Archived__c = false,
            Status__c = 'Pending'
        );
        insert queue;

        Test.startTest();
        FollowUpFatigueService.applyFatigueSuppression(queue.Id, 'Test');
        Boolean suppressed = FollowUpFatigueService.isSuppressed(queue.Id);
        FollowUpFatigueService.removeSuppression(queue.Id);
        Boolean suppressedAfter = FollowUpFatigueService.isSuppressed(queue.Id);
        Test.stopTest();

        System.assertEquals(true, suppressed, 'Queue should be marked suppressed');
        System.assertEquals(false, suppressedAfter, 'Queue suppression should be removed');
    }

    @isTest
    static void updateAttemptTrackingIncrementsCounts() {
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true);
        Follow_Up_Queue__c queue = new Follow_Up_Queue__c(
            Onboarding_Requirement__c = req.Id,
            Attempt_Count__c = 0,
            Consecutive_Failures__c = 0,
            Last_Attempt_Date__c = DateTime.now().addDays(-3),
            Is_Archived__c = false,
            Status__c = 'Pending'
        );
        insert queue;

        Test.startTest();
        FollowUpFatigueService.updateAttemptTracking(queue.Id, false);
        FollowUpFatigueService.updateAttemptTracking(queue.Id, true);
        Test.stopTest();

        Follow_Up_Queue__c refreshed = [
            SELECT Attempt_Count__c, Consecutive_Failures__c, Last_Attempt_Date__c
            FROM Follow_Up_Queue__c
            WHERE Id = :queue.Id
        ];

        System.assertEquals(2, refreshed.Attempt_Count__c, 'Attempt count should increment per call');
        System.assertEquals(0, refreshed.Consecutive_Failures__c, 'Successful attempt should reset consecutive failures');
        System.assertNotEquals(null, refreshed.Last_Attempt_Date__c, 'Last attempt date should be set');
    }
}
