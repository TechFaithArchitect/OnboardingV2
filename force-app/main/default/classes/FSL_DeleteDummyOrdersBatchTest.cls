@isTest
private class FSL_DeleteDummyOrdersBatchTest {
    private static final String GUEST_USER_NAME = 'SelfScheduleGuest';

    @testSetup
    static void makeData() {
        insert new FSL_Settings__c(Self_Schedule_Guest_User_Name__c = GUEST_USER_NAME);

        User guestUser = new User(
            LastName = GUEST_USER_NAME,
            Alias = 'guest',
            Email = 'FSL_DeleteDummyOrdersBatchTest' + DateTime.now().getTime() + '@hikko.com',
            UserName = 'FSL_DeleteDummyOrdersBatchTest' + DateTime.now().getTime() + '@hikko.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert guestUser;

        System.runAs(guestUser) {
            insert new WorkOrder(
                Subject = 'Dummy Work Order',
                Status = 'New'
            );
        }
    }

    @isTest
    static void executeTest() {
        Test.startTest();
        Database.executeBatch(new FSL_DeleteDummyOrdersBatch(), 100);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder WHERE Subject = 'Dummy Work Order'];
        System.assertEquals(0, workOrders.size(), 'WorkOrder should have been deleted by the batch.');
    }

    @isTest
    static void testErrorHandling() {
        FSL_DeleteDummyOrdersBatch.throwException = true;

        Test.startTest();
        Database.executeBatch(new FSL_DeleteDummyOrdersBatch(), 100);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT  Id, Type__c, Provider__c, Component__c, Error__c, CreatedDate
            FROM    Error_Log__c
            WHERE   Component__c = 'FSL_DeleteDummyOrdersBatch'
        ];

        Assert.areEqual(1, errorLogs.size(), 'Should have created an error log.');
    }
}