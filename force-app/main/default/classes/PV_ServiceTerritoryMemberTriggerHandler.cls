/**
 * @description       : PV_ServiceTerritoryMemberTriggerHandler is handler class for PV_ServiceTerritoryMemberTrigger
 * @author            : Impaqtive DevTeam
 * @last modified on  : 05-12-2023
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   05-12-2023   Impaqtive DevTeam   Initial Version
 **/
public class PV_ServiceTerritoryMemberTriggerHandler {
    //Method to set primary STM when a primary STM update or delete
    public static void updatePrimaryStm(list<ServiceTerritoryMember> oldStmList,Map<Id, ServiceTerritoryMember> newStmMap){
        Set<Id> ServiceResourceIdSet = new Set<Id>();
        Set<Id> stmUpdatedIdSet = new Set<Id>();
        Set<Id> deletedParentServiceTerritory = new Set<Id>();
        Id serviceResourceId;
        
        If (Trigger.isDelete){
            for (ServiceTerritoryMember oldStm : oldStmList) {
                If (oldStm.TerritoryType == 'P') {
                    ServiceResourceIdSet.add(oldStm.ServiceResourceId);
                }
                If(oldStm.Parent_Service_Territory__c != null){
                    deletedParentServiceTerritory.add(oldStm.Parent_Service_Territory__c);
                    serviceResourceId = oldStm.ServiceResourceId;
                }
            }
            If(!deletedParentServiceTerritory.isEmpty()){
                deleteParentrStm(deletedParentServiceTerritory,serviceResourceId);
            }
        }else If (Trigger.isUpdate){
            for (ServiceTerritoryMember oldStm : oldStmList) {
                // Logic to check STM is updated from primary to secondary
                If (oldStm.TerritoryType == 'P' && !oldStm.TerritoryType.equals(newStmMap.get(oldStm.Id).TerritoryType)) {
                    ServiceResourceIdSet.add(oldStm.ServiceResourceId);
                    stmUpdatedIdSet.add(oldStm.Id);
                }
                // Logic to check for a primary STM EndDate is updated
               /* If((oldStm.TerritoryType == 'P' && oldStm.TerritoryType.equals(newStmMap.get(oldStm.Id).TerritoryType))
                  && oldStm.EffectiveEndDate !=  newStmMap.get(oldStm.Id).EffectiveEndDate && newStmMap.get(oldStm.Id).EffectiveEndDate < Date.today()){
                      System.debug('*****Date Changed for primary****');
                }*/
            }
        }
        If(!ServiceResourceIdSet.isEmpty()) {
            List<ServiceTerritoryMember> updatedServiceTerritoryMembers = new List<ServiceTerritoryMember>();
            Map<Id, ServiceTerritoryMember> ServiceResourceStmMap = new Map <Id, ServiceTerritoryMember>();
            for(ServiceTerritoryMember stm : [Select Id,EffectiveStartDate, EffectiveEndDate,ServiceResourceId,TerritoryType,ServiceResource.Contact__r.MailingPostalCode,ServiceResource.Contact__r.MailingCity,
                                              ServiceResource.Contact__r.MailingStreet,ServiceResource.Contact__r.MailingState,ServiceResource.Contact__r.MailingCountry
                                              From ServiceTerritoryMember Where (EffectiveEndDate  > TODAY OR EffectiveEndDate  = null) 
                                              AND ServiceTerritory.ParentTerritoryId != null AND ServiceResourceId IN:ServiceResourceIdSet ORDER BY EffectiveStartDate ASC ]){
                                                      If(! ServiceResourceStmMap.containsKey(stm.ServiceResourceId) && ! stmUpdatedIdSet.contains(stm.Id)){
                                                          ServiceTerritoryMember stmSetToPrimary = new ServiceTerritoryMember(
                                                              Id= stm.Id,
                                                              TerritoryType = 'P',
                                                              Street  = stm.ServiceResource.Contact__r.MailingStreet,
                                                              City  = stm.ServiceResource.Contact__r.MailingCity,
                                                              State  = stm.ServiceResource.Contact__r.MailingState,
                                                              Country  = stm.ServiceResource.Contact__r.MailingCountry,
                                                              PostalCode  = stm.ServiceResource.Contact__r.MailingPostalCode
                                                          );
                                                          ServiceResourceStmMap.put(stm.ServiceResourceId, stmSetToPrimary);
                                                      }
                                              }
            If(!ServiceResourceStmMap.isEmpty()){
                try{
                    Update ServiceResourceStmMap.values();
                }catch (Exception ex) {
                    ExceptionUtil.publishException('PV_ServiceTerritoryMemberTriggerHandler', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
                }
            }
            
        }
    }
    
    //Method to create parent STM for child STM's
    public static void createParentrStm(Set<Id> newStmIdList/*list<ServiceTerritoryMember>newStmList*/){
        list<ServiceTerritoryMember> childStmList = [Select Id,ServiceTerritory.ParentTerritoryId,EffectiveStartDate,ServiceResourceId From ServiceTerritoryMember where ServiceTerritory.ParentTerritoryId != null
                                                    AND Id IN:newStmIdList];
        List<ServiceTerritoryMember> parentStmToCreateList = new List<ServiceTerritoryMember>();
        For(ServiceTerritoryMember cStm:childStmList){
            ServiceTerritoryMember pStm = new ServiceTerritoryMember();
            pStm.ServiceResourceId = cStm.ServiceResourceId;
            pStm.ServiceTerritoryId = cStm.ServiceTerritory.ParentTerritoryId;
            pStm.TerritoryType = 'S';
            pStm.EffectiveStartDate = cStm.EffectiveStartDate;
            parentStmToCreateList.add(pStm);
        }
        If(!parentStmToCreateList.isEmpty()){
            try{
                Insert parentStmToCreateList;
            }catch (Exception ex) {
                ExceptionUtil.publishException('PV_ServiceTerritoryMemberTriggerHandler', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            }
        }
        

    }
    //Method to delete parent STM when child deleted
    public static void deleteParentrStm(Set<Id>parenterritoryIds,Id serviceResourceId){
       list<ServiceTerritoryMember> deletedMemberList = [Select Id from ServiceTerritoryMember where ServiceTerritoryId IN:parenterritoryIds AND ServiceResourceId=:serviceResourceId];
        If(!deletedMemberList.isEmpty()){
            delete deletedMemberList;
        }
    }
}