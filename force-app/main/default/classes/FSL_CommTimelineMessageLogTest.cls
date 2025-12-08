@IsTest
private class FSL_CommTimelineMessageLogTest {

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

        Message_Log__c messageLog = new Message_Log__c(
            Service_Appointment__c = serviceAppointment.Id,
            Sent_Date__c = Datetime.now(),
            To__c = '+1234567890',
            From__c = '+1987654321',
            Contact__c = contact.Id,
            Direction__c = 'Outbound',
            Status__c = 'Sent',
            Body__c = 'Test message'
        );
        insert messageLog;
    }

    @IsTest
    static void testGetRecords() {
        ServiceAppointment testServiceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        List<Id> excludeIds = new List<Id>();
        Integer queryLimit = 10;

        Test.startTest();
        List<FSL_CommunicationTimelineItem> result = FSL_CommTimelineMessageLog.getRecords(testServiceAppointment.Id, excludeIds, queryLimit);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 item');
        Assert.areEqual('SMS', result[0].type, 'Type should be SMS');
    }
}