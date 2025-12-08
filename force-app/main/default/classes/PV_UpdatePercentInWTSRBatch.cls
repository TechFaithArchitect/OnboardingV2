global class PV_UpdatePercentInWTSRBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Service_Territory__r.ParentTerritoryId, Work_Type__c, No_of_skilled_resources__c, Service_Resource_Percentage__c FROM Work_Type_SR_Count__c';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bC, List<Work_Type_SR_Count__c> wtsrList) {
        PV_WorkTypeSRCountHandler.updatePercentageInWTSRCount(wtsrList);
    }
    
    global void finish(Database.BatchableContext bC) {
    }
}