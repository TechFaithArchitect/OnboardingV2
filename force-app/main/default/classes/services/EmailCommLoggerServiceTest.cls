@isTest
private class EmailCommLoggerServiceTest {

    @isTest
    static void testLogImmediately_Success() {
        // Arrange
        EmailCommSendRequestDTO request = TestDataFactory.createEmailCommSendRequestDTO();
        request.toAddress = 'test@example.com';
        request.subject = 'Test Email';
        request.htmlBody = '<p>Test</p>';
        request.textBody = 'Test';
        
        // Act
        Test.startTest();
        EmailCommLoggerService.logImmediately(request);
        Test.stopTest();
        
        // Assert
        List<Email_Communication_Log__c> logs = [
            SELECT Id, To_Address__c, Subject__c 
            FROM Email_Communication_Log__c 
            WHERE To_Address__c = 'test@example.com'
        ];
        System.assertEquals(1, logs.size(), 'Should create one log record');
        System.assertEquals('Test Email', logs[0].Subject__c, 'Subject should match');
    }

    @isTest
    static void testLogImmediately_Duplicate_Skips() {
        // Arrange
        EmailCommSendRequestDTO request = TestDataFactory.createEmailCommSendRequestDTO();
        request.toAddress = 'test@example.com';
        request.subject = 'Test Email';
        
        // Create an existing log to make it a duplicate
        Email_Communication_Log__c existingLog = TestEmailCommLogFactory.create(request, true, 0);
        
        // Act
        Test.startTest();
        EmailCommLoggerService.logImmediately(request);
        Test.stopTest();
        
        // Assert - Should still have only one log (duplicate was skipped)
        List<Email_Communication_Log__c> logs = [
            SELECT Id 
            FROM Email_Communication_Log__c 
            WHERE To_Address__c = 'test@example.com'
        ];
        System.assertEquals(1, logs.size(), 'Should not create duplicate log');
    }

    @isTest
    static void testLogImmediately_WithOnboarding() {
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
        EmailCommLoggerService.logImmediately(request);
        Test.stopTest();
        
        // Assert
        List<Email_Communication_Log__c> logs = [
            SELECT Id, Onboarding__c, Contact__c, Account__c 
            FROM Email_Communication_Log__c 
            WHERE Onboarding__c = :onboarding.Id
        ];
        System.assertEquals(1, logs.size(), 'Should create log with onboarding reference');
        System.assertEquals(onboarding.Id, logs[0].Onboarding__c, 'Onboarding should be set');
        System.assertEquals(contact.Id, logs[0].Contact__c, 'Contact should be set');
        System.assertEquals(account.Id, logs[0].Account__c, 'Account should be set');
    }

    @isTest
    static void testLogImmediately_WithTemplate() {
        // Arrange
        Communication_Template__c template = TestCommTemplateFactory.createTemplate(true);
        
        EmailCommSendRequestDTO request = TestDataFactory.createEmailCommSendRequestDTO();
        request.communicationTemplateId = template.Id;
        request.toAddress = 'test@example.com';
        request.subject = 'Template Email';
        
        // Act
        Test.startTest();
        EmailCommLoggerService.logImmediately(request);
        Test.stopTest();
        
        // Assert
        List<Email_Communication_Log__c> logs = [
            SELECT Id, Communication_Template__c 
            FROM Email_Communication_Log__c 
            WHERE Communication_Template__c = :template.Id
        ];
        System.assertEquals(1, logs.size(), 'Should create log with template reference');
        System.assertEquals(template.Id, logs[0].Communication_Template__c, 'Template should be set');
    }
}
