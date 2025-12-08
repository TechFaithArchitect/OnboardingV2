public with sharing class PV_RecordOperationHandler implements Database.Stateful {

    public static ProcessResult processSaveResults(List<Database.SaveResult> saveResults) {
        ProcessResult result = new ProcessResult();
    
        for (Database.SaveResult saveResult : saveResults) {
            if (!saveResult.isSuccess() && !saveResult.getErrors().isEmpty()) {
                Database.Error firstError = saveResult.getErrors()[0];
                result.firstErrorType = firstError.getStatusCode() + ': ' + firstError.getMessage();
                break;
            }
        }
        return result;
    }

    public static ProcessResult processDeleteResults(List<Database.DeleteResult> deleteResults) {
        ProcessResult result = new ProcessResult();
    
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

    public class ProcessResult {
        public String firstErrorType { get; set; }
        public String firstErrorRecordId { get; set; }
    }
}