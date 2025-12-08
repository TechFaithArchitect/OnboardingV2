public class POE_DeleteMapsLocationRecordsBatch implements Database.Batchable<sObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        if (!Test.isRunningTest()) {
            query = 'SELECT ID FROM maps__Location__c WHERE RecordType.Name = \'ClickerGeoCode\' LIMIT 15000000';
        } else {
            query = 'SELECT ID FROM maps__Location__c WHERE RecordType.Name = \'ClickerGeoCode\' LIMIT 200';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<maps__Location__c> recordsToDelete = (List<maps__Location__c>) scope;

        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
            System.debug('Deleted ' + recordsToDelete.size() + ' records.');
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Job finished');
    }

    public void execute(SchedulableContext sc) {
        POE_DeleteMapsLocationRecordsBatch batchJob = new POE_DeleteMapsLocationRecordsBatch();
        Database.executeBatch(batchJob);
    }
}