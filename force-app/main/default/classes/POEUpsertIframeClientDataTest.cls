@isTest
public with sharing class POEUpsertIframeClientDataTest {
    @TestSetup
    static void makeData() {
        Id consRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Person Account')
            .getRecordTypeId();

        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Account';
        acc.RecordTypeId = consRecordTypeId;
        acc.BillingStreet = 'Test Address';
        acc.BillingCity = 'Test city';
        acc.BillingStateCode = 'NY';
        acc.BillingPostalCode = '72212';
        acc.ShippingStreet = 'Test Address';
        acc.ShippingCity = 'Test city';
        acc.ShippingStateCode = 'NY';
        acc.ShippingPostalCode = '72212';
        acc.Phone = '1231235234';
        insert acc;

        Referral_Code__c testCode = new Referral_Code__c(
            Referral_code__c = 'TestCode',
            Logo_URL__c = 'test',
            Body__c = 'test',
            Primary_Brand_Color__c = '123456',
            Secondary_Brand_Color__c = '123456',
            Subtitle__c = 'test',
            Title__c = 'test'
        );
        insert testCode;
        testCode = [SELECT Id, Name FROM Referral_Code__c WHERE Id = :testCode.Id];

        Opportunity opp = new Opportunity();
        opp.CloseDate = System.today();
        opp.StageName = 'Opportunity';
        opp.Maps_PostalCode__c = '72212';
        opp.accountId = acc.Id;
        opp.Name = 'Test';
        opp.Referral_Code__c = testCode.Id;
        insert opp;

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;
    }

    @IsTest
    private static void updateAccountTest() {
        Boolean result;
        String methodName = 'upsertClient';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String firstName = 'Test';
        String lastName = 'Account';
        String street = 'Test Address';
        String city = 'Test city';
        String state = 'NY';
        String zipCode = '72212';
        String phone = '1231235234';
        String mobile = '1231235234';
        String email = 'test@test.com';
        String origin = 'callcenter';
        String program = 'Charter/Spectrum';
        String isCallOrder = 'true';
        Boolean consent = true;
        inputMap.put('recordId', opp.Id);
        inputMap.put('firstName', firstName);
        inputMap.put('lastName', lastName);
        inputMap.put('street', street);
        inputMap.put('city', city);
        inputMap.put('state', state);
        inputMap.put('zipCode', zipCode);
        inputMap.put('phone', phone);
        inputMap.put('mobile', mobile);
        inputMap.put('email', email);
        inputMap.put('origin', origin);
        inputMap.put('program', program);
        inputMap.put('isCallOrder', isCallOrder);
        inputMap.put('consent', consent);
        Test.startTest();
        POEUpsertIframeClientData ups = new POEUpsertIframeClientData();
        result = ups.invokeMethod('upsertClient', inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(true, result, 'The method was not executed correctly');
    }

    @IsTest
    private static void insertAccountTest() {
        Boolean result;
        String methodName = 'upsertClient';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String firstName = 'NonExisting';
        String lastName = 'Account';
        String street = 'Test Address';
        String city = 'Test city';
        String state = 'NY';
        String zipCode = '72212';
        String phone = '1231235234';
        String mobile = '1231235234';
        String email = 'test@test.com';
        String origin = 'event';
        String program = 'Charter/Spectrum';
        String isCallOrder = 'true';
        Boolean consent = true;
        inputMap.put('recordId', opp.Id);
        inputMap.put('firstName', firstName);
        inputMap.put('lastName', lastName);
        inputMap.put('street', street);
        inputMap.put('city', city);
        inputMap.put('state', state);
        inputMap.put('zipCode', zipCode);
        inputMap.put('phone', phone);
        inputMap.put('mobile', mobile);
        inputMap.put('email', email);
        inputMap.put('origin', origin);
        inputMap.put('program', program);
        inputMap.put('isCallOrder', isCallOrder);
        inputMap.put('consent', consent);
        Test.startTest();
        POEUpsertIframeClientData ups = new POEUpsertIframeClientData();
        result = ups.invokeMethod('upsertClient', inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(true, result, 'The method was not executed correctly');
    }

    @IsTest
    private static void insertOrderTest() {
        Boolean result;
        String methodName = 'upsertClient';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String firstName = 'Test';
        String lastName = 'Account';
        String street = 'Test Address';
        String city = 'Test city';
        String state = 'NY';
        String zipCode = '72212';
        String phone = '1231235234';
        String mobile = '1231235234';
        String email = 'test@test.com';
        String origin = 'retail';
        String program = 'Charter/Spectrum';
        Boolean consent = true;
        String isCallOrder = 'true';
        inputMap.put('recordId', opp.Id);
        inputMap.put('firstName', firstName);
        inputMap.put('lastName', lastName);
        inputMap.put('street', street);
        inputMap.put('city', city);
        inputMap.put('state', state);
        inputMap.put('zipCode', zipCode);
        inputMap.put('phone', phone);
        inputMap.put('mobile', mobile);
        inputMap.put('email', email);
        inputMap.put('origin', origin);
        inputMap.put('program', program);
        inputMap.put('isCallOrder', isCallOrder);
        inputMap.put('consent', consent);
        Test.startTest();
        POEUpsertIframeClientData ups = new POEUpsertIframeClientData();
        result = ups.invokeMethod('upsertClient', inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(true, result, 'The method was not executed correctly');
    }

    @IsTest
    private static void updateOrderTest() {
        Boolean result;
        String methodName = 'upsertClient';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order ord = new Order();
        ord.Status = 'Draft';
        ord.EffectiveDate = System.Today();
        ord.OpportunityId = opp.Id;
        ord.AccountId = acc.Id;
        insert ord;
        String firstName = 'Test';
        String lastName = 'Account';
        String street = 'Test Address';
        String addressLine2 = 'Test Address 2';
        String city = 'Test city';
        String state = 'NY';
        String zipCode = '72212';
        Boolean consent = true;
        String mobile = '1231235234';
        String email = 'test@test.com';
        String origin = 'phonesales';
        String program = 'Other';
        String isCallOrder = 'true';
        inputMap.put('recordId', opp.Id);
        inputMap.put('firstName', firstName);
        inputMap.put('lastName', lastName);
        inputMap.put('street', street);
        inputMap.put('city', city);
        inputMap.put('state', state);
        inputMap.put('zipCode', zipCode);
        inputMap.put('mobile', mobile);
        inputMap.put('email', email);
        inputMap.put('origin', origin);
        inputMap.put('program', program);
        inputMap.put('isCallOrder', isCallOrder);
        inputMap.put('addressLine2', addressLine2);
        inputMap.put('consent', consent);

        Test.startTest();
        POEUpsertIframeClientData ups = new POEUpsertIframeClientData();
        result = ups.invokeMethod('upsertClient', inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(true, result, 'The method was not executed correctly');
    }

    @IsTest
    private static void testDifferentMethodName() {
        Boolean result;
        String methodName = 'upsertClientTest';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        POEUpsertIframeClientData ups = new POEUpsertIframeClientData();
        result = ups.invokeMethod(methodName, inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(false, result, 'testDifferentMethodName');
    }
}