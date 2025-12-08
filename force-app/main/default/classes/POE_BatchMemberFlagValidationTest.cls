@isTest
private class POE_BatchMemberFlagValidationTest {
    @testSetup
    static void setupTestData() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Id p = TestHelper.getGeneralProfile().Id;
            Id dealerRT = [SELECT Id FROM RecordType WHERE Name = 'Dealer' LIMIT 1][0].Id;

            Account ac = new Account(name = 'Test Acc', recordTypeId = dealerRT);
            insert ac;

            Contact chuzoContact = new Contact(LastName = 'Chuzo', AccountId = ac.Id);
            insert chuzoContact;

            User chuzoUser = new User(
                alias = 'test123',
                email = 'test123@noemail.com',
                emailencodingkey = 'UTF-8',
                lastname = 'Testing',
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                profileid = p,
                country = 'United States',
                IsActive = true,
                ContactId = chuzoContact.Id,
                timezonesidkey = 'America/Los_Angeles',
                username = 'User' + Math.random() * 100 + '@test.com'
            );
            insert chuzoUser;

            PermissionSet ps = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = :POE_PermissionsUtility.CHUZO_PARTNER_NAME
                LIMIT 1
            ];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = chuzoUser.Id,
                PermissionSetId = ps.Id
            );
            insert psa;
        }
    }

    @isTest
    static void testBatchExecution() {
        Contact cont = [SELECT Id, Chuzo_Member__c FROM Contact LIMIT 1];
        cont.Chuzo_Member__c = false;
        update cont;
        Test.startTest();
        POE_BatchMemberFlagValidation batchJob = new POE_BatchMemberFlagValidation();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();
        List<Contact> updatedContacts = [SELECT Id FROM Contact WHERE Chuzo_Member__c = TRUE];
        System.assertEquals(false, updatedContacts.isEmpty(), 'Flag was not updated');
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        String jobId = System.schedule('Test Batch Job', '0 0 0 1 * ?', new POE_BatchMemberFlagValidation());
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Scheduled job should have a valid job ID');
    }
}