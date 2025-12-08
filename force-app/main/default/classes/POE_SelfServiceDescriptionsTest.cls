@isTest
public without sharing class POE_SelfServiceDescriptionsTest {
    @isTest
    public static void getMetadataTest() {
        Test.startTest();
        List<Self_Service_Program_Description__mdt> metadatas = POE_SelfServiceDescriptionsController.getProgramDescriptionsMetadata();
        Assert.isNotNull(metadatas, 'List should not be null');
        Test.stopTest();
    }
}