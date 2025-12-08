/**
* @description       : Test Class for PV_ExceptionTriggerHandler
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 12-06-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
@isTest
public class PV_ExceptionTriggerHandlerTest {
    @TestSetup
    static void makeTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())){
            Account acct= PV_TestDataFactory.createAccount('TestAcc', true);
            contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acct);
            
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acct, pst);
            
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            
            ServiceResource sr = PV_TestDataFactory.createServiceResource(true,acct,con,usr);
            sr.Manager__c = UserInfo.getUserId();
            update sr;
            
            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,sr,childServiceTerritory,'P');
            WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill',true);
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);
            
            ServiceAppointment sa = new ServiceAppointment();
            sa.ParentRecordId = wo.Id;
            sa.ServiceTerritoryId = pst.Id;
            sa.WorkTypeId = wt.Id;
            sa.Status = 'Scheduled';
            sa.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
            sa.SchedStartTime = System.now();
            sa.SchedEndTime = System.now().addHours(3);
            sa.DueDate = System.today().adddays(3);
            insert sa;
            
            Exception__c ex1 = new Exception__c();
            //ex1.Name = 'TestException';
            ex1.Dealer__c = acct.id;
            ex1.Customer__c = acct.Id;
            ex1.Approved__c = False;
            //ex1.Service_Resource__c=sr.Id;
            ex1.Service_Appointment__c=sa.Id;
            ex1.Type__c = 'Repair';
            insert ex1;
            System.debug('ex1>>>>>>>>>>'+ex1);
        }
        
    }
    
    @isTest
    static void testData(){
        
        List<Account> acct1 = [SELECT Id FROM Account];
        List<ServiceAppointment> sa1 = [SELECT Id FROM ServiceAppointment];
        
        Exception__c ex1 = new Exception__c();
        //ex1.Name = 'TestException';
        ex1.Dealer__c = acct1[0].Id;
        ex1.Customer__c = acct1[0].Id;
        ex1.Approved__c = False;
        //ex1.Service_Resource__c=sr.Id;
        ex1.Service_Appointment__c=sa1[0].Id;
        ex1.Type__c = 'Repair';
        insert ex1;
    }
    
    
}