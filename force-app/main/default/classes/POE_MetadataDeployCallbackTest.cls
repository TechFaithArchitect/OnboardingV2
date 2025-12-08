@isTest
private class POE_MetadataDeployCallbackTest {
    @isTest
    static void testSuccessfulDeployment() {
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        POE_MetadataDeployCallback callback = new POE_MetadataDeployCallback();
        callback.handleResult(result, context);
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size(), 'No errors should be logged for a successful deployment');
    }

    @isTest
    static void testFailedDeployment() {
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Failed;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        POE_MetadataDeployCallback callback = new POE_MetadataDeployCallback();
        callback.handleResult(result, context);
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'An error should be logged for a failed deployment');
    }
}