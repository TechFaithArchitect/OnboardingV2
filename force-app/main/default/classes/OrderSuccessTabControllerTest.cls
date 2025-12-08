@isTest
private class OrderSuccessTabControllerTest {
    @TestSetup
    static void makeData() {
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Presentation'
        );
        insert testOpp;
        Opportunity nullOpp = new Opportunity(
            Name = 'Null Opportunity',
            CloseDate = Date.today(),
            StageName = 'Presentation'
        );
        insert nullOpp;

        ContentVersion version = new ContentVersion(
            Title = 'poe_signature',
            PathOnClient = 'test.jpg',
            VersionData = EncodingUtil.base64Decode('AA=='),
            Origin = 'H'
        );
        insert version;

        ContentVersion v2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

        ContentDocumentLink docLink = new ContentDocumentLink(
            LinkedEntityId = testOpp.Id,
            ContentDocumentId = v2.ContentDocumentId
        );

        insert docLink;
    }

    @isTest
    static void test_getSignatureFile() {
        List<Opportunity> opps = [SELECT Id,Name FROM Opportunity];
        Opportunity opp = opps[0];
        test.startTest();
        OrderSuccessTabController.ResponseWrapper response = OrderSuccessTabController.getSignatureFile(
            new Map<String, Object>{ 'ContextId' => opp.Id }
        );
        test.stopTest();

        String docId = (String) response.result.get('Id');

        System.assert(docId != null, 'Response should not be null');
    }
}