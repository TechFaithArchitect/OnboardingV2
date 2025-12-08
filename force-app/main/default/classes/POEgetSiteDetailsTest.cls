@isTest
public class POEgetSiteDetailsTest {
    @isTest
    private static void callMethod() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        test.startTest();
        POEgetSiteDetails os = new POEgetSiteDetails();
        Object result = os.invokeMethod('method', inputMap, outputMap, options);
        test.stopTest();
        System.assertEquals(true, outputMap.containsKey('result'), 'Method not invoked');
    }
}