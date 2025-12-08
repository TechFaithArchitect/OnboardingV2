@isTest
private class CloseInactiveOpportunitiesBatchTest {
    @testSetup
    static void setupTestData() {
        RecordType rt = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'Standard_Opportunity' 
            AND SObjectType = 'Opportunity'
            LIMIT 1
        ];

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                Name = 'Old Opp 1',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                RecordTypeId = rt.Id,
                First_Attempted_Date__c = Date.today().addDays(-70)
            ),
            new Opportunity(
                Name = 'Recent Opp 2',
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                RecordTypeId = rt.Id,
                First_Attempted_Date__c = Date.today().addDays(-10)
            ),
            new Opportunity(
                Name = 'Closed Opp 3',
                StageName = 'Closed Lost',
                CloseDate = Date.today().addDays(30),
                RecordTypeId = rt.Id,
                If_closed_lost_why__c = 'Test closed lost reason',
                First_Attempted_Date__c = Date.today().addDays(-80)
            )
        };

        insert opps;
        
        List<Opportunity> insertedOpps = [
            SELECT Id, Name, StageName, First_Attempted_Date__c, RecordTypeId
            FROM Opportunity
            WHERE Name IN ('Old Opp 1', 'Recent Opp 2', 'Closed Opp 3')
        ];
    }

    @isTest
    static void testScheduler() {
        Test.startTest();
        String cron = '0 0 0 * * ?'; 
        System.schedule('Test Scheduled Close', cron, new CloseInactiveOpportunitiesBatch());
        Test.stopTest();
    }
}