public with sharing class FSL_ShiftsDeletionBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Date cutoffDate;
    public final Integer defaultDaysBeforeDeletingShifts = 7;
    @testVisible private static Boolean throwException = false;
    
    public FSL_ShiftsDeletionBatch() {
        FSL_Settings__c fslSettings = FSL_Settings__c.getInstance();
    
        if (fslSettings != null && fslSettings.Days_Before_Deleting_Shifts__c != null) {
            cutoffDate = Date.today().addDays(-Integer.valueOf(fslSettings.Days_Before_Deleting_Shifts__c));
        } else {
            cutoffDate = Date.today().addDays(-Integer.valueOf(defaultDaysBeforeDeletingShifts));
        }
    }    

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT  Id
            FROM    Shift
            WHERE   StartTime < :cutoffDate
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Database.DeleteResult> deleteResults = Database.delete(scope, false);

        if (Test.isRunningTest() && throwException) {
            deleteResults = Database.delete(scope, false);
        }

        ProcessSaveResult result = processSaveResults(deleteResults);

        if (result.firstErrorType != null) {
            String errorMessage = 'Record ID: ' + result.firstErrorRecordId + ' - Error Type: ' + result.firstErrorType;
            ExceptionUtil.publishException('FSL_ShiftsDeletionBatch.execute', 0, errorMessage, 'N/A');
        } else {
            System.debug('FSL_ShiftsDeletionBatch successfully executed. A total of ' + scope.size() + ' records were deleted.');
        }
    }
    
    public ProcessSaveResult processSaveResults(List<Database.DeleteResult> deleteResults) {
        ProcessSaveResult result = new ProcessSaveResult();
    
        for (Database.DeleteResult deleteResult : deleteResults) {
            if (!deleteResult.isSuccess() && !deleteResult.getErrors().isEmpty()) {
                Database.Error firstError = deleteResult.getErrors()[0];
                result.firstErrorType = firstError.getStatusCode() + ': ' + firstError.getMessage();
                result.firstErrorRecordId = deleteResult.getId();
                break;
            }
        }
        return result;
    }

    public void finish(Database.BatchableContext BC) {
    }

    public class ProcessSaveResult {
        public String firstErrorType { get; set; }
        public String firstErrorRecordId { get; set; }
    }
}