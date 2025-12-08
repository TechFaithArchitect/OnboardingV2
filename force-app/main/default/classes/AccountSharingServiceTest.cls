@isTest
public class AccountSharingServiceTest {

    @isTest
    static void testShareAccountWithGroup() {
        // Create test data
        // Insert a test Account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        // Insert a test group (like a Public Group or Queue)
        Group testGroup = new Group(
            Name = 'Test Group',
            Type = 'Regular'
        );
        insert testGroup;
        
        // Prepare input for the service method
        AccountSharingService.ShareInput input = new AccountSharingService.ShareInput();
        input.recordId = acc.Id;
        input.groupId = testGroup.Id;
        input.accessLevel = 'Read'; // Set access level to 'Read' for testing
        
        List<AccountSharingService.ShareInput> inputList = new List<AccountSharingService.ShareInput>{input};
        
        // Call the method to test
        Test.startTest();
        AccountSharingService.shareAccountWithGroup(inputList);
        Test.stopTest();
        
        // Verify results
        List<AccountShare> shares = [SELECT Id, AccountId, UserOrGroupId, AccountAccessLevel 
                                     FROM AccountShare 
                                     WHERE AccountId = :acc.Id 
                                     AND UserOrGroupId = :testGroup.Id];
                                     
        // Assert that a share record was created with the correct access level
        System.assertEquals(1, shares.size(), 'One AccountShare record should be created.');
        System.assertEquals('Read', shares[0].AccountAccessLevel, 'AccountAccessLevel should be Read');
        System.assertEquals(acc.Id, shares[0].AccountId, 'AccountId should match the test Account');
        System.assertEquals(testGroup.Id, shares[0].UserOrGroupId, 'UserOrGroupId should match the test Group');
    }
}