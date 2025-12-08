@isTest
public class POEGetSSNAgreementTest {
    @isTest
    private static void getOppSuccessTest() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Account testAcc = new Account(Name = 'Account Test');
        insert testAcc;
        Opportunity opp = new Opportunity(
            Name = 'TEST1',
            CloseDate = System.today(),
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp;
        options.put('recordId', opp.Id);
        test.startTest();
        POEGetSSNAgreement os = new POEGetSSNAgreement();
        Boolean result = os.invokeMethod('getOpportunity', inputMap, outputMap, options);
        test.stopTest();
        System.assertEquals(true, result, 'Method not invoked');
    }

    @isTest
    private static void getOppFailTest() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        test.startTest();
        POEGetSSNAgreement os = new POEGetSSNAgreement();
        Boolean result = os.invokeMethod('getOpportunity', inputMap, outputMap, options);
        test.stopTest();
        System.assertEquals(false, result, 'Method not invoked');
    }

    @isTest
    private static void testDifferentMethodName() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        test.startTest();
        POEGetSSNAgreement os = new POEGetSSNAgreement();
        Boolean result = os.invokeMethod('getOpportunityTest', inputMap, outputMap, options);
        test.stopTest();
        System.assertEquals(false, result, 'testDifferentMethodName');
    }
}