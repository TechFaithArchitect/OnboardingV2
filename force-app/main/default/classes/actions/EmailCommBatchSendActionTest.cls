@isTest
private class EmailCommBatchSendActionTest {
    @isTest
    static void testExecuteSinglePayload() {
        TestDataFactoryWrapper.EmailCommWrapper emailCommWrapper = TestDataFactoryWrapper.createEmailCommSendWrapper(true, 0);

        EmailCommSendWrapper sendWrapper = new EmailCommSendWrapper();
        sendWrapper.payloads = new List<EmailCommSendRequestDTO>{ emailCommWrapper.dto };

        Test.startTest();
        List<EmailCommSendResultDTO> results = EmailCommBatchSendAction.execute(
            new List<EmailCommSendWrapper>{ sendWrapper }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one send result');
        System.assertNotEquals(null, results[0], 'Result should not be null');
    }
}