@isTest
private class GetAvailableRecordTypesTest {
    @isTest static void testInvokeWithValidAndInvalidObjects() {
        // Build requests
        GetAvailableRecordTypesRequest good = new GetAvailableRecordTypesRequest();
        good.sObjectApiName = 'Opportunity';
        GetAvailableRecordTypesRequest bad = new GetAvailableRecordTypesRequest();
        bad.sObjectApiName  = 'NoSuch__c';
        
        List<GetAvailableRecordTypesRequest> reqs = 
            new List<GetAvailableRecordTypesRequest>{ good, bad };

        Test.startTest();
        List<List<RecordType>> results = GetAvailableRecordTypes.invoke(reqs);
        Test.stopTest();

        // Two response lists
        System.assertEquals(2, results.size());

        // 1) Opportunity has at least one
        List<RecordType> oppRTs = results[0];
        System.assert(oppRTs.size() > 0, 'Expected record types for Opportunity');

        // 2) Bogus object yields none
        List<RecordType> noRTs = results[1];
        System.assertEquals(0, noRTs.size(), 'Expected no record types for invalid object');
    }
}