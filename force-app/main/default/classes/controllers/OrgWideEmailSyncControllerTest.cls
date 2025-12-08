@isTest
private class OrgWideEmailSyncControllerTest {

    @isTest
    static void testScheduledExecution() {
        // Arrange
        OrgWideEmailDTO orgWideEmailDTO = TestOrgWideEmailDTOFactory.create('Program Support');
        OrgWideEmailSyncService.setMockDtos(new List<OrgWideEmailDTO>{ orgWideEmailDTO });

        // Act
        Test.startTest();
        new OrgWideEmailSyncController().execute(null);
        Test.stopTest();

        // Assert
        List<Sync_Log__c> syncLogs = [SELECT Id FROM Sync_Log__c];
        System.assert(!syncLogs.isEmpty(), 'Expected log record after scheduled run');
    }
}