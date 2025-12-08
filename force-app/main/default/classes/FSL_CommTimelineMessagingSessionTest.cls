@IsTest
private class FSL_CommTimelineMessagingSessionTest {

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

        MessagingChannel messagingChannel = [SELECT Id FROM MessagingChannel WHERE DeveloperName LIKE '%TEXT_US_1%'];

        MessagingEndUser messagingEndUser = new MessagingEndUser(
            Name = 'Test End User',
            MessagingChannelId = messagingChannel.Id,
            MessageType = 'Text',
            MessagingPlatformKey = '+1234567890'
        );
        insert messagingEndUser;

        MessagingSession messagingSession = new MessagingSession(
            StartTime = System.now(),
            MessagingChannelId = messagingChannel.Id,
            MessagingEndUserId = messagingEndUser.Id,
            Status = 'Active'
        );
        insert messagingSession;
        messagingSession.Service_Appointment__c = serviceAppointment.Id;
        update messagingSession;

        ConversationEntry conversationEntry = new ConversationEntry(
            ConversationId = messagingSession.Id,
            Message = 'Test SMS message content',
            EntryTime = System.now(),
            EntryType = 'Text',
            ActorType = 'System',
            Seq = 0
        );
        insert conversationEntry;
    }

    @IsTest
    static void testGetRecords() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        List<Id> excludeIds = new List<Id>();
        Integer queryLimit = 10;

        Test.startTest();
        List<FSL_CommunicationTimelineItem> result = FSL_CommTimelineMessagingSession.getRecords(serviceAppointment.Id, excludeIds, queryLimit);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 item');
        Assert.areEqual('SMS', result[0].type, 'Type should be SMS');
    }
}