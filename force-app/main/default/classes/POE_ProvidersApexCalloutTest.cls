@isTest
public with sharing class POE_ProvidersApexCalloutTest {
    @isTest
    private static void poeCalloutTest() {
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> bodyMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'callEndpoint';
        bodyMap.put('partnerName', 'enga');
        bodyMap.put('dealerCorpId', '2000085241');
        bodyMap.put('dealerId', '7123091');
        bodyMap.put('dealerAgentId', '90023847');
        bodyMap.put('dealerLocation', 'DMDR4');
        mapInput.put('body', bodyMap);
        mapInput.put('path', 'salesFlow');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new POE_ProvidersApexHttpCalloutMock());
        POE_ProvidersApexCallout call = new POE_ProvidersApexCallout();
        Boolean result = call.invokeMethod(methodName, mapInput, outMap, options);
        Test.stopTest();
        System.assertEquals(true, result, 'Callout failed');
    }

    @isTest
    private static void poeCalloutTestNonVlocity() {
        Map<String, String> mapInput = new Map<String, String>();
        String methodName = 'callEndpoint';
        mapInput.put('partnerName', 'enga');
        mapInput.put('dealerCorpId', '2000085241');
        mapInput.put('dealerId', '7123091');
        mapInput.put('dealerAgentId', '90023847');
        mapInput.put('dealerLocation', 'DMDR4');
        mapInput.put('path', 'salesFlow');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new POE_ProvidersApexHttpCalloutMock());
        String result = POE_ProvidersApexCallout.callEndpoint(mapInput);
        Test.stopTest();
        System.assert(result != null, 'Callout failed');
    }

    @isTest
    private static void poeCalloutFailedTest() {
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> bodyMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'inexistantMethod';
        bodyMap.put('partnerName', 'enga');
        bodyMap.put('dealerCorpId', '2000085241');
        bodyMap.put('dealerId', '7123091');
        bodyMap.put('dealerAgentId', '90023847');
        bodyMap.put('dealerLocation', 'DMDR4');
        mapInput.put('body', bodyMap);
        mapInput.put('path', 'salesFlow');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new POE_ProvidersApexHttpCalloutMock());
        POE_ProvidersApexCallout call = new POE_ProvidersApexCallout();
        Boolean result = call.invokeMethod(methodName, mapInput, outMap, options);
        Test.stopTest();
        System.assertEquals(false, result, 'Callout failed');
    }

    @isTest
    static void testInvokeMethodException() {
        Map<String, Object> inputMap = new Map<String, Object>{};
        Map<String, Object> outMap = new Map<String, Object>{};
        Map<String, Object> options = new Map<String, Object>{};

        Test.startTest();
        POE_ProvidersApexCallout providers = new POE_ProvidersApexCallout();
        providers.throwException = true;
        Boolean response = providers.invokeMethod('', inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(false, response, 'testInvokeMethodException');
    }
}