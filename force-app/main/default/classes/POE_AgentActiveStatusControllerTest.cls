@isTest
public with sharing class POE_AgentActiveStatusControllerTest {
    @TestSetup
    static void makeData() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            Id p = TestHelper.getGeneralProfile().Id;

            Account ac = new Account(name = 'Test Acc');
            insert ac;

            Contact con = new Contact(LastName = 'testCon', AccountId = ac.Id);
            insert con;

            Contact conNoUser = new Contact(LastName = 'testConNoUser', AccountId = ac.Id);
            insert conNoUser;

            User user = new User(
                alias = 'test123',
                email = 'test123@noemail.com',
                emailencodingkey = 'UTF-8',
                lastname = 'Testing',
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                profileid = p,
                country = 'United States',
                IsActive = true,
                ContactId = con.Id,
                timezonesidkey = 'America/Los_Angeles',
                username = 'tester@noemail15112022.com'
            );
            insert user;

            PermissionSet ps = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = :POE_PermissionsUtility.RESIDENTIAL_PS_NAME
                LIMIT 1
            ];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = ps.Id);
            insert psa;
        }
    }

    @isTest
    private static void testGetChuzoAgentStatus() {
        Id contactId = [SELECT Id FROM Contact WHERE Name = 'testCon'].Id;
        Test.startTest();
        POE_AgentActiveStatusController.ResponseWrapper response = POE_AgentActiveStatusController.getAgentStatus(
            contactId
        );
        Test.stopTest();
        Assert.isTrue((Boolean) response.result.get('chuzo'), 'User Retrieved successfully');
    }
}