@isTest
public with sharing class POE_UpdateUserCommunityMembershipTest {
    @TestSetup
    static void makeData() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Id p = TestHelper.getGeneralProfile().Id;
            Id fsProfile = [SELECT Id FROM Profile WHERE Name = '#FS Dispatcher (Partner Community)'].id;

            Account ac = new Account(name = 'Test Acc');
            insert ac;

            Contact chuzoContact = new Contact(LastName = 'Chuzo', AccountId = ac.Id);
            insert chuzoContact;

            Contact fsContact = new Contact(LastName = 'FS', AccountId = ac.Id);
            insert fsContact;

            Contact conNoUser = new Contact(LastName = 'testConNoUser', AccountId = ac.Id);
            insert conNoUser;

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
    private static void testBatchJob() {
        Test.startTest();
        POE_UpdateUserCommunityMembershipBatch batchInstance = new POE_UpdateUserCommunityMembershipBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();
        Contact fsContact = [SELECT Id, Chuzo_Member__c, FSL_Member__c FROM Contact WHERE LastName = 'FS' LIMIT 1];
        System.assertEquals(true, fsContact.FSL_Member__c, 'FSL Member value should be true');
        System.assertEquals(false, fsContact.Chuzo_Member__c, 'Chuzo Member value should be true');
    }
}