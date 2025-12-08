@IsTest
private class EmailMessageBuilderTest {

    @IsTest
    static void testBuild_withTemplate() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO(true).dto;
        emailCommSendRequestDTO.emailTemplateId = [SELECT Id FROM EmailTemplate WHERE IsActive = true LIMIT 1].Id;

        Messaging.SingleEmailMessage emailMessage = EmailMessageBuilder.build(emailCommSendRequestDTO);

        System.assertNotEquals(null, emailMessage.getTemplateId(), 'Expected template to be set');
        System.assertEquals(false, emailMessage.getUseSignature(), 'Should disable signature for templates');
    }

    @IsTest
    static void testBuild_withManualContent() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO(true).dto;
        emailCommSendRequestDTO.emailTemplateId = null;
        emailCommSendRequestDTO.toAddress = 'test@example.com';
        emailCommSendRequestDTO.subject = 'Unit Test';
        emailCommSendRequestDTO.htmlBody = '<p>Hello</p>';
        emailCommSendRequestDTO.textBody = 'Hello';

        Messaging.SingleEmailMessage emailMessage = EmailMessageBuilder.build(emailCommSendRequestDTO);

        System.assertEquals('Unit Test', emailMessage.getSubject());
        System.assert(emailMessage.getToAddresses().contains('test@example.com'), 'Expected to address to be set');
    }

    @IsTest
    static void testBuild_withCCAndBCC() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO(true).dto;
        emailCommSendRequestDTO.toAddress = 'to@example.com';
        emailCommSendRequestDTO.ccAddressList = new List<String>{ 'cc@example.com' };
        emailCommSendRequestDTO.bccAddressList = new List<String>{ 'bcc@example.com' };

        Messaging.SingleEmailMessage emailMessage = EmailMessageBuilder.build(emailCommSendRequestDTO);

        System.assert(emailMessage.getCcAddresses().contains('cc@example.com'), 'Expected CC address');
        System.assert(emailMessage.getBccAddresses().contains('bcc@example.com'), 'Expected BCC address');
    }
}