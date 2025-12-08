public class FSL_ErrorAlertTriggerHelper {
    public static void afterInsert(List<FSL_Error_Alert__e> errorAlerts) {
        List<Error_Log__c> errorLogsToInsert = new List<Error_Log__c>();

        for (FSL_Error_Alert__e errorAlert : errorAlerts) {
            Error_Log__c newErrorLog = new Error_Log__c(
                Type__c = errorAlert.Type__c,
                Provider__c = errorAlert.Provider__c,
                Component__c = errorAlert.Component__c,
                Error__c = errorAlert.Error__c
            );
            errorLogsToInsert.add(newErrorLog);
        }
        
        insert errorLogsToInsert;
    }
}