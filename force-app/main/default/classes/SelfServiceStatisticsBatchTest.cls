@isTest
public class SelfServiceStatisticsBatchTest {
    @TestSetup
    static void makeData() {
        Chuzo_Settings__c chuzoCS = Chuzo_Settings__c.getOrgDefaults();
        chuzoCS.Self_Service_Statistics_Archive__c = 1;
        upsert chuzoCS;

        List<Self_Service_Statistic__c> statistics = new List<Self_Service_Statistic__c>();
        for (Integer i = 0; i < 200; i++) {
            Self_Service_Statistic__c stat = new Self_Service_Statistic__c(
                Start_Time__c = Datetime.now(),
                Tab_Name__c = 'Products'
            );
            statistics.add(stat);
        }

        insert statistics;

        for (Integer i = 0; i < 100; i++) {
            Test.setCreatedDate(
                statistics[i].Id,
                Datetime.newInstanceGmt(date.today().year(), date.today().month(), date.today().day() - 1, 18, 0, 0)
            );
        }
    }

    @isTest
    static void test_selfServiceStatisticsBatchDeletion() {
        Test.startTest();
        Id batchProccessId = Database.executeBatch(new SelfServiceStatisticsBatch());
        Test.stopTest();

        List<Self_Service_Statistic__c> stats = [SELECT Id FROM Self_Service_Statistic__c];
        List<Error_Log__c> logs = [SELECT Id, Error__c, Component__c FROM Error_Log__c];

        System.assertEquals(1, logs.size(), 'An error log should had been created');
        System.assertEquals(100, stats.size(), 'Only 100 records should remain');
    }

    @isTest
    static void testScheduler() {
        Integer year = Date.Today().Year() + 1;
        String cronExpr = '0 0 0 15 3 ? ' + year;

        List<AsyncApexJob> jobsBefore = [SELECT Id, ApexClassID, ApexClass.Name, Status, JobType FROM AsyncApexJob];
        System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');

        Test.startTest();
        String jobId = System.schedule('myJobTestJobName', cronExpr, new SelfServiceStatisticsBatch());
        Test.stopTest();

        List<AsyncApexJob> jobsScheduled = [
            SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex'
        ];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals(
            'SelfServiceStatisticsBatch',
            jobsScheduled[0].ApexClass.Name,
            'expecting specific scheduled job'
        );

        List<AsyncApexJob> jobsApexBatch = [
            SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
        ];
        System.assertEquals(1, jobsApexBatch.size(), 'expecting one apex batch job');
        System.assertEquals(
            'SelfServiceStatisticsBatch',
            jobsApexBatch[0].ApexClass.Name,
            'expecting specific batch job'
        );
    }
}