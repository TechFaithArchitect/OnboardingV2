public with sharing class POE_CustomNotificationSender {
    @testVisible
    private static Boolean throwException = false;

    @InvocableMethod(
        label='Send Task Notifications' 
        description='Sends a Custom Notification to all users with tasks due in the current date.'
    )
    public static void sendTaskNotifications() {
        Set<String> userIds = new Set<String>();

        for (Task t : [
            SELECT OwnerId
            FROM Task
            WHERE ActivityDate = :Date.today()
            AND Status != 'Completed'
        ]) {
            userIds.add(t.OwnerId);
        }

        if (userIds.size() > 0) {
            sendNotifications(
                System.Label.POE_Daily_Task_Remainder_Title,
                System.Label.POE_Daily_Task_Remainder_Body,
                System.Label.POE_Daily_Task_Remainder_Notification_Type,
                userIds,
                null,
                System.Label.POE_Daily_Task_Remainder_Target_Reference,
                null
            );
        }
    }

    public static void sendNotifications(
        String title,
        String body,
        String notificationTypeApiName,
        Set<String> recipientIds, 
        String targetId, 
        String targetPageRef,
        String senderId
    ) {
        CustomNotificationType notificationType = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = :notificationTypeApiName
        ];
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification(
            notificationType.Id, senderId, title, body, targetId, targetPageRef
        );
        
        try {
            if (throwException) {
                throw new CustomException();
            }

            notification.send(recipientIds);
        }
        catch (Exception e) {
            System.debug(e.getMessage());

            if (Test.isRunningTest()) {
                throw e;
            }
        }
    }
}