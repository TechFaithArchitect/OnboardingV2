@isTest
private class POE_ChuzoNotificationControllerTest {
    @TestSetup
    static void makeData() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'External Partner – General'].Id;

        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        User adminUser = [
            SELECT Id, UserRoleId
            FROM User
            WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
            LIMIT 1
        ];
        adminUser.UserRoleId = role.Id;
        update adminUser;

        System.runAs(adminUser) {
            Account account = new Account();
            account.Name = 'TEST';
            insert account;
            Contact contact = new Contact();
            contact.AccountId = account.Id;
            contact.FirstName = 'Test';
            contact.LastName = 'One';
            contact.Email = 'test@test.com.invalid';
            contact.POE_Programs_Available__c = 'Frontier;Spectrum API';
            contact.POE_Event_Programs__c = 'EarthLink';
            contact.POE_Retail_Programs__c = 'Frontier';
            contact.D2D_Programs__c = 'EarthLink';
            insert contact;
            User user = new User();
            user.ContactId = contact.Id;
            user.ProfileId = profileId;
            user.FirstName = 'TestName1';
            user.LastName = 'LastName';
            user.Username = 'testPOE_ChuzoNotificationControllerTest' + DateTime.now().getTime() + '@gmail.com.invalid';
            user.Email = 'POE_ChuzoNotificationControllerTest@gmail.com.invalid';
            user.EmailEncodingKey = 'UTF-8';
            user.LocaleSidKey = 'en_US';
            user.LanguageLocaleKey = 'en_US';
            user.TimeZoneSidKey = 'America/Los_Angeles';
            user.Alias = 'userone';
            user.PortalRole = null;
            insert user;
        }
    }

    @isTest
    static void testGetActiveNotification() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        User portalUser = [SELECT Id FROM User WHERE ContactId = :contact.Id];
        Test.startTest();
        System.runAs(portalUser) {
            List<String> notifications = POE_ChuzoNotificationController.getActiveNotification();
            Assert.areEqual(1, notifications.size(), 'Only one notification should have been retrieved.');
            Assert.areEqual('Test', notifications[0], 'Wrong notification message retrieved.');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetActiveNotificationNegativeTest() {
        Contact contact = [
            SELECT Id, POE_Programs_Available__c, POE_Retail_Programs__c, POE_Event_Programs__c, D2D_Programs__c
            FROM Contact
            LIMIT 1
        ];

        contact.POE_Programs_Available__c = '';
        contact.POE_Retail_Programs__c = '';
        contact.POE_Event_Programs__c = '';
        contact.D2D_Programs__c = '';
        update contact;

        User portalUser = [SELECT Id FROM User WHERE ContactId = :contact.Id];

        Test.startTest();
        System.runAs(portalUser) {
            List<String> notifications = POE_ChuzoNotificationController.getActiveNotification();

            Assert.areEqual(0, notifications.size(), 'No notifications should have been retrieved.');
        }
        Test.stopTest();
    }
}