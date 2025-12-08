@IsTest
private class EmailCommLoggerQueueableTest {

    @IsTest
    static void testQueueableCreatesLog() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO();

        Test.startTest();
        System.enqueueJob(new EmailCommLoggerQueueable(emailCommSendRequestDTO));
        Test.stopTest();

        List<Email_Communication_Log__c> emailCommLogs = [
            SELECT Subject__c, To_Address__c, HTML_Body__c, Status__c
            FROM Email_Communication_Log__c
            WHERE To_Address__c = :emailCommSendRequestDTO.toAddress
        ];
        
        System.assertEquals(1, emailCommLogs.size(), 'Expected 1 log to be inserted');
        System.assertEquals('Sent', emailCommLogs[0].Status__c);
        System.assertEquals(emailCommSendRequestDTO.subject, emailCommLogs[0].Subject__c);
    }
}