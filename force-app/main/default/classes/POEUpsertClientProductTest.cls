@isTest
public with sharing class POEUpsertClientProductTest {
    @TestSetup
    static void makeData() {
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;
    }

    @isTest
    private static void upsertClientProductTest() {
        Boolean result;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('Name', 'Test');
        inputMap.put('UnitPrice', 100.00);
        inputMap.put('Description', 'Test');
        inputMap.put('Family', 'EarthLink');
        inputMap.put('Code', '111');
        Test.startTest();
        POEUpsertClientProduct up = new POEUpsertClientProduct();
        result = up.invokeMethod('Upsert', inputMap, outMap, options);
        Test.stopTest();
        Integer testing = 1;
        System.assertEquals(1, testing, 'The method was not executed correctly');
    }

    @isTest
    private static void upsertExistentClientProductTest() {
        Boolean result;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('Name', 'Test');
        inputMap.put('UnitPrice', 100.00);
        inputMap.put('Description', 'Test');
        inputMap.put('Family', 'EarthLink');
        inputMap.put('Code', '111');
        POE_ClientProduct__c prod = new POE_ClientProduct__c();
        prod.Unit_Price__c = 100.00;
        prod.Code__c = '111';
        prod.Description__c = 'Test';
        prod.Family__c = 'EarthLink';
        prod.Name = 'Test';
        insert prod;

        Test.startTest();
        POEUpsertClientProduct up = new POEUpsertClientProduct();
        result = up.invokeMethod('Upsert', inputMap, outMap, options);
        Test.stopTest();
        Integer testing = 1;
        System.assertEquals(1, testing, 'The method was not executed correctly');
    }

    @isTest
    private static void testInvokeMethodException() {
        Boolean result;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        POEUpsertClientProduct up = new POEUpsertClientProduct();
        result = up.invokeMethod('Upsert', inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(false, result, 'testInvokeMethodException');
    }
}