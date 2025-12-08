@isTest
public class POEinsertPCICreditCheckTest {
    private static final String TEST_STATUS = Opportunity.StageName.getDescribe().getPicklistValues()[0].getValue();

    @TestSetup
    static void makeData() {
        Account testAcc = new Account(
            Name = 'Test',
            ShippingStreet = 'Test Street',
            POE_Dealer_Office_Email__c = 'poeinsertpcicreditchecktest@perfectvision.com'
        );
        insert testAcc;

        Opportunity opp1 = new Opportunity(
            Name = 'TEST1',
            CloseDate = System.today(),
            AccountId = testAcc.Id,
            StageName = TEST_STATUS,
            Maps_PostalCode__c = '72212'
        );
        insert opp1;
    }

    @isTest
    private static void testInvokeMethod() {
        Opportunity opp = [SELECT Id FROM Opportunity lIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        options.put('birthdate', Date.today());
        options.put('dlExpirationDate', Date.today());
        options.put('oppId', opp.Id);

        test.startTest();
        POEinsertPCICreditCheck os = new POEinsertPCICreditCheck();
        Boolean result = os.invokeMethod('updateCreditCheckSSN', inputMap, outputMap, options);
        Boolean result2 = os.invokeMethod('updateCreditCheckDL', inputMap, outputMap, options);
        test.stopTest();

        System.assertEquals(true, result, 'testInvokeMethod');
        System.assertEquals(true, result2, 'testInvokeMethod2');
    }

    @isTest
    private static void testInvokeMethodException() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        POEinsertPCICreditCheck os = new POEinsertPCICreditCheck();
        Boolean result = os.invokeMethod('updateCreditCheckSSN', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(false, result, 'testInvokeMethodException');
    }
}