@isTest
private class EmailCommLogRepositoryTest {

    @isTest
    static void testInsertLog() {
        // Arrange
        TestDataFactoryWrapper.EmailCommWrapper wrapper = TestDataFactory.createEmailCommSendWrapper(1, false);
        Email_Communication_Log__c log = wrapper.log;

        // Act
        Test.startTest();
        Email_Communication_Log__c inserted = EmailCommLogRepository.insertLog(log);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, inserted.Id, 'Inserted log should have an Id');
    }

    @isTest
    static void testGetMatchingLogs() {
        // Arrange
        TestDataFactoryWrapper.EmailCommWrapper wrapper = TestDataFactory.createEmailCommSendWrapper(1, true);
        EmailCommSendRequestDTO dto = wrapper.dto;

        // Act
        Test.startTest();
        List<Email_Communication_Log__c> logs = EmailCommLogRepository.getMatchingLogs(
            dto.contactId,
            dto.communicationTemplateId,
            dto.onboardingId
        );
        Test.stopTest();

        // Assert
        System.assertEquals(1, logs.size(), 'Should find one matching log');
        System.assertEquals(wrapper.log.Id, logs[0].Id, 'Should match the expected log');
    }

    @isTest
    static void testGetMatchingLogsNoneFound() {
        // Arrange
        TestDataFactoryWrapper.EmailCommWrapper wrapper = TestDataFactory.createEmailCommSendWrapper(1, true);
        // Create a valid but non-existent ID by modifying a character in the middle (keeping prefix intact)
        String originalId = wrapper.dto.communicationTemplateId.toString();
        // Modify the 10th character (index 9) to create a different but valid ID
        String charAt9 = originalId.substring(9, 10);
        String replacement = (charAt9 == '0' ? '1' : '0');
        String fakeIdString = originalId.substring(0, 9) + replacement + originalId.substring(10);
        Id fakeTemplateId = Id.valueOf(fakeIdString);

        // Act
        Test.startTest();
        List<Email_Communication_Log__c> logs = EmailCommLogRepository.getMatchingLogs(
            wrapper.dto.contactId,
            fakeTemplateId, // intentionally wrong
            wrapper.dto.onboardingId
        );
        Test.stopTest();

        // Assert
        System.assertEquals(0, logs.size(), 'Should not find any matching logs with wrong template');
    }
}