@isTest
public class POEinsertPCICheckoutTest {
    @isTest
    private static void updateOppTest() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        test.startTest();
        POEinsertPCICheckout os = new POEinsertPCICheckout();
        Boolean result = os.invokeMethod('updateCheckout', inputMap, outputMap, options);
        test.stopTest();
        System.assertEquals(false, result, 'Method not invoked');
    }
}