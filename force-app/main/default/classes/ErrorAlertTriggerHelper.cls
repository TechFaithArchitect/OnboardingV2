public class ErrorAlertTriggerHelper {
    public static void afterInsert(List<Error_Alert__e> errorAlerts) {
        List<PV_Error_Log__c> errorLogsToInsert = new List<PV_Error_Log__c>();
        for (Error_Alert__e errorAlert : errorAlerts) {
            //create ErrorLogs
            PV_Error_Log__c newErrorLog = new PV_Error_Log__c(
                Line_Number__c = errorAlert.Line_Number__c,
                Message__c = errorAlert.Message__c,
                Stack_Trace__c = errorAlert.Stack_Trace__c,
                Type_Name__c	 = errorAlert.Type_Name__c
            );
            errorLogsToInsert.add(newErrorLog);
        }
        
        insert errorLogsToInsert;
    }
}