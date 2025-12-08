@IsTest
private class FSL_CommTimelineTaskTest {

    @TestSetup
    static void setupTestData() {
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;

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

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = account.Id
        );
        insert contact;

        Task task = new Task(
            WhatId = serviceAppointment.Id,
            WhoId = contact.Id,
            Type = 'Email',
            Subject = 'Test Email Task',
            Description = 'This is a test email task description',
            Status = 'Completed',
            Priority = 'Normal'
        );
        insert task;
    }

    @IsTest
    static void testGetRecords() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        List<Id> excludeIds = new List<Id>();
        Integer queryLimit = 10;

        Test.startTest();
        List<FSL_CommunicationTimelineItem> result = FSL_CommTimelineTask.getRecords(serviceAppointment.Id, excludeIds, queryLimit);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 item');
        Assert.areEqual('Email', result[0].type, 'Type should be Email');
    }
}