@IsTest
public class EmailCommSenderServiceTest {

    @IsTest
    static void testSendBasicEmailSuccess() {
        TestDataFactoryWrapper.EmailCommWrapper emailCommWrapper = TestDataFactory.createEmailCommSendRequestDTO(true);
        EmailCommSendRequestDTO emailCommSendRequestDTO = emailCommWrapper.dto;

        Test.startTest();
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals('Success', result.status);
        System.assertNotEquals(null, result.emailMessageId, 'EmailMessageId should be returned');
        System.assertEquals(null, result.errorMessage);
    }

    @IsTest
    static void testSendWithMissingSenderTypeDefaultsToCurrentUser() {
        TestDataFactoryWrapper.EmailCommWrapper emailCommWrapper = TestDataFactory.createEmailCommSendRequestDTO(true);
        EmailCommSendRequestDTO emailCommSendRequestDTO = emailCommWrapper.dto;
        emailCommSendRequestDTO.senderType = null;

        Test.startTest();
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testSendWithInvalidSenderTypeFails() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO(true).dto;
        emailCommSendRequestDTO.senderType = 'AlienType';

        Test.startTest();
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals('Failed', result.status);
        System.assert(result.errorMessage.contains('Invalid senderType'), 'Expected senderType validation error');
    }

    @IsTest
    static void testSendWithOrgWideSenderWithoutIdFails() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO(true).dto;
        emailCommSendRequestDTO.senderType = 'OrgWide';
        emailCommSendRequestDTO.orgWideEmailAddressId = null;

        Test.startTest();
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals('Failed', result.status);
        System.assert(result.errorMessage.contains('Org-Wide Email Address ID'), 'Expected OrgWide validation error');
    }

    @IsTest
    static void testSendWithAttachmentIds() {
        // Simulate attachment creation
        Attachment attachment = new Attachment(Name = 'TestFile.txt', Body = Blob.valueOf('Hello'), ContentType = 'text/plain');
        insert attachment;

        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO(true).dto;
        emailCommSendRequestDTO.attachmentIds = new List<Id>{ attachment.Id };

        Test.startTest();
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testSendEmailCatchesExceptionAndReturnsGracefulFailure() {
        // Inject invalid recipient to force failure
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO(true).dto;
        emailCommSendRequestDTO.toAddress = 'bad_email_address';

        Test.startTest();
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals('Exception', result.status);
        System.assertNotEquals(null, result.errorMessage, 'Should capture exception message');
    }

    @IsTest
    static void testSendWithTemplate() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO(true).dto;
        emailCommSendRequestDTO.emailTemplateId = [SELECT Id FROM EmailTemplate WHERE IsActive = true LIMIT 1].Id;

        Test.startTest();
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testTestOverrideSuccess() {
        EmailCommSendResultDTO mockResult = new EmailCommSendResultDTO('Success', 'mockEmailMessageId', null);
        Test.startTest();
        EmailCommSenderService.testResultOverride = mockResult;
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(TestDataFactory.createEmailCommSendRequestDTO(true).dto);
        Test.stopTest();

        System.assertEquals('Success', result.status);
        System.assertEquals('mockEmailMessageId', result.emailMessageId);
    }
}