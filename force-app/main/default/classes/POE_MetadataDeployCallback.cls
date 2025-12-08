public class POE_MetadataDeployCallback implements Metadata.DeployCallback {
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        Id jobId = context.getCallbackJobId();
        if (result.status !== Metadata.DeployStatus.SUCCEEDED) {
            ErrorLogWrapper errorLogWrapper = new ErrorLogWrapper();
            errorLogWrapper.type = 'Internal Error';
            errorLogWrapper.component = 'POE_MetadataDeployCallback';
            errorLogWrapper.error = JSON.serialize(result);
            errorLogWrapper.request = JSON.serialize(context);
            ErrorLogModel.logError(errorLogWrapper);
        }
    }
}