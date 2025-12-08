@isTest
public with sharing class POE_GeoCodeStoresTest {
    @isTest
    private static void createStoreTest() {
        Test.startTest();
        POE_Retail_Store__c st = new POE_Retail_Store__c();
        st.Name = 'Test';
        st.POE_City__c = 'San Francisco';
        st.POE_State__c = 'California';
        st.POE_Street_Address__c = '417 Mission Street';
        st.POE_Zip_Code__c = '94105';
        insert st;
        Test.stopTest();
        POE_Retail_Store__c updatedSt = [SELECT Id, Location__Latitude__s, Location__Longitude__s FROM POE_Retail_Store__c LIMIT 1];
        POE_GeoCodeStores.geoCodeRecord('InvalidAddress', 'InvalidRecordId');
        System.assertEquals(37.7897784, updatedSt.Location__Latitude__s, 'Method not correclty invocated');
        System.assertEquals(-122.3973206, updatedSt.Location__Longitude__s, 'Method not correclty invocated');
    }
}