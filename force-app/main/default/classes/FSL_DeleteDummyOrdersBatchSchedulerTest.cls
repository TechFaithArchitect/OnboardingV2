@isTest
private class FSL_DeleteDummyOrdersBatchSchedulerTest {
    @isTest
    static void testSchedulerExecution() {
        Test.startTest();
        String cronExpression = '0 0 2 * * ?';
        String jobId = System.schedule(FSL_DeleteDummyOrdersBatchSchedulerTest.class.getName(), cronExpression, new FSL_DeleteDummyOrdersBatchScheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'The job ID should not be null.');
    }
}