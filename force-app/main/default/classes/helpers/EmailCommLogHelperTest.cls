@isTest
private class EmailCommLogHelperTest {

    @isTest
    static void testBuildLogFromRequest_Basic() {
        // Arrange
        EmailCommSendRequestDTO request = TestDataFactory.createEmailCommSendRequestDTO();
        request.toAddress = 'test@example.com';
        request.subject = 'Test Subject';
        request.htmlBody = '<p>Test HTML</p>';
        request.textBody = 'Test Text';
        
        // Act
        Test.startTest();
        Email_Communication_Log__c log = EmailCommLogHelper.buildLogFromRequest(request);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, log, 'Log should not be null');
        System.assertEquals('test@example.com', log.To_Address__c, 'To address should match');
        System.assertEquals('Test Subject', log.Subject__c, 'Subject should match');
        System.assertEquals('<p>Test HTML</p>', log.HTML_Body__c, 'HTML body should match');
        System.assertEquals('Test Text', log.Text_Body__c, 'Text body should match');
        System.assertEquals('Flow', log.Sent_Via__c, 'Sent via should be Flow');
        System.assertEquals('Sent', log.Status__c, 'Status should be Sent');
        System.assertNotEquals(null, log.Sent_At__c, 'Sent at should be set');
        System.assertEquals(UserInfo.getUserId(), log.Sent_By__c, 'Sent by should be current user');
    }

    @isTest
    static void testBuildLogFromRequest_WithOnboarding() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Account account = TestAccountFactory.create('Test Account', true);
        Contact contact = TestContactFactory.create('Test', 'Contact', account, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(account, vendorProgram, true);
        
        EmailCommSendRequestDTO request = TestDataFactory.createEmailCommSendRequestDTO();
        request.onboardingId = onboarding.Id;
        request.contactId = contact.Id;
        request.accountId = account.Id;
        request.toAddress = 'test@example.com';
        request.subject = 'Onboarding Email';
        
        // Act
        Test.startTest();
        Email_Communication_Log__c log = EmailCommLogHelper.buildLogFromRequest(request);
        Test.stopTest();
        
        // Assert
        System.assertEquals(onboarding.Id, log.Onboarding__c, 'Onboarding should be set');
        System.assertEquals(contact.Id, log.Contact__c, 'Contact should be set');
        System.assertEquals(account.Id, log.Account__c, 'Account should be set');
    }

    @isTest
    static void testBuildLogFromRequest_WithTemplate() {
        // Arrange
        Communication_Template__c template = TestCommTemplateFactory.createTemplate(true);
        
        EmailCommSendRequestDTO request = TestDataFactory.createEmailCommSendRequestDTO();
        request.communicationTemplateId = template.Id;
        request.toAddress = 'test@example.com';
        request.subject = 'Template Email';
        
        // Act
        Test.startTest();
        Email_Communication_Log__c log = EmailCommLogHelper.buildLogFromRequest(request);
        Test.stopTest();
        
        // Assert
        System.assertEquals(template.Id, log.Communication_Template__c, 'Template should be set');
    }

    @isTest
    static void testBuildLogFromRequest_AllFields() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Account account = TestAccountFactory.create('Test Account', true);
        Contact contact = TestContactFactory.create('Test', 'Contact', account, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(account, vendorProgram, true);
        Communication_Template__c template = TestCommTemplateFactory.createTemplate(true);
        
        EmailCommSendRequestDTO request = TestDataFactory.createEmailCommSendRequestDTO();
        request.onboardingId = onboarding.Id;
        request.contactId = contact.Id;
        request.accountId = account.Id;
        request.communicationTemplateId = template.Id;
        request.toAddress = 'test@example.com';
        request.subject = 'Complete Email';
        request.htmlBody = '<p>Complete HTML</p>';
        request.textBody = 'Complete Text';
        
        // Act
        Test.startTest();
        Email_Communication_Log__c log = EmailCommLogHelper.buildLogFromRequest(request);
        Test.stopTest();
        
        // Assert
        System.assertEquals(onboarding.Id, log.Onboarding__c, 'All fields should be set correctly');
        System.assertEquals(contact.Id, log.Contact__c, 'Contact should be set');
        System.assertEquals(account.Id, log.Account__c, 'Account should be set');
        System.assertEquals(template.Id, log.Communication_Template__c, 'Template should be set');
        System.assertEquals('test@example.com', log.To_Address__c, 'To address should be set');
        System.assertEquals('Complete Email', log.Subject__c, 'Subject should be set');
        System.assertEquals('<p>Complete HTML</p>', log.HTML_Body__c, 'HTML body should be set');
        System.assertEquals('Complete Text', log.Text_Body__c, 'Text body should be set');
    }
}