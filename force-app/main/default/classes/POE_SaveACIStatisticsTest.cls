@isTest
public with sharing class POE_SaveACIStatisticsTest {
    @TestSetup
    static void makeData() {
        POE_Retail_Store__c store = new POE_Retail_Store__c();
        store.Name = 'Test Store';
        store.Location__latitude__s = 34.000;
        store.Location__longitude__s = 50.000;
        store.POE_City__c = 'San Francisco';
        store.POE_State__c = 'California';
        store.POE_Street_Address__c = 'Test Street';
        store.POE_Zip_Code__c = '94105';
        insert store;

        POE_Clicker_Retail_Track__c track = new POE_Clicker_Retail_Track__c();
        track.POE_Store__c = store.Id;
        insert track;

        POE_Event__c event = new POE_Event__c();
        event.Name = 'Test Store';
        event.Location__latitude__s = 34.000;
        event.Location__longitude__s = 50.000;
        event.POE_City__c = 'San Francisco';
        event.POE_State__c = 'California';
        event.POE_Street_Address__c = 'Test Street';
        event.POE_Zip_Code__c = '94105';
        insert event;

        POE_Clicker_Event_Track__c track2 = new POE_Clicker_Event_Track__c();
        track2.POE_Event__c = event.Id;
        insert track2;

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.CloseDate = System.today();
        opp.Name = 'Test Opportunity';
        opp.Maps_Latitude__c = 50.11;
        opp.Maps_Longitude__c = 30.33;
        opp.AccountId = acc.Id;
        opp.StageName = 'Opportunity';
        opp.Maps_PostalCode__c = '72212';
        insert opp;
    }

    @isTest
    private static void testInitialSave() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Order> ord = new List<Order>();
        Test.startTest();
        POE_SaveACIStatistics.initialSave(opp.Id, 34.000, 50.000);
        ord = POE_SaveACIStatistics.getData(opp.Id);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveWithPreviousACI() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        POE_ACI_Statistic__c ac = new POE_ACI_Statistic__c();
        ac.Opportunity__c = opp.Id;
        insert ac;
        Test.startTest();
        POE_SaveACIStatistics.initialSave(opp.Id, 34.000, 50.000);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Presentation__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveVlocityRetailInsert() {
        Boolean result;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContextId', opp.Id);
        inputMap.put('latitude', 33.50);
        inputMap.put('longitude', 50.2313);
        inputMap.put('origin', 'retail');
        Test.startTest();
        POE_SaveACIVlocity vl = new POE_SaveACIVlocity();
        result = vl.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveVlocityEventInsert() {
        Boolean result;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContextId', opp.Id);
        inputMap.put('latitude', 33.50);
        inputMap.put('longitude', 50.2313);
        inputMap.put('origin', 'event');
        Test.startTest();
        POE_SaveACIVlocity vl = new POE_SaveACIVlocity();
        result = vl.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveVlocityMapInsert() {
        Boolean result;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContextId', opp.Id);
        inputMap.put('latitude', 33.50);
        inputMap.put('longitude', 50.2313);
        inputMap.put('origin', 'maps');
        Test.startTest();
        POE_SaveACIVlocity vl = new POE_SaveACIVlocity();
        result = vl.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveVlocityPhoneSalesInsert() {
        Boolean result;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContextId', opp.Id);
        inputMap.put('latitude', 33.50);
        inputMap.put('longitude', 50.2313);
        inputMap.put('origin', 'phonesales');
        Test.startTest();
        POE_SaveACIVlocity vl = new POE_SaveACIVlocity();
        result = vl.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveVlocityRetailUpdate() {
        Boolean result;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        POE_ACI_Statistic__c st = new POE_ACI_Statistic__c();
        st.Point_of_Disposition__latitude__s = 50;
        st.Point_of_Disposition__longitude__s = 30;
        st.Opportunity__c = opp.Id;
        insert st;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContextId', opp.Id);
        inputMap.put('latitude', 33.50);
        inputMap.put('longitude', 50.2313);
        inputMap.put('origin', 'retail');
        Test.startTest();
        POE_SaveACIVlocity vl = new POE_SaveACIVlocity();
        result = vl.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveVlocityEventUpdate() {
        Boolean result;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        POE_ACI_Statistic__c st = new POE_ACI_Statistic__c();
        st.Point_of_Disposition__latitude__s = 50;
        st.Point_of_Disposition__longitude__s = 30;
        st.Opportunity__c = opp.Id;
        insert st;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContextId', opp.Id);
        inputMap.put('latitude', 33.50);
        inputMap.put('longitude', 50.2313);
        inputMap.put('origin', 'event');
        Test.startTest();
        POE_SaveACIVlocity vl = new POE_SaveACIVlocity();
        result = vl.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveVlocityMapUpdate() {
        Boolean result;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        POE_ACI_Statistic__c st = new POE_ACI_Statistic__c();
        st.Point_of_Disposition__latitude__s = 50;
        st.Point_of_Disposition__longitude__s = 30;
        st.Opportunity__c = opp.Id;
        insert st;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContextId', opp.Id);
        inputMap.put('latitude', 33.50);
        inputMap.put('longitude', 50.2313);
        inputMap.put('origin', 'maps');
        Test.startTest();
        POE_SaveACIVlocity vl = new POE_SaveACIVlocity();
        result = vl.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveVlocityPhoneSalesUpdate() {
        Boolean result;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        POE_ACI_Statistic__c st = new POE_ACI_Statistic__c();
        st.Point_of_Disposition__latitude__s = 50;
        st.Point_of_Disposition__longitude__s = 30;
        st.Opportunity__c = opp.Id;
        insert st;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContextId', opp.Id);
        inputMap.put('latitude', 33.50);
        inputMap.put('longitude', 50.2313);
        inputMap.put('origin', 'phonesales');
        Test.startTest();
        POE_SaveACIVlocity vl = new POE_SaveACIVlocity();
        result = vl.invokeMethod('Test', inputMap, outMap, options);
        Test.stopTest();
        List<POE_ACI_Statistic__c> aci = [
            SELECT Id, Order_Created__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, aci.size(), 'ACI not inserted');
    }

    @isTest
    private static void testInitialSaveException() {
        Test.startTest();
        try {
            POE_SaveACIStatistics.initialSave('InvalidId', 34.000, 50.000);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }
}