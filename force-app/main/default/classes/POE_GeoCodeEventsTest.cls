@isTest
public with sharing class POE_GeoCodeEventsTest {
    @isTest
    private static void createEventTest() {
        Test.startTest();
        POE_Event__c ev = new POE_Event__c();
        ev.Name = 'Test';
        ev.POE_City__c = 'San Francisco';
        ev.POE_State__c = 'California';
        ev.POE_Street_Address__c = '417 Mission Street';
        ev.POE_Zip_Code__c = '94105';
        insert ev;
        Test.stopTest();
        POE_Event__c updatedEv = [SELECT Id, Location__Latitude__s, Location__Longitude__s FROM POE_Event__c LIMIT 1];
        POE_GeoCodeEvents.geoCodeRecord('InvalidAddress', 'InvalidRecordId');
        System.assertEquals(37.7897784, updatedEv.Location__Latitude__s, 'Method not correclty invocated');
        System.assertEquals(-122.3973206, updatedEv.Location__Longitude__s, 'Method not correclty invocated');
    }
}