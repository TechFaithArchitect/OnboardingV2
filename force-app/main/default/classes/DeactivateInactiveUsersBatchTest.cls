@isTest
private class DeactivateInactiveUsersBatchTest {

    @isTest static void testBatchExecution() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Id profileId = TestHelper.getGeneralProfile().Id;

            Account acct = new Account(Name = 'Batch Test Account');
            insert acct;

            Contact contact = new Contact(
                LastName = 'InactiveUserContact',
                AccountId = acct.Id,
                Chuzo_Member__c = true,
                FSL_Member__c = false
            );
            insert contact;

            User testUser = new User(
                Alias = 'tuser',
                Email = 'batchuser@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'BatchTest',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profileId,
                Country = 'United States',
                IsActive = true,
                ContactId = contact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'batchuser' + Math.random() + '@example.com',
                LearnUponP__LU_Field_1__c = DateTime.now().addDays(-120)
            );
            insert testUser;

            Test.startTest();
                Database.executeBatch(new DeactivateInactiveUsersBatch(), 1);
            Test.stopTest();

            User updatedUser = [SELECT IsActive FROM User WHERE Id = :testUser.Id];
            System.assertEquals(false, updatedUser.IsActive, 'User should have been deactivated.');
        }
    }

    @isTest static void testSchedulableExecution() {
        Test.startTest();
            DeactivateInactiveUsersBatch batch = new DeactivateInactiveUsersBatch();
            String jobId = System.schedule('Test Deactivation Job', '0 0 1 * * ?', batch);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job should return a valid job ID.');
    }
}