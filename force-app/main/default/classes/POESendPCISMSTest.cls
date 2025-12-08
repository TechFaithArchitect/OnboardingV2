@isTest
public with sharing class POESendPCISMSTest {
    public static final String VALID_PHONE_NUMBER = '14235123673';

    @testSetup
    static void makeData() {
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Phone = VALID_PHONE_NUMBER
        );
        insert contact;
    }

    @isTest
    private static void poeSendPCISMSTest() {
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        mapInput.put('AccountId', 'ACdc82f57944869cb7cf90dbf66880a029');
        mapInput.put('Body', 'Follow the link to fill your personal info https://poedev-chuzo.cs221.force.com/poe/s/pci-checkout?c__ContextId:undefined');
        mapInput.put('From', '18506045257');
        mapInput.put('Password', '9791a3f12dfe8880c7d0f08ff352dd8b');
        mapInput.put('To', '5491140457664');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new POESMSHttpCalloutMock());
        POESendPCISMS sms = new POESendPCISMS();
        Boolean result = sms.invokeMethod('Method', mapInput, outMap, options);
        Test.stopTest();
        System.assertEquals(result, true , 'poeSendPCISMSTest: Callout failed');
    }

    @isTest
    private static void poeSendPCISMSValidContactTest() {
        Contact contact = [SELECT Id, Phone FROM Contact LIMIT 1];
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        mapInput.put('AccountId', 'ACdc82f57944869cb7cf90dbf66880a029');
        mapInput.put('Body', 'Follow the link to fill your personal info https://poedev-chuzo.cs221.force.com/poe/s/pci-checkout?c__ContextId:undefined');
        mapInput.put('From', '18506045257');
        mapInput.put('Password', '9791a3f12dfe8880c7d0f08ff352dd8b');
        mapInput.put('To', '5491140457664');
        mapInput.put('ContactId', contact.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new POESMSHttpCalloutMock());
        POESendPCISMS sms = new POESendPCISMS();
        Boolean result = sms.invokeMethod('Method', mapInput, outMap, options);
        Test.stopTest();
        
        System.assertEquals(result, true , 'poeSendPCISMSValidContactTest: Callout failed');
    }

    @isTest
    private static void poeSendPCISMSValidPhoneTest() {
        Contact contact = [SELECT Id, Phone FROM Contact LIMIT 1];
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        mapInput.put('AccountId', 'ACdc82f57944869cb7cf90dbf66880a029');
        mapInput.put('Body', 'Follow the link to fill your personal info https://poedev-chuzo.cs221.force.com/poe/s/pci-checkout?c__ContextId:undefined');
        mapInput.put('From', '18506045257');
        mapInput.put('Password', '9791a3f12dfe8880c7d0f08ff352dd8b');
        mapInput.put('To', VALID_PHONE_NUMBER);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new POESMSHttpCalloutMock());
        POESendPCISMS sms = new POESendPCISMS();
        Boolean result = sms.invokeMethod('Method', mapInput, outMap, options);
        Test.stopTest();
        
        System.assertEquals(result, true , 'poeSendPCISMSValidPhoneTest: Callout failed');
    }
}