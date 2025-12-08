public class FSL_DeleteDummyOrdersBatch implements Database.Batchable<SObject>, Database.Stateful {
    @testVisible private static Boolean throwException = false;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String guestUserName = FSL_Settings__c.getInstance().Self_Schedule_Guest_User_Name__c;

        return Database.getQueryLocator([
            SELECT  Id
            FROM    WorkOrder
            WHERE   Vendor__c = null
            AND     External_WO_Id__c = null
            AND     CreatedBy.Name = :guestUserName
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<WorkOrder> scope) {
        List<Database.DeleteResult> deleteResults = Database.delete(scope, false);

        if (Test.isRunningTest() && throwException) {
            deleteResults = Database.delete(scope, false);
        }

        PV_RecordOperationHandler.ProcessResult result = PV_RecordOperationHandler.processDeleteResults(deleteResults);

        if (result.firstErrorType != null) {
            String errorMessage = 'Record ID: ' + result.firstErrorRecordId + ' - Error Type: ' + result.firstErrorType;
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', FSL_DeleteDummyOrdersBatch.class.getName(), errorMessage);
        } else {
            System.debug('FSL_DeleteDummyOrdersBatch successfully executed. A total of ' + scope.size() + ' records were deleted.');
        }
    }

    public void finish(Database.BatchableContext BC) {
    }
}