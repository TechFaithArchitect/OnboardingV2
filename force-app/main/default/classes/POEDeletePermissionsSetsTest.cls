@isTest
public class POEDeletePermissionsSetsTest {
    @TestSetup
    static void makeData() {
        UserLicense license = [SELECT Id FROM UserLicense WHERE Name = 'Salesforce'];
        Profile profile = [SELECT Id FROM Profile WHERE UserLicenseId = :license.Id LIMIT 1];

        System.runAs(new User(Id = UserInfo.getUserId())) {
            User testUser = new User();
            testUser.FirstName = 'Test';
            testUser.LastName = 'User';
            testUser.Email = 'randomtestuser@devtest.' + String.valueOf(Datetime.now().getTime()) + '.com';
            testUser.UserName = 'randomtestuser@devtest.' + String.valueOf(Datetime.now().getTime()) + '.com';
            testUser.EmailEncodingKey = 'UTF-8';
            testUser.Alias = 'testuser';
            testUser.LanguageLocaleKey = 'en_US';
            testUser.LocaleSidKey = 'en_US';
            testUser.ProfileId = profile.Id;
            testUser.TimeZoneSidKey = 'America/Los_Angeles';
            testUser.IsActive = true;
            insert testUser;
        }
    }
    @isTest
    private static void deletePermissionSets() {
        List<User> users = [SELECT Id FROM User WHERE Alias = 'testuser' LIMIT 1];
        List<String> userId = new List<String>();
        for (User u : users) {
            userId.add(u.Id);
        }
        Test.startTest();
        POEDeletePermissionsSets.deletePermissions(userId);
        Test.stopTest();

        List<PermissionSetAssignment> perms = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE
                AssigneeId IN :userId
                AND PermissionSet.IsOwnedByProfile = FALSE
                AND PermissionSetGroup.DeveloperName != 'Owner_Permission_Set_Group'
                AND PermissionSetGroup.DeveloperName != 'Owner_Permissions_No_Maps'
        ];

        System.assertEquals(0, perms.size(), 'Permissions were not deleted');
    }

    @isTest
    static void testDeletePermissionsException() {
        POEDeletePermissionsSets.throwException = true;
        List<String> ids = new List<String>{};

        Test.startTest();
        try {
            POEDeletePermissionsSets.deletePermissions(ids);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }
}