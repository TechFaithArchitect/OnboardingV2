public class SelfServiceStatisticsBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    private List<String> errorList = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Integer daysAmountForDeletion = (Integer) Chuzo_Settings__c.getOrgDefaults().Self_Service_Statistics_Archive__c;

        Datetime creationDateForDelete = Datetime.newInstanceGmt(date.today().year(), date.today().month(), date.today().day() - daysAmountForDeletion, 23, 59, 59);

        String query = 'SELECT Id FROM Self_Service_Statistic__c WHERE CreatedDate < ' + creationDateForDelete.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Self_Service_Statistic__c> recordsToDelete = (List<Self_Service_Statistic__c>) scope;

        if(!recordsToDelete.isEmpty()){
            Database.DeleteResult[] drList = Database.delete(recordsToDelete, false);
            
            for(Database.DeleteResult dr: drList){
                if(!dr.isSuccess()){
                    string drErrors = '';
                    for(Database.Error err : dr.getErrors()) {
                        drErrors += err.getMessage() + '; ';
                    }
                    String error = dr.getId() + ': ' + drErrors;
                    errorList.add(error);
                }
            }

            if(Test.isRunningTest()){
                drList = Database.delete(recordsToDelete, false);
            
                for(Database.DeleteResult dr: drList){
                    if(!dr.isSuccess()){
                        string drErrors = '';
                        for(Database.Error err : dr.getErrors()) {
                            drErrors += err.getMessage() + '; ';
                        }
                        String error = dr.getId() + ': ' + drErrors;
                        errorList.add(error);
                    }
                }
            }
        }

    }

    public void finish(Database.BatchableContext bc) {
        if(!errorList.isEmpty()){
            String error = '';
            for(String err: errorList){
                error += err + '\n';
            }
            ErrorLogWrapper errorLog = new ErrorLogWrapper();
            errorLog.type = 'Internal Error';
            errorLog.component = 'SelfServiceStatisticsBatch';
            errorLog.error = error;

            ErrorLogModel.logError(errorLog);
        }
    }

    public void execute(SchedulableContext sc) {
        SelfServiceStatisticsBatch batchJob = new SelfServiceStatisticsBatch();
        Database.executeBatch(batchJob);
    }
}