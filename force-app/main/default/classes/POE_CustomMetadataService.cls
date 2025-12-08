public without sharing class POE_CustomMetadataService {
    public static String generateEncryptionKey() {
        Blob key = Crypto.generateAesKey(256);
        String base64Key = EncodingUtil.base64Encode(key);
        return base64Key;
    }

    public Boolean updateAndDeployMetadata(
        String metadataName,
        String metadataLabel,
        String customMetadataTypeName,
        String metadataKeyField
    ) {
        Boolean success;
        try {
            if (
                metadataName == null ||
                metadataLabel == null ||
                customMetadataTypeName == null ||
                metadataKeyField == null
            ) {
                throw new IllegalArgumentException('Arguments cannot be null');
            }

            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = customMetadataTypeName + '.' + metadataName;
            customMetadata.label = metadataLabel;

            Metadata.CustomMetadataValue newKey = new Metadata.CustomMetadataValue();
            newKey.field = metadataKeyField;
            newKey.value = generateEncryptionKey();
            customMetadata.values.add(newKey);

            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadata);

            POE_MetadataDeployCallback callback = new POE_MetadataDeployCallback();

            Id deployRequestId;
            if (!Test.isRunningTest()) {
                deployRequestId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
                if (deployRequestId == null) {
                    throw new HandledException('Metadata Deployment failed');
                } else {
                    success = true;
                    return success;
                }
            } else {
                success = true;
                return success;
            }
        } catch (Exception e) {
            ErrorLogWrapper errorLogWrapper = new ErrorLogWrapper();
            errorLogWrapper.type = 'Internal Error';
            errorLogWrapper.component = 'POE_CustomMetadataService';
            errorLogWrapper.error = JSON.serialize(e);
            ErrorLogModel.logError(errorLogWrapper);
            success = false;
            return success;
        }
    }
}