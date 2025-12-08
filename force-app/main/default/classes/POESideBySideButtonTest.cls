@isTest
public with sharing class POESideBySideButtonTest {
    @TestSetup
    static void makeData() {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'poe_img_sidebyside_' + System.now() + '.png';
        cv.PathOnClient = 'Signature-' + System.now() + '.png';
        cv.ContentLocation = 'S';
        cv.Origin = 'H';
        cv.VersionData = EncodingUtil.base64Decode('Test');
        insert cv;
    }

    @isTest
    private static void saveFileTest() {
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        Account acc = new Account(Name = 'test account');
        insert acc;
        Opportunity opp = new Opportunity(Name='Test Opp', AccountId = acc.Id, CloseDate = System.Today(),
        Maps_PostalCode__c = '72212', StageName='Opportunity');
        insert opp;

        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();
        String mockContent = 'Unit Test Attachment Body';
        inputMap.put('recId', opp.Id);
        inputMap.put('strSignElement', mockContent);
        inputMap.put('updBoolean', false);
        inputMap.put('cvId', cv.Id);

        Test.startTest();
        POESideBySideButton sbs = new POESideBySideButton();
        Boolean result = sbs.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(result, true , 'Insert failed');
    }

    @isTest
    private static void updateFileTest() {
        Account acc = new Account(Name = 'test account');
        insert acc;
        Opportunity opp = new Opportunity(Name='Test Opp', AccountId = acc.Id, CloseDate = System.Today(),
        Maps_PostalCode__c = '72212', StageName='Opportunity');
        insert opp;
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();
        String signature = 'signature';
        String mockContent = 'Unit Test Attachment Body';
        inputMap.put('recId', opp.Id);
        inputMap.put('strSignElement', mockContent);
        inputMap.put('updBoolean', true);
        inputMap.put('type', signature);

        Test.startTest();
        POESideBySideButton sbs = new POESideBySideButton();
        Boolean result = sbs.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals(result, true , 'Insert failed');
    }

    public class Input {
        public String recId;
        public String strSignElement;
        public Boolean updBoolean;
    }
}