global class PV_WorkTypeSRBatch implements Database.Batchable<sObject>, Database.Stateful{
    public Map<String, String> workTypeIdMap = new Map<String, String>();
    global Database.QueryLocator start(Database.BatchableContext bC) {
       getWorkTypeId();
       String query = 'SELECT Id, Name, isActive, ParentTerritoryId, Account__c, (SELECT Id,ServiceResource.IsActive FROM ServiceResources WHERE ServiceResource.IsActive = true AND ServiceResource.Vendor_Type__c INCLUDES (\'T-Mobile\', \'WOW\', \'AT&T\') AND EffectiveStartDate <= TODAY AND (EffectiveEndDate = null OR EffectiveEndDate >= TODAY)), (SELECT Id, Service_Territory__c, Work_Type__c, No_of_skilled_resources__c FROM Work_Type_SR_Counts__r) FROM ServiceTerritory WHERE ParentTerritoryId != null AND isActive = true AND Id IN (SELECT ServiceTerritoryId FROM ServiceTerritoryMember WHERE EffectiveStartDate <= TODAY AND (EffectiveEndDate = null OR EffectiveEndDate >= TODAY))';
       return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bC, List<ServiceTerritory> scope) {
        try{
            List<Work_Type_SR_Count__c> wtsrListToUpsert = new List<Work_Type_SR_Count__c>();
            List<Work_Type_SR_Count__c> wtsrListToDelete = new List<Work_Type_SR_Count__c>();
            Set<Id> SRId = new Set<Id>();
            //Used to get Service Resource Id
            for(ServiceTerritory sTerr : scope){
                for(ServiceTerritoryMember sTM : sTerr.ServiceResources){
                    SRId.add(sTM.ServiceResourceId);
                }
            }
            
            Map<Id,Map<String,boolean>> srWTMap = PV_WorkTypeSRBatchHandler.skillcheck(SRId);
            
            for(ServiceTerritory sTerr : scope){
                Map<String, Integer> workTypeIdCountMap = new Map<String, Integer>();
                for(ServiceTerritoryMember sTM : sTerr.ServiceResources){
                    
                    workTypeIdCountMap = checkAndSetWorkTypeCount(sTM, workTypeIdCountMap,srWTMap);
                }
                
                for(Work_Type_SR_Count__c wtsr : sTerr.Work_Type_SR_Counts__r){
                    if(workTypeIdCountMap.containsKey(wtsr.Work_Type__c))
                    {
                        if(workTypeIdCountMap.get(wtsr.Work_Type__c) != wtsr.No_of_skilled_resources__c){
                            wtsr.No_of_skilled_resources__c = workTypeIdCountMap.get(wtsr.Work_Type__c);
                            wtsrListToUpsert.add(wtsr);
                        }
                        workTypeIdCountMap.remove(wtsr.Work_Type__c);
                    }else if(!workTypeIdCountMap.containsKey(wtsr.Work_Type__c)){
                        wtsrListToDelete.add(wtsr);
                    }
                } 
                for(String wtId : workTypeIdCountMap.keySet()){
                    Work_Type_SR_Count__c wts = new Work_Type_SR_Count__c();
                    wts.Service_Territory__c = sTerr.Id;
                    wts.Work_Type__c = wtId;
                    wts.No_of_skilled_resources__c = workTypeIdCountMap.get(wtId);
                    wtsrListToUpsert.add(wts);
                }  
            }
            
            if(!wtsrListToUpsert.isEmpty()){
                //Database.upsert(wtsrListToUpsert, true, AccessLevel.SYSTEM_MODE);
                Database.upsert(wtsrListToUpsert);
            }
            if(!wtsrListToDelete.isEmpty()){
                //Database.delete(wtsrListToDelete, true, AccessLevel.SYSTEM_MODE);
                Database.delete(wtsrListToDelete);
            }
        }
        catch (Exception ex) {
            ExceptionUtil.publishException('PV_WorkTypeSRBatch.execute', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    global void finish(Database.BatchableContext bC) {
        Database.executeBatch(new PV_UpdatePercentInWTSRBatch());
    }
    
    private void getWorkTypeId(){
        for (WorkType wt : [SELECT Id,Work_Type_Code__c, Name FROM WorkType WHERE Vendor__c IN ('T-Mobile', 'WOW', 'AT&T')]) {
            workTypeIdMap.put(wt.Work_Type_Code__c, wt.Id);
        }
    }
    
    private Map<String, Integer> checkAndSetWorkTypeCount(ServiceTerritoryMember stm, Map<String, Integer> workTypeIdCountMap ,Map<Id,Map<String,boolean>> srWTMap){
        
        try {
            if(srWTMap.containsKey(stm.ServiceResourceId)){
                for(String wtcode: workTypeIdMap.keySet()){
                    if((srWTMap.get(stm.ServiceResourceId)).containsKey(wtcode) && srWTMap.get(stm.ServiceResourceId).get(wtcode)){
                        workTypeIdCountMap = setWorkTypeCountMap(workTypeIdCountMap, wtcode);
                    }
                }
            }
            return workTypeIdCountMap;
        } catch (Exception e) {
            System.debug('checkAndSetWorkTypeCount'+e.getTypeName() + ' - ' + e.getLineNumber() + ' - ' + e.getMessage());
        }
        return null;
    }
    
    private Map<String, Integer> setWorkTypeCountMap(Map<String, Integer> workTypeIdCountMap, String workTypeName){
        String workTypeId = workTypeIdMap.get(workTypeName);
        
        if(workTypeIdCountMap.containsKey(workTypeId)){
            workTypeIdCountMap.put(workTypeId, workTypeIdCountMap.get(workTypeId) + 1);
        }else{
            workTypeIdCountMap.put(workTypeId, 1);
        }
        return workTypeIdCountMap;
    }
    
}