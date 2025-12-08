@isTest
public with sharing class POE_CustomMetadataServiceTest {
    @isTest
    static void testUpdateAndDeployMetadataSuccess() {
        Test.startTest();
        POE_CustomMetadataService deployMetadata = new POE_CustomMetadataService();
        String metadataName = 'CC_Encryption_Key';
        String metadataLabel = 'CC Encryption Key';
        String customMetadataTypeName = 'Chuzo_Creditcard_Encryption_Key__mdt';
        String metadataKeyField = 'key__c';
        Boolean deployMetadataTest = deployMetadata.updateAndDeployMetadata(
            metadataName,
            metadataLabel,
            customMetadataTypeName,
            metadataKeyField
        );
        Test.stopTest();

        System.assert.areEqual(true, deployMetadataTest, 'Successfully updated Metadata');
    }
    @isTest
    static void testUpdateAndDeployMetadataFail() {
        Test.startTest();
        POE_CustomMetadataService deployMetadata = new POE_CustomMetadataService();
        String metadataName;
        String metadataLabel;
        String customMetadataTypeName;
        String metadataKeyField;
        String errorMessage;

        Boolean deployMetadataTest = deployMetadata.updateAndDeployMetadata(
            metadataName,
            metadataLabel,
            customMetadataTypeName,
            metadataKeyField
        );

        Test.stopTest();
        System.assert.isFalse(deployMetadataTest, 'Failed to update Metadata');
    }
}