/**
* @description       : Test Class for PV_ServiceTerritoryTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 08-06-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
@isTest
    public class PV_ServiceTerritoryTriggerHandlerTest {
    @TestSetup
    static void makeTestData() {
        Account acc= PV_TestDataFactory.createAccount('Test Account', true);
        contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc);
        OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        OperatingHours opHrs2= PV_TestDataFactory.createOperatingHours('West - Mon-Fri 8am - 5pm', true);
        ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc, pst);
        
        User usr = PV_TestDataFactory.createTechnicianUser(true,con);
        System.runAs(usr) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }
        
        ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true,acc,con,usr);
        ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes,childServiceTerritory,'P');
        pst.IsActive = False;
        pst.OperatingHoursId = opHrs2.Id;
        update pst;
        
        
    }
    
    @isTest
    static void handleBeforeUpdate(){
        Test.startTest();
        List<ServiceTerritory> stList = [SELECT Id,Name, IsActive, ParentTerritoryId, OperatingHoursId FROM ServiceTerritory];
        PV_ServiceTerritoryTriggerHandler.handleAfterUpdate(stList);
        Test.stopTest();
        ServiceTerritory cst = [SELECT Id,Name, IsActive, ParentTerritoryId, OperatingHoursId FROM ServiceTerritory WHERE ParentTerritoryId =: stList LIMIT 1];
        system.assertEquals(False, cst.IsActive);
    }
}