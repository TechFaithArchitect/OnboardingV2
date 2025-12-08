@isTest
private class RemoveOpportunitySensitiveDataBatchTest {
    @isTest
    static void testBatchExecution() {
        List<Opportunity> testOpps = new List<Opportunity>();

        for (Integer i = 0; i < 5; i++) {
            testOpps.add(
                new Opportunity(
                    Name = 'Sensitive Opp ' + i,
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(30),
                    POE_Credit_Card__c = '1234567890123456',
                    POE_Sensitive_Data__c = 'Secret info'
                )
            );
        }

        // Also include a non-sensitive record to verify it's skipped
        testOpps.add(
            new Opportunity(Name = 'Non-sensitive Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(30))
        );

        insert testOpps;

        Test.startTest();
        Database.executeBatch(new RemoveOpportunitySensitiveDataBatch(), 200);
        Test.stopTest();

        List<Opportunity> updatedOpps = [
            SELECT POE_Credit_Card__c, POE_Sensitive_Data__c
            FROM Opportunity
            WHERE StageName = 'Prospecting'
        ];

        for (Opportunity o : updatedOpps) {
            System.assertEquals(null, o.POE_Credit_Card__c, 'Credit card should be cleared');
            System.assertEquals(null, o.POE_Sensitive_Data__c, 'Sensitive data should be cleared');
        }

        // Ensure non-sensitive record is untouched
        Opportunity untouched = [
            SELECT POE_Credit_Card__c, POE_Sensitive_Data__c
            FROM Opportunity
            WHERE StageName = 'Prospecting'
            LIMIT 1
        ];

        System.assertEquals(null, untouched.POE_Credit_Card__c);
        System.assertEquals(null, untouched.POE_Sensitive_Data__c);
    }

    @isTest
    static void testSchedulable() {
        Test.startTest();
        String cronExp = '0 0 3 * * ?'; // Daily at 3 AM
        System.schedule('Test Chuzo Scheduler', cronExp, new RemoveOpportunitySensitiveDataBatch());
        Test.stopTest();
    }
}