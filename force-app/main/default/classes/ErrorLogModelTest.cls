@isTest
public class ErrorLogModelTest {
    static final String TEST_TYPE = 'API Error';
    static final String TEST_PROVIDER = 'DIRECTV';
    static final String TEST_PROVIDER_SUBTYPE = 'Beam';
    static final String TEST_TAB = 'Credit Check';
    static final String TEST_COMPONENT = 'API Error';
    static final String TEST_ERROR = 'Test Error Message';
    static final String TEST_ENDPOINT = 'creditCheck';
    static final String TEST_REQUEST = '{"partnerName": "directv"}';

    @TestSetup
    static void makeData() {
        Opportunity testOpportunity = new Opportunity(
            Name = 'test opportunity',
            StageName = 'Draft',
            CloseDate = Date.today()
        );
        insert testOpportunity;
    }

    @isTest
    static void logErrorTestPositive() {
        List<Error_Log__c> initialErrorLogs = [SELECT Id FROM Error_Log__c];
        Assert.isTrue(initialErrorLogs.isEmpty(), 'No Error_Log__c records should exist at beggining of the test');

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        ErrorLogWrapper errorLogWrapper = new ErrorLogWrapper();
        errorLogWrapper.type = TEST_TYPE;
        errorLogWrapper.provider = TEST_PROVIDER;
        errorLogWrapper.providerSubtype = TEST_PROVIDER_SUBTYPE;
        errorLogWrapper.tab = TEST_TAB;
        errorLogWrapper.component = TEST_COMPONENT;
        errorLogWrapper.error = TEST_ERROR;
        errorLogWrapper.endpoint = TEST_ENDPOINT;
        errorLogWrapper.request = TEST_REQUEST;
        errorLogWrapper.opportunity = opp.Id;

        Test.startTest();
        ErrorLogModel.logError(errorLogWrapper);
        Test.stopTest();

        List<Error_Log__c> resultErrorLogs = [
            SELECT
                Id,
                Name,
                Type__c,
                Provider__c,
                Provider_Subtype__c,
                Tab__c,
                Component__c,
                Error__c,
                Endpoint__c,
                Request__c,
                Opportunity__c
            FROM Error_Log__c
        ];

        Assert.areEqual(1, resultErrorLogs.size(), 'An Error_Log__c record should have been created');
        Error_Log__c resultErrorLog = resultErrorLogs.get(0);

        Assert.areEqual(
            TEST_TYPE,
            resultErrorLog.Type__c,
            'Error_Log__c.Type__c field should match value passed in ErrorLogWrapper.type attribute'
        );
        Assert.areEqual(
            TEST_PROVIDER,
            resultErrorLog.Provider__c,
            'Error_Log__c.Provider__c field should match value passed in ErrorLogWrapper.provider attribute'
        );
        Assert.areEqual(
            TEST_PROVIDER_SUBTYPE,
            resultErrorLog.Provider_Subtype__c,
            'Error_Log__c.Provider_Subtype__c field should match value passed in ErrorLogWrapper.providerSubtype attribute'
        );
        Assert.areEqual(
            TEST_TAB,
            resultErrorLog.Tab__c,
            'Error_Log__c.Tab__c field should match value passed in ErrorLogWrapper.tab attribute'
        );
        Assert.areEqual(
            TEST_COMPONENT,
            resultErrorLog.Component__c,
            'Error_Log__c.Component__c field should match value passed in ErrorLogWrapper.component attribute'
        );
        Assert.areEqual(
            TEST_ERROR,
            resultErrorLog.Error__c,
            'Error_Log__c.Error__c field should match value passed in ErrorLogWrapper.error attribute'
        );
        Assert.areEqual(
            TEST_ENDPOINT,
            resultErrorLog.Endpoint__c,
            'Error_Log__c.Endpoint__c field should match value passed in ErrorLogWrapper.endpoint attribute'
        );
        Assert.areEqual(
            errorLogWrapper.request,
            resultErrorLog.Request__c,
            'Error_Log__c.Request__c field should match value passed in ErrorLogWrapper.request attribute'
        );
        Assert.areEqual(
            opp.Id,
            resultErrorLog.Opportunity__c,
            'Error_Log__c.Opportunity__c field should match value passed in ErrorLogWrapper.opportunity attribute'
        );
    }

    @isTest
    static void logErrorTestNegative() {
        List<Error_Log__c> initialErrorLogs = [SELECT Id FROM Error_Log__c];
        Assert.isTrue(initialErrorLogs.isEmpty(), 'No Error_Log__c records should exist at beggining of the test');

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        ErrorLogWrapper errorLogWrapper = new ErrorLogWrapper();
        errorLogWrapper.provider = TEST_PROVIDER;
        errorLogWrapper.tab = TEST_TAB;

        Test.startTest();
        try {
            ErrorLogModel.logPublicError(errorLogWrapper);
        } catch (Exception exc) {
            System.debug(exc.getMessage());
        }
        Test.stopTest();

        List<Error_Log__c> resultErrorLogs = [
            SELECT
                Id,
                Name,
                Type__c,
                Provider__c,
                Tab__c,
                Component__c,
                Error__c,
                Endpoint__c,
                Request__c,
                Opportunity__c
            FROM Error_Log__c
        ];

        Assert.isTrue(resultErrorLogs.isEmpty(), 'No Error_Log__c records should be created');
    }

    @isTest
    static void logPublicErrorTest() {
        List<Error_Log__c> initialErrorLogs = [SELECT Id FROM Error_Log__c];
        Assert.isTrue(initialErrorLogs.isEmpty(), 'No Error_Log__c records should exist at beggining of the test');

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        ErrorLogWrapper errorLog = new ErrorLogWrapper();
        errorLog.type = TEST_TYPE;
        errorLog.provider = TEST_PROVIDER;
        errorLog.providerSubtype = TEST_PROVIDER_SUBTYPE;
        errorLog.tab = TEST_TAB;
        errorLog.component = TEST_COMPONENT;
        errorLog.error = TEST_ERROR;
        errorLog.endpoint = TEST_ENDPOINT;
        errorLog.request = TEST_REQUEST;
        errorLog.opportunity = POE_PublicRecordAccessUtility.encryptRecordId(opp.Id);

        Test.startTest();
        ErrorLogModel.logPublicError(errorLog);
        Test.stopTest();

        List<Error_Log__c> resultErrorLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Opportunity__c = :opp.Id
        ];
        Assert.areEqual(1, resultErrorLogs.size(), 'No error log was created with the decrypted Opportunity Id.');
    }
}