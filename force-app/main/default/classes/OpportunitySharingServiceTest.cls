@isTest
public class OpportunitySharingServiceTest {
    @isTest
    static void testShareOpportunityWithGroup() {
        // Create test data
        // Insert a test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert opp;

        // Insert a test group (like a Public Group or Queue)
        Group testGroup = new Group(Name = 'Test Group', Type = 'Regular');
        insert testGroup;

        // Prepare input for the service method
        OpportunitySharingService.ShareInput input = new OpportunitySharingService.ShareInput();
        input.recordId = opp.Id;
        input.groupId = testGroup.Id;
        input.accessLevel = 'Read'; // Set access level to 'Read' for testing

        List<OpportunitySharingService.ShareInput> inputList = new List<OpportunitySharingService.ShareInput>{ input };

        // Call the method to test
        Test.startTest();
        OpportunitySharingService.shareOpportunityWithGroup(inputList);
        Test.stopTest();

        // Verify results
        List<OpportunityShare> shares = [
            SELECT Id, OpportunityId, UserOrGroupId, OpportunityAccessLevel
            FROM OpportunityShare
            WHERE OpportunityId = :opp.Id AND UserOrGroupId = :testGroup.Id
        ];

        // Assert that a share record was created with the correct access level
        System.assertEquals(1, shares.size(), 'One OpportunityShare record should be created.');
        System.assertEquals('Read', shares[0].OpportunityAccessLevel, 'OpportunityAccessLevel should be Read');
        System.assertEquals(opp.Id, shares[0].OpportunityId, 'OpportunityId should match the test Opportunity');
        System.assertEquals(testGroup.Id, shares[0].UserOrGroupId, 'UserOrGroupId should match the test Group');
    }
}