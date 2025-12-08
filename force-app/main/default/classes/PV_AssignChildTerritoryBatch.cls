public class PV_AssignChildTerritoryBatch implements Database.Batchable<sObject> {
    private List<Id> serviceAppointmentIds;
    
    public PV_AssignChildTerritoryBatch() {
    }
    
    public PV_AssignChildTerritoryBatch(List<Id> serviceAppointmentIds) {
        this.serviceAppointmentIds = serviceAppointmentIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (serviceAppointmentIds == null || serviceAppointmentIds.isEmpty()) {
            return Database.getQueryLocator('SELECT Id FROM ServiceAppointment WHERE Id = null');
        }

        String query =
        'SELECT Id,Status,AppointmentNumber,FSSK__FSK_Work_Order__c,FSSK__FSK_Work_Order__r.Vendor__c,WorkTypeId,ServiceTerritoryId,ServiceTerritory.ParentTerritoryId ' +
        'FROM   ServiceAppointment ' +
        'WHERE  Id IN :serviceAppointmentIds';

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<ServiceAppointment> saList) {
        try {
            Map<Id, Map<Id, List<ServiceAppointment>>> pTerritoryApptMap = new Map<Id, Map<Id, List<ServiceAppointment>>>();
            Map<Id, Map<Id, List<Id>>> pTerritoryWTCSTListMap = new Map<Id, Map<Id, List<Id>>>();
            Map<Id, Map<Id, Decimal>> cTerritoryWtRatio = new Map<Id, Map<Id, Decimal>>();
            
            List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>();
            
            for (ServiceAppointment sa : saList) {
                if (!pTerritoryApptMap.containsKey(sa.ServiceTerritoryId)) {
                    pTerritoryApptMap.put(sa.ServiceTerritoryId, new Map<Id, List<ServiceAppointment>>{sa.WorkTypeId => new List<ServiceAppointment>{sa}});
                } else {         
                    if(!pTerritoryApptMap.get(sa.ServiceTerritoryId).containsKey(sa.WorkTypeId)){
                        pTerritoryApptMap.get(sa.ServiceTerritoryId).put(sa.WorkTypeId, new List<ServiceAppointment>{sa});
                    }else{
                        pTerritoryApptMap.get(sa.ServiceTerritoryId).get(sa.WorkTypeId).add(sa);
                    }
                }
            }
            
            for (Work_Type_SR_Count__c wtrc : [
                SELECT  Service_Territory__c, Service_Territory__r.ParentTerritoryId, Work_Type__c, No_of_skilled_resources__c, Service_Resource_Percentage__c 
                FROM    Work_Type_SR_Count__c 
                WHERE   Service_Territory__r.ParentTerritoryId IN :PTerritoryApptMap.keySet()
                AND     Service_Territory__r.IsActive = true
            ]) {
                
                if (!pTerritoryWTCSTListMap.containsKey(wtrc.Service_Territory__r.ParentTerritoryId)) {
                    pTerritoryWTCSTListMap.put(wtrc.Service_Territory__r.ParentTerritoryId, new Map<Id, List<Id>>{wtrc.Work_Type__c => new List<Id>{wtrc.Service_Territory__c}});    
                } else {         
                    if(! pTerritoryWTCSTListMap.get(wtrc.Service_Territory__r.ParentTerritoryId).containsKey(wtrc.Work_Type__c)){
                        pTerritoryWTCSTListMap.get(wtrc.Service_Territory__r.ParentTerritoryId).put(wtrc.Work_Type__c, new List<Id>{wtrc.Service_Territory__c});
                    }else {
                        pTerritoryWTCSTListMap.get(wtrc.Service_Territory__r.ParentTerritoryId).get(wtrc.Work_Type__c).add(wtrc.Service_Territory__c);
                    }
                }
                
                if (!cTerritoryWtRatio.containsKey(wtrc.Service_Territory__c)) {
                    cTerritoryWtRatio.put(wtrc.Service_Territory__c, new Map<Id, Decimal>{wtrc.Work_Type__c =>  wtrc.Service_Resource_Percentage__c});
                } else {
                    cTerritoryWtRatio.get(wtrc.Service_Territory__c).put(wtrc.Work_Type__c, wtrc.Service_Resource_Percentage__c);
                }
            }

            for (Id pst:pTerritoryApptMap.keySet()) {
                
                for(Id wtype:pTerritoryApptMap.get(pst).keySet()){
                    if(pTerritoryWTCSTListMap.get(pst) != Null && pTerritoryWTCSTListMap.get(pst).get(wtype) != Null){
                        if(pTerritoryApptMap.get(pst).get(wtype).size() < pTerritoryWTCSTListMap.get(pst).get(wtype).size()){
                            saToUpdateList.addAll(apptLessThanDealer (pTerritoryApptMap.get(pst).get(wtype), pTerritoryWTCSTListMap.get(pst).get(wtype)));
                        }else if(pTerritoryApptMap.get(pst).get(wtype).size() == pTerritoryWTCSTListMap.get(pst).get(wtype).size()){
                            saToUpdateList.addAll(apptLessThanDealer (pTerritoryApptMap.get(pst).get(wtype), pTerritoryWTCSTListMap.get(pst).get(wtype)));
                        }else{
                            saToUpdateList.addAll(apptGreaterThanDealer (pTerritoryApptMap.get(pst).get(wtype), pTerritoryWTCSTListMap.get(pst).get(wtype),wtype,cTerritoryWtRatio));
                        }
                    }
                }
            }

            List<Database.SaveResult> saveResults = Database.update(saToUpdateList, false);
            String firstErrorType = null;
            String firstErrorRecordId = null;

            for (Database.SaveResult sr : saveResults) {
                if (!sr.isSuccess() && !sr.getErrors().isEmpty()) {
                    Database.Error firstError = sr.getErrors()[0];
                    firstErrorType = firstError.getStatusCode() + ': ' + firstError.getMessage();
                    firstErrorRecordId = sr.getId();
                    break;
                }
            }

            if (firstErrorType != null) {
                String errorMessage = 'Record ID: ' + firstErrorRecordId + ' - Error Type: ' + firstErrorType;
                ExceptionUtil.publishException('PV_AssignChildTerritoryBatch.execute', 0, errorMessage, 'N/A');
            }
        } catch (Exception ex) {
            ExceptionUtil.publishException('PV_AssignChildTerritoryBatch.execute', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
    
    public static List<ServiceAppointment> apptLessThanDealer(List<ServiceAppointment> apptList, List<Id> cTerritoryList){

        for(ServiceAppointment sa: apptList){
            Integer randomIndex = Math.roundToLong(Math.random() * (cTerritoryList.size()-1)).intValue();
            sa.ServiceTerritoryId = cTerritoryList[randomIndex];
            cTerritoryList.remove(randomIndex);
        }
        return apptList;
    }
    
    public static List<ServiceAppointment> apptGreaterThanDealer(List<ServiceAppointment> apptList, List<Id> cTerritoryList, Id WType, Map<Id, Map<Id, Decimal>> cTerritoryWtRatio){

        Integer apptCount = apptList.size();
        Map<Id, Integer> cTerritorySACount = new Map<Id, Integer>();
        List<ServiceAppointment> apptsToReassign = new List<ServiceAppointment>();
        
        for(Id cst: cTerritoryWtRatio.keySet()){
            if(cTerritoryList.contains(cst) && cTerritoryWtRatio.get(cst).containsKey(WType)){
                cTerritorySACount.put(cst, Integer.valueOf(cTerritoryWtRatio.get(cst).get(WType) * apptCount / 100));
            }
        }        
        
        for(Id cst: cTerritorySACount.keySet()){
            for(integer i = 0; i < cTerritorySACount.get(cst); i++){
                if(!apptList.isempty()){
                ServiceAppointment sa = new ServiceAppointment();
                sa.Id = apptList[0].Id;
                sa.ServiceTerritoryId = cst;
                apptsToReassign.add(sa);
                apptList.remove(0);
                }
            }
        }
       
        for(ServiceAppointment sa: apptList){
            Integer randomIndex = Math.roundToLong(Math.random() * (cTerritoryList.size()-1)).intValue();
            sa.ServiceTerritoryId = cTerritoryList[randomIndex];
            apptsToReassign.add(sa);
            cTerritoryList.remove(randomIndex);
        }
        return apptsToReassign;
    }
}