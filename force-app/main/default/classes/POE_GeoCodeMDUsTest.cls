@isTest
public with sharing class POE_GeoCodeMDUsTest {
    @isTest
    private static void createMDUTest() {
        Test.startTest();
        MDU_Chuzo__c mdu = new MDU_Chuzo__c();
        mdu.Name = 'Test MDU';
        mdu.City__c = 'San Francisco';
        mdu.State__c = 'California';
        mdu.Street_Address__c = '417 Mission Street';
        mdu.Zip_Code__c = '94105';
        insert mdu;
        Test.stopTest();
        MDU_Chuzo__c updatedMDU = [SELECT Id, Location__Latitude__s, Location__Longitude__s FROM MDU_Chuzo__c LIMIT 1];
        POE_GeoCodeMDUs.geoCodeRecord('InvalidAddress', 'InvalidRecordId');
        System.assertEquals(37.7897784, updatedMDU.Location__Latitude__s, 'Method not correctly invoked');
        System.assertEquals(-122.3973206, updatedMDU.Location__Longitude__s, 'Method not correctly invoked');
    }
}