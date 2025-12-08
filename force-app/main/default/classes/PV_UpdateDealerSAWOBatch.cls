public class PV_UpdateDealerSAWOBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //collect the batches of records to be passed to execute
        String query = 'SELECT Id,AppointmentNumber,Dealer__c,FSSK__FSK_Work_Order__r.Dealer__c,ServiceTerritoryId,FSSK__FSK_Assigned_Service_Resource__c,FSSK__FSK_Assigned_Service_Resource__r.AccountId FROM ServiceAppointment WHERE FSSK__FSK_Assigned_Service_Resource__c != NULL';        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<ServiceAppointment> saList) {
        try {
            List<Id> woIds = new List<Id>();
            Map<String,Id> woDealerMap = new Map<String,Id>();
            for(ServiceAppointment sa : saList) {
                sa.Dealer__c = sa.FSSK__FSK_Assigned_Service_Resource__r.AccountId;
                woIds.add(sa.FSSK__FSK_Work_Order__c);
                woDealerMap.put(sa.FSSK__FSK_Work_Order__c,sa.FSSK__FSK_Assigned_Service_Resource__r.AccountId);
            }
            update saList;
            List<WorkOrder> woList = [Select Id, Dealer__c from WorkOrder where Id IN: woIds];
            for(WorkOrder wo : woList ){
                wo.Dealer__c = woDealerMap.get(wo.Id);
            }
            update woList;
        }catch (Exception ex) {
            ExceptionUtil.publishException('PV_UpdateDealerSAWOBatch.execute', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }

}