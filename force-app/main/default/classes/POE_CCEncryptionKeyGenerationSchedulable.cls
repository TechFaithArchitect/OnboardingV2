global class POE_CCEncryptionKeyGenerationSchedulable implements Schedulable {
    public void execute(SchedulableContext SC) {
        String metadataName = 'CC_Encryption_Key';
        String metadataLabel = 'CC Encryption Key';
        String customMetadataTypeName = 'Chuzo_Creditcard_Encryption_Key__mdt';
        String metadataKeyField = 'key__c';

        POE_CustomMetadataService deployService = new POE_CustomMetadataService();

        Boolean updateMetadata = deployService.updateAndDeployMetadata(
            metadataName,
            metadataLabel,
            customMetadataTypeName,
            metadataKeyField
        );
    }
}