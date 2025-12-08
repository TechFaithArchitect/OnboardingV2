@isTest
private class POE_DeleteMapsLocationRecordsBatchTest {
    @TestSetup
    static void makeData() {
        List<maps__Location__c> testRecords = new List<maps__Location__c>();
        for (Integer i = 0; i < 200; i++) {
            testRecords.add(
                new maps__Location__c(Name = 'Test Location ' + i, RecordType = new RecordType(Name = 'ClickerGeoCode'))
            );
        }
        insert testRecords;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        POE_DeleteMapsLocationRecordsBatch batchInstance = new POE_DeleteMapsLocationRecordsBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();

        List<maps__Location__c> remainingRecords = [
            SELECT Id
            FROM maps__Location__c
            WHERE RecordType.Name = 'ClickerGeoCode'
        ];

        System.assertEquals(0, remainingRecords.size(), 'All records were deleted');
    }

    @isTest
    static void testScheduling() {
        Test.startTest();
        POE_DeleteMapsLocationRecordsBatch batchInstance = new POE_DeleteMapsLocationRecordsBatch();
        String cronSchedule = '0 30 0 ? * 6';
        String jobId = System.schedule('Schedulablejob', cronSchedule, batchInstance);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        Test.stopTest();
        System.assertEquals(0, ct.TimesTriggered, 'Class was not scheduled.');
        System.assertEquals('0 30 0 ? * 6', ct.CronExpression, 'Class was not scheduled.');
    }
}