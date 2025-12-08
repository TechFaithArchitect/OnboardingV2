/**
* @description       : Handler Class for PV_ServiceTerritoryTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 08-06-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
public class PV_ServiceTerritoryTriggerHandler {
    public static void handleAfterUpdate(List<ServiceTerritory> serviceTerritory){
        List<Id> deActivatedChildTerritoryIdList = new List<Id>();
        try{
            List<ServiceTerritory> stList = new List<ServiceTerritory>();
            for(ServiceTerritory st: serviceTerritory){
                if(st.IsActive == False){
                    stList.add(st);
                }
            }
            
            
            //Deactivating Child Service Territory
            List<ServiceTerritory> activeChildServiceTerritory = [SELECT Id, ParentTerritoryId, IsActive FROM ServiceTerritory WHERE ParentTerritoryId =: stList AND IsActive = True];
            if(!stList.isEmpty()){
                for(ServiceTerritory cst: activeChildServiceTerritory){
                    deActivatedChildTerritoryIdList.add(cst.Id);
                    cst.IsActive = False;
                }
            }
            update activeChildServiceTerritory;  
            
            //Logic to change primary stm to secondary
            if(! deActivatedChildTerritoryIdList.isEmpty()){
                List<ServiceTerritoryMember> stmToUpdateList = new List<ServiceTerritoryMember>();
                for(ServiceTerritoryMember stm: [Select Id from ServiceTerritoryMember where ServiceTerritoryId IN: deActivatedChildTerritoryIdList AND TerritoryType  = 'P']){
                    ServiceTerritoryMember stmupdate = new ServiceTerritoryMember();
                    stmupdate.Id = stm.Id;
                    stmupdate.City =null;
                    stmupdate.Country = null;
                    stmupdate.State = null;
                    stmupdate.Street = null;
                    stmupdate.PostalCode = null;
                    stmupdate.Latitude = null;
                    stmupdate.Longitude = null;
                    stmupdate.TerritoryType = 'S';
                    stmToUpdateList.add(stmupdate);
                }
                if(!stmToUpdateList.isEmpty()){
                    update stmToUpdateList;
                }
            }
            
            
            //Update Operating Hours of Child Service Territory
            List<ServiceTerritory> cstList = [SELECT Id, OperatingHoursId, ParentTerritoryId FROM ServiceTerritory WHERE ParentTerritoryId =: serviceTerritory AND IsActive = TRUE];
            for(ServiceTerritory st: serviceTerritory){
                for(ServiceTerritory cst: cstList){
                    if(cst.ParentTerritoryId == st.Id && cst.OperatingHoursId != st.OperatingHoursId){
                        cst.OperatingHoursId = st.OperatingHoursId;
                    }
                }
            }
            update cstList;
            
        }catch (Exception ex) {
            ExceptionUtil.publishException('PV_ServiceTerritoryTriggerHandler.handleAfterUpdate', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
}