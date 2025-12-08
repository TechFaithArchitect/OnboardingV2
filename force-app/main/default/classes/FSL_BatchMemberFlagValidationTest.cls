@isTest
private class FSL_BatchMemberFlagValidationTest {
    @testSetup
    static void setupTestData() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Id p = TestHelper.getGeneralProfile().Id;
            Id fsProfile = [SELECT Id FROM Profile WHERE Name = '#FS Dispatcher (Partner Community)'].id;
            Id dealerRT = [SELECT Id FROM RecordType WHERE Name = 'Dealer' LIMIT 1][0].Id;

            Account ac = new Account(name = 'Test Acc', recordTypeId = dealerRT);
            insert ac;

            Contact fsContact = new Contact(LastName = 'FS', AccountId = ac.Id, FSL_Member__c = false);
            insert fsContact;

            User fsUser = new User(
                alias = 'test123',
                email = 'test123@noemail.com',
                emailencodingkey = 'UTF-8',
                lastname = 'Testing',
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                profileid = fsProfile,
                country = 'United States',
                IsActive = true,
                ContactId = fsContact.Id,
                timezonesidkey = 'America/Los_Angeles',
                username = 'User' + Math.random() * 100 + '@test.com'
            );
            insert fsUser;
        }
    }

    @isTest
    static void testBatchExecution() {
        Contact cont = [SELECT Id, FSL_Member__c FROM Contact LIMIT 1];
        cont.FSL_Member__c = false;
        update cont;
        Test.startTest();
        FSL_BatchMemberFlagValidation batchJob = new FSL_BatchMemberFlagValidation();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();
        List<Contact> updatedContacts = [SELECT Id FROM Contact WHERE FSL_Member__c = TRUE];
        System.assertEquals(false, updatedContacts.isEmpty(), 'Flag was not updated');
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        String jobId = System.schedule('Test Batch Job', '0 0 0 1 * ?', new FSL_BatchMemberFlagValidation());
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Scheduled job should have a valid job ID');
    }
}