@isTest
private class EmailCommSendActionTest {

    @isTest
    static void testSingleRequestSuccess() {
        // Arrange
        TestDataFactoryWrapper.EmailCommWrapper emailCommWrapper = TestDataFactoryWrapper.createEmailCommSendWrapper(true, 0);
        EmailCommSendRequestDTO emailCommSendRequestDTO = emailCommWrapper.dto;

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

        EmailCommSendAction.Request emailCommSendRequest = new EmailCommSendAction.Request();
        emailCommSendRequest.toAddress = emailCommSendRequestDTO.toAddress;
        emailCommSendRequest.subject = emailCommSendRequestDTO.subject;
        emailCommSendRequest.htmlBody = emailCommSendRequestDTO.htmlBody;
        emailCommSendRequest.textBody = emailCommSendRequestDTO.textBody;
        emailCommSendRequest.contactId = emailCommSendRequestDTO.contactId;
        emailCommSendRequest.accountId = emailCommSendRequestDTO.accountId;
        emailCommSendRequest.onboardingId = emailCommSendRequestDTO.onboardingId;
        emailCommSendRequest.communicationTemplateId = emailCommSendRequestDTO.communicationTemplateId;
        emailCommSendRequest.orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        emailCommSendRequest.senderType = 'OrgWide';
        emailCommSendRequest.logSync = true;

        // Act
        Test.startTest();
        List<EmailCommSendAction.Result> results = EmailCommSendAction.send(new List<EmailCommSendAction.Request>{ emailCommSendRequest });
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size());
        System.assertEquals('Success', results[0].status);
        System.assertEquals(null, results[0].errorMessage);
        System.assertNotEquals(null, results[0].emailMessageId);
    }

    @isTest
    static void testBulkRequests() {
        List<EmailCommSendAction.Request> emailCommSendRequests = new List<EmailCommSendAction.Request>();

        for (Integer i = 0; i < 3; i++) {
            TestDataFactoryWrapper.EmailCommWrapper emailCommWrapper = TestDataFactoryWrapper.createEmailCommSendWrapper(true, 0);
            EmailCommSendRequestDTO emailCommSendRequestDTO = emailCommWrapper.dto;

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

            EmailCommSendAction.Request emailCommSendRequest = new EmailCommSendAction.Request();
            emailCommSendRequest.toAddress = emailCommSendRequestDTO.toAddress;
            emailCommSendRequest.subject = emailCommSendRequestDTO.subject;
            emailCommSendRequest.htmlBody = emailCommSendRequestDTO.htmlBody;
            emailCommSendRequest.textBody = emailCommSendRequestDTO.textBody;
            emailCommSendRequest.contactId = emailCommSendRequestDTO.contactId;
            emailCommSendRequest.accountId = emailCommSendRequestDTO.accountId;
            emailCommSendRequest.onboardingId = emailCommSendRequestDTO.onboardingId;
            emailCommSendRequest.communicationTemplateId = emailCommSendRequestDTO.communicationTemplateId;
            emailCommSendRequest.senderType = 'OrgWide';
            emailCommSendRequest.orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;

            emailCommSendRequests.add(emailCommSendRequest);
        }

        // Act
        Test.startTest();
        List<EmailCommSendAction.Result> results = EmailCommSendAction.send(emailCommSendRequests);
        Test.stopTest();

        // Assert
        System.assertEquals(3, results.size(), 'Should return one result per request');
        for (EmailCommSendAction.Result result : results) {
            System.assertEquals('Success', result.status);
            System.assertEquals(null, result.errorMessage);
            System.assertNotEquals(null, result.emailMessageId);
        }
    }
}