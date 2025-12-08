public class PV_WorkTypeSRCountHandler {

    public static void updatePercentageInWTSRCount(List<Work_Type_SR_Count__c> wtsrList) {
        Map<Id, Map<Id, Integer>> territoryWorkTypeMap = new Map<Id, Map<Id, Integer>>();
        List<Work_Type_SR_Count__c> wtSrCountUpdateList = new List<Work_Type_SR_Count__c>();
        Set<id> parentTerritorySet = new Set<Id>();

        for (Work_Type_SR_Count__c wtsr : wtsrList) {
            parentTerritorySet.add(wtsr.Service_Territory__r.ParentTerritoryId);
        }

        AggregateResult[] groupedResults = [
            SELECT  Count(Id), Sum(No_of_skilled_resources__c) skilledResources, Service_Territory__r.ParentTerritoryId parentTerritory,Work_Type__c worktypeId 
            FROM    Work_Type_SR_Count__c 
            WHERE   Service_Territory__r.ParentTerritoryId IN : parentTerritorySet 
            GROUP BY Service_Territory__r.ParentTerritoryId ,Work_Type__c
        ];
                                           
        for (AggregateResult agr:groupedResults) {
            if (!territoryWorkTypeMap.containsKey((Id)agr.get('parentTerritory'))) {
                territoryWorkTypeMap.put((Id)agr.get('parentTerritory'), new Map<Id, Integer>{(Id)agr.get('worktypeId') =>  Integer.valueOf(agr.get('skilledResources'))});    
            } else {
                territoryWorkTypeMap.get((Id)agr.get('parentTerritory')).put((Id)agr.get('worktypeId'), Integer.valueOf(agr.get('skilledResources')));
            }
        }

        for (Work_Type_SR_Count__c wtsr : wtsrList) {
            if (territoryWorkTypeMap.containsKey(wtsr.Service_Territory__r.ParentTerritoryId) && 
               territoryWorkTypeMap.get(wtsr.Service_Territory__r.ParentTerritoryId).containsKey(wtsr.Work_Type__c))
            {
                wtsr.Service_Resource_Percentage__c = (wtsr.No_of_skilled_resources__c / territoryWorkTypeMap.get(wtsr.Service_Territory__r.ParentTerritoryId).get(wtsr.Work_Type__c))*100;
                wtSrCountUpdateList.add(wtsr);
            }
        }

        if (!wtSrCountUpdateList.isEmpty()) {
            Database.update(wtSrCountUpdateList, true, AccessLevel.SYSTEM_MODE);
        }
    }

    @InvocableMethod(label='Handle Territory Inactivation' description='Handles the inactivation of a territory')
    public static void handleTerritoryInactivation(List<Id> territoryIds) {
        Set<Id> parentTerritoryIds = new Set<Id>();
        
        for (ServiceTerritory serviceTerritory : [SELECT ParentTerritoryId FROM ServiceTerritory WHERE Id = :territoryIds]) {
            if (serviceTerritory.ParentTerritoryId != null) {
                parentTerritoryIds.add(serviceTerritory.ParentTerritoryId);
            }
        }

        List<Work_Type_SR_Count__c> wtsrList = [
            SELECT  Id, Service_Territory__r.ParentTerritoryId, Work_Type__c, No_of_skilled_resources__c, Service_Resource_Percentage__c
            FROM    Work_Type_SR_Count__c
            WHERE   Service_Territory__r.ParentTerritoryId IN :parentTerritoryIds
        ];
        
        updatePercentageInWTSRCount(wtsrList);
    }
}