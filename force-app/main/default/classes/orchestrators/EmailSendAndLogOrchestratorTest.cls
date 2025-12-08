@isTest
private class EmailSendAndLogOrchestratorTest {

    @isTest
    static void testOrchestrateSendAndLog_syncLogging() {
        TestDataFactoryWrapper.EmailCommWrapper emailCommWrapper = TestDataFactory.createEmailCommSendWrapper(1, true);

        // Use a mock Id for EmailMessage since it may not have an Id in test context
        // EmailMessage is a special object that may not be insertable in test context
        Id mockEmailMessageId = (emailCommWrapper.msg != null && emailCommWrapper.msg.Id != null) 
            ? emailCommWrapper.msg.Id 
            : (Id)('00X000000000000AAA'); // Mock EmailMessage Id pattern

        EmailCommSenderService.testResultOverride = new EmailCommSendResultDTO(
            'Success',
            mockEmailMessageId,
            null
        );

        emailCommWrapper.dto.logSync = true;

        Test.startTest();
        EmailCommSendResultDTO result = EmailSendAndLogOrchestrator.orchestrateSendAndLog(emailCommWrapper.dto);
        Test.stopTest();

        System.assertEquals('Success', result.status);
        System.assertNotEquals(null, result.emailMessageId);
    }

    @isTest
    static void testOrchestrateSendAndLog_asyncLogging() {
        TestDataFactoryWrapper.EmailCommWrapper emailCommWrapper = TestDataFactory.createEmailCommSendWrapper(1, true);

        // Use a mock Id for EmailMessage since it may not have an Id in test context
        // EmailMessage is a special object that may not be insertable in test context
        Id mockEmailMessageId = (emailCommWrapper.msg != null && emailCommWrapper.msg.Id != null) 
            ? emailCommWrapper.msg.Id 
            : (Id)('00X000000000000AAA'); // Mock EmailMessage Id pattern

        EmailCommSenderService.testResultOverride = new EmailCommSendResultDTO(
            'Success',
            mockEmailMessageId,
            null
        );

        emailCommWrapper.dto.logSync = false;

        Test.startTest();
        EmailCommSendResultDTO result = EmailSendAndLogOrchestrator.orchestrateSendAndLog(emailCommWrapper.dto);
        Test.stopTest();

        System.assertEquals('Success', result.status);
        System.assertNotEquals(null, result.emailMessageId);
        System.assertEquals(null, result.errorMessage);
    }

    @isTest
    static void testOrchestrateBulk() {
        List<EmailCommSendRequestDTO> emailCommSendRequests = new List<EmailCommSendRequestDTO>();

        for (Integer i = 0; i < 2; i++) {
            TestDataFactoryWrapper.EmailCommWrapper emailCommWrapper = TestDataFactory.createEmailCommSendWrapper(1, true);
            emailCommSendRequests.add(emailCommWrapper.dto);

            // Use a mock Id for EmailMessage since it may not have an Id in test context
            // EmailMessage is a special object that may not be insertable in test context
            String mockIdSuffix = String.valueOf(i).length() == 1 ? '00' + String.valueOf(i) : (String.valueOf(i).length() == 2 ? '0' + String.valueOf(i) : String.valueOf(i));
            Id mockEmailMessageId = (emailCommWrapper.msg != null && emailCommWrapper.msg.Id != null) 
                ? emailCommWrapper.msg.Id 
                : (Id)('00X000000000000' + mockIdSuffix + 'AAA'); // Unique mock EmailMessage Id

            EmailCommSenderService.testResultOverride = new EmailCommSendResultDTO(
                'Success',
                mockEmailMessageId,
                null
            );
        }

        Test.startTest();
        List<EmailCommSendResultDTO> results = EmailSendAndLogOrchestrator.orchestrateBulk(emailCommSendRequests);
        Test.stopTest();

        System.assertEquals(2, results.size());
        for (EmailCommSendResultDTO result : results) {
            System.assertEquals('Success', result.status);
            System.assertNotEquals(null, result.emailMessageId);
        }
    }
}