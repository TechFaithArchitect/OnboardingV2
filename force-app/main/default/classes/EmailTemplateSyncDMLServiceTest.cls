@isTest
private class EmailTemplateSyncDMLServiceTest {

    @isTest
    static void testSaveWithRetry_insertSuccess() {
        Communication_Template__c record = new Communication_Template__c(
            Name = 'Test Template Insert',
            DeveloperName__c = 'Test_Dev_Name_1',
            Communication_Type__c = 'Welcome',
            Email_Subject__c = 'Hello',
            Active__c = true
        );

        Test.startTest();
        EmailTemplateSyncDMLService.saveWithRetry(new List<Communication_Template__c>{ record }, true);
        Test.stopTest();

        List<Communication_Template__c> results = [
            SELECT Id, DeveloperName__c FROM Communication_Template__c
            WHERE DeveloperName__c = 'Test_Dev_Name_1'
        ];
        System.assertEquals(1, results.size(), 'Record should be inserted');
    }

    @isTest
    static void testSaveWithRetry_updateSuccess() {
        Communication_Template__c record = new Communication_Template__c(
            Name = 'Test Template Update',
            DeveloperName__c = 'Test_Dev_Name_2',
            Communication_Type__c = 'Welcome',
            Email_Subject__c = 'Original Subject',
            Active__c = true
        );
        insert record;

        // Modify for update
        record.Email_Subject__c = 'Updated Subject';

        Test.startTest();
        EmailTemplateSyncDMLService.saveWithRetry(new List<Communication_Template__c>{ record }, false);
        Test.stopTest();

        Communication_Template__c updated = [
            SELECT Email_Subject__c FROM Communication_Template__c
            WHERE Id = :record.Id
        ];
        System.assertEquals('Updated Subject', updated.Email_Subject__c, 'Subject should be updated');
    }

    @isTest
    static void testSaveWithRetry_handlesEmpty() {
        Test.startTest();
        EmailTemplateSyncDMLService.saveWithRetry(new List<Communication_Template__c>(), true);
        EmailTemplateSyncDMLService.saveWithRetry(null, false);
        Test.stopTest();

        // ✅ Should not throw errors — no assertion needed
    }

    @isTest
    static void testSaveWithRetry_partialFailure_simulated() {
        // ✅ Valid
        Communication_Template__c valid = new Communication_Template__c(
            Name = 'Valid Template',
            DeveloperName__c = 'Valid_Dev_Name',
            Communication_Type__c = 'Welcome',
            Email_Subject__c = 'Hi',
            Active__c = true
        );

        // ❌ Invalid (missing required field)
        Communication_Template__c invalid = new Communication_Template__c(
            DeveloperName__c = null, // Missing DevName
            Communication_Type__c = 'Broken',
            Email_Subject__c = 'Broken'
        );

        List<Communication_Template__c> mixedBatch = new List<Communication_Template__c>{ valid, invalid };

        Test.startTest();
        try {
            EmailTemplateSyncDMLService.saveWithRetry(mixedBatch, true);
        } catch (Exception e) {
            // This may or may not throw depending on MAX_RETRIES
            System.debug('Expected partial failure: ' + e.getMessage());
        }
        Test.stopTest();

        List<Communication_Template__c> inserted = [
            SELECT DeveloperName__c FROM Communication_Template__c
            WHERE DeveloperName__c = 'Valid_Dev_Name'
        ];

        System.assertEquals(1, inserted.size(), 'Only valid record should be inserted');
    }
}