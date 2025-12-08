@isTest
public class POE_CCEncryptionKeyGenSchedulableTest {
    @isTest
    static void testExecuteMethod() {
        Test.startTest();
        String cronExpr = '0 0 1 * * ?';
        System.schedule('Test CC Scheduler', cronExpr, new POE_CCEncryptionKeyGenerationSchedulable());
        Test.stopTest();
        CronTrigger job = [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType
            FROM CronTrigger
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assert.areEqual(job.CronJobDetail.Name, 'Test CC Scheduler', 'Task successfully scheduled');
    }
}