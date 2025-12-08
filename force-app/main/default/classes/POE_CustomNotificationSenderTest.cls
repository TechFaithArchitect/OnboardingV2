@isTest
public with sharing class POE_CustomNotificationSenderTest {

    private static final String TEST_SUBJECT = Task.Subject.getDescribe().getPicklistValues()[0].getValue();
    private static final String TEST_PRIORITY = Task.Priority.getDescribe().getPicklistValues()[0].getValue();
    private static final String TEST_CURRENCY = Task.CurrencyIsoCode.getDescribe().getPicklistValues()[0].getValue();
    private static final String TEST_STATUS = Task.Status.getDescribe().getPicklistValues()[0].getValue();

    @TestSetup
    static void setup() {
        List<Task> testTasks = new List<Task>();
        for (Integer i  = 0; i < 200; i++) {
            testTasks.add(new Task(
                Subject = TEST_SUBJECT,
                OwnerId = UserInfo.getUserId(),
                CurrencyIsoCode = TEST_CURRENCY,
                Priority = TEST_PRIORITY,
                Status = TEST_STATUS,
                ActivityDate = Date.today()
            ));
        }
        insert testTasks;
    }

    @isTest
    static void sendTaskNotificationsTest() {
        Boolean isSuccess = true;
        Test.startTest();
        try {
            POE_CustomNotificationSender.sendTaskNotifications();
        } catch (Exception e) {
            isSuccess = false;
        }
        Test.stopTest();

        Assert.isTrue(isSuccess, 'The notifications were not sent successfully.');
    }

    @isTest
    static void testSendTaskNotificationsException() {
        POE_CustomNotificationSender.throwException = true;

        Test.startTest();
        try {
            POE_CustomNotificationSender.sendTaskNotifications();
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }
}