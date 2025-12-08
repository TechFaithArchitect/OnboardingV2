@IsTest
private class FSL_CommunicationsTimelineTest {

    @TestSetup
    static void setupTestData() {
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;

        Contact contact = PV_TestDataFactory.createContact('Test', 'Contact', true, account);

        WorkOrder workOrder = new WorkOrder(
            AccountId = account.Id,
            Subject = 'Test Work Order'
        );
        insert workOrder;

        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = workOrder.Id,
            Status = 'Unscheduled',
            DueDate = System.today().addDays(7),
            EarliestStartTime = System.now(),
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addHours(2)
        );
        insert serviceAppointment;

        List<Message_Log__c> messageLogs = new List<Message_Log__c>();
        for (Integer i = 0; i < FSL_CommunicationsTimeline.QUERY_LIMIT; i++) {
            messageLogs.add(new Message_Log__c(
                Service_Appointment__c = serviceAppointment.Id,
                Sent_Date__c = Datetime.now().addMinutes(i),
                To__c = '+1234567890',
                From__c = '+1987654321',
                Contact__c = contact.Id,
                Direction__c = 'Outbound',
                Status__c = 'Sent',
                Body__c = 'Test message ' + i
            ));
        }
        insert messageLogs;
    }

    @IsTest
    static void testGetRecords() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];

        List<Id> excludeIds = new List<Id>();

        Test.startTest();
        List<FSL_CommunicationTimelineItem> result = FSL_CommunicationsTimeline.getRecords(workOrder.Id, excludeIds);
        Test.stopTest();

        System.assertEquals(FSL_CommunicationsTimeline.QUERY_LIMIT, result.size(), 'Should return ' + FSL_CommunicationsTimeline.QUERY_LIMIT + ' communication timeline items');
        System.assertEquals('SMS', result[0].type, 'Type should be SMS');
    }
}