@isTest
public class PV_CreateStmGroupMembersHandlerTest {
    @testSetup
    static void setupTestData() {

        Group testGroup = new Group(
            Name = 'Test Group',
            Type = 'Regular' 
        );
        insert testGroup;

        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < 3; i++) {
            testUsers.add(new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Alias = 'tuser' + i,
                Email = 'testuser' + i + '@example.com',
                Username = 'testuser' + i + '@hikkoTest.com',
                CommunityNickname = 'testuser' + i,
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert testUsers;

        List<GroupMember> groupMembers = new List<GroupMember>();
        for (User user : testUsers) {
            groupMembers.add(new GroupMember(
                GroupId = testGroup.Id,
                UserOrGroupId = user.Id
            ));
        }
        insert groupMembers;
    }

    @isTest
    static void testCreateGroupMembers() {
        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Group' LIMIT 1];

        List<User> newUsers = new List<User>();
        for (Integer i = 0; i < 2; i++) {
            newUsers.add(new User(
                FirstName = 'New',
                LastName = 'User' + i,
                Alias = 'nuser' + i,
                Email = 'newuser' + i + '@example.com',
                Username = 'newuser' + i + '@example.PV_CreateStmGroupMembersHandlerTest',
                CommunityNickname = 'newuser' + i,
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert newUsers;

        List<GroupMember> newGroupMembers = new List<GroupMember>();
        for (User user : newUsers) {
            newGroupMembers.add(new GroupMember(
                GroupId = testGroup.Id,
                UserOrGroupId = user.Id
            ));
        }

        Test.startTest();
        PV_CreateStmGroupMembersHandler.createGroupMembers(newGroupMembers);
        Test.stopTest();

        List<GroupMember> createdGroupMembers = [SELECT Id, UserOrGroupId FROM GroupMember WHERE GroupId = :testGroup.Id];
        System.assertEquals(5, createdGroupMembers.size(), 'Expected 5 GroupMembers in total');
    }

    @isTest
    static void testDeleteGroupMembers() {
        List<GroupMember> existingGroupMembers = [SELECT Id FROM GroupMember WHERE Group.Name = 'Test Group'];
        System.assert(existingGroupMembers.size() > 0, 'Expected GroupMembers from test setup');

        Test.startTest();
        PV_CreateStmGroupMembersHandler.deleteGroupMembers(existingGroupMembers);
        Test.stopTest();

        Integer remainingGroupMembers = [SELECT COUNT() FROM GroupMember WHERE Group.Name = 'Test Group'];
        System.assertEquals(0, remainingGroupMembers, 'Expected all GroupMembers to be deleted');
    }
}