@isTest
public without sharing class POEUserDeactivationControllerTest {
    @TestSetup
    static void makeData() {
        UserLicense license = [SELECT Id FROM UserLicense WHERE Name Like '%Partner%'];
        Profile profile = [SELECT Id FROM Profile WHERE UserLicenseId = :license.Id LIMIT 1];
        UserRole role = [SELECT Id FROM UserRole WHERE Name LIKE '%Partner%' LIMIT 1];
        Contact portalContact;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account portalAccount = new Account(name = 'portalAccount');
            insert portalAccount;
            portalContact = new contact(LastName = 'portalContact', AccountId = portalAccount.Id);
            insert portalContact;
        }
                    
        User testUser = new User();
        testUser.FirstName = 'POEUserDeactivationControllerTest';
        testUser.LastName = 'TestUser';
        testUser.Email = 'randomtestuser@devtest.' + String.valueOf(Datetime.now().getTime()) + '.com';
        testUser.UserName = 'randomtestuser@devtest.' + String.valueOf(Datetime.now().getTime()) + '.com';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.Alias = 'testuser';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.ProfileId = profile.Id;
        testUser.TimeZoneSidKey = 'America/Los_Angeles';
        testUser.IsActive = true;
        testUser.ContactId = portalContact.Id;
        insert testUser;
    }

    @isTest
    private static void deactivateUserTest() {
        List<User> user = [SELECT Id, ContactId FROM User WHERE LastName = 'TestUser' AND FirstName = 'POEUserDeactivationControllerTest' LIMIT 1];

        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Boolean result;
        inputMap.put('userId', user[0].Id);
        inputMap.put('deactivationReason', 'testing method');

        Test.startTest();
        POEUserDeactivationController prev = new POEUserDeactivationController();
        result = prev.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        Assert.areEqual(true, result, 'Method not correctly invocated');
    }

    @isTest
    private static void deactivateRepresentativeTest() {
        List<User> user = [SELECT Id, ContactId FROM User WHERE LastName = 'TestUser' AND FirstName = 'POEUserDeactivationControllerTest' LIMIT 1];

        Map<String, Object> data = new Map<String, Object>();
        data.put('userId', user[0].Id);
        data.put('deactivationReason', 'testing method');

        Test.startTest();
        POEUserDeactivationController.deactivateRepresentative(data);
        Test.stopTest();

        User result = [SELECT Id, IsActive FROM User WHERE LastName = 'TestUser' AND FirstName = 'POEUserDeactivationControllerTest' LIMIT 1];

        Assert.areEqual(false, result.IsActive, 'the user should be deactivated');
    }

    @isTest
    private static void deactivateRepresentativeWithFSLTest() {
        List<User> user = [SELECT Id, ContactId FROM User WHERE LastName = 'TestUser' AND FirstName = 'POEUserDeactivationControllerTest' LIMIT 1];
        List<Contact> contact = [SELECT Id, FSL_Member__c FROM Contact WHERE Id = :user[0].ContactId];
        contact[0].FSL_Member__c = true;
        update contact;

        Map<String, Object> data = new Map<String, Object>();
        data.put('userId', user[0].Id);
        data.put('deactivationReason', 'testing method');

        Test.startTest();
        POEUserDeactivationController.deactivateRepresentative(data);
        Test.stopTest();

        User result = [SELECT Id, IsActive FROM User WHERE LastName = 'TestUser' AND FirstName = 'POEUserDeactivationControllerTest' LIMIT 1];

        Assert.areEqual(true, result.IsActive, 'the user should not be deactivated');
    }

    @isTest
    private static void deactivateRepresentativeContactTest() {
        List<User> user = [SELECT Id, ContactId FROM User WHERE LastName = 'TestUser' AND FirstName = 'POEUserDeactivationControllerTest' LIMIT 1];

        Map<String, Object> data = new Map<String, Object>();
        data.put('userId', user[0].Id);
        data.put('deactivationReason', 'testing method');

        Test.startTest();
        POEUserDeactivationController.deactivateRepresentativeContact(data);
        Test.stopTest();

        Contact con = [SELECT Id, POE_Deactivation_Reason__c FROM Contact WHERE Id = :user[0].ContactId];
        Assert.areEqual('testing method', con.POE_Deactivation_Reason__c, 'the deactivation reason was not updated correctly');
    }

    @isTest
    private static void testInvokeMethodException() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Boolean result;

        Test.startTest();
        POEUserDeactivationController prev = new POEUserDeactivationController();
        result = prev.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        Assert.AreEqual(false, result, 'testInvokeMethodException');
    }
}