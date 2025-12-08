@isTest
public class PV_WorkPlanControllerTest {

    @testSetup
    static void testData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
        
            Account acc = PV_TestDataFactory.createAccount('Test Account', true);
            contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc);
            OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
            // ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc, pst);
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            // ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true,acc,con,usr);
            // ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes,childServiceTerritory,'P');
            WorkType wt = PV_TestDataFactory.createWorkType('T-Mobile Commercial Install - Cellular Gateway Only',true);
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);

            /*
            ServiceAppointment sa = new ServiceAppointment();
            sa.ParentRecordId = wo.Id;
            sa.ServiceTerritoryId = pst.Id;
            sa.WorkTypeId = wt.Id;
            insert sa;
            */
            Test.stopTest();
        }
    }

    @isTest
    static void getWorkPlan(){
        Test.startTest();
        List<WorkOrder> wo = [SELECT Id FROM WorkOrder];
        List<ServiceTerritory> pst = [SELECT Id FROM ServiceTerritory];
        List<WorkType> wt = [SELECT Id,Name FROM WorkType WHERE Name = 'T-Mobile Commercial Install - Cellular Gateway Only'];
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = wo[0].Id;
        sa.ServiceTerritoryId = pst[0].Id;
        sa.WorkTypeId = wt[0].Id;
        insert sa;
        
        PV_WorkPlanController.getWorkPlanType(sa.Id);
        PV_WorkPlanController.getWorkPlan(wt[0].Name);
        Test.stopTest();
    } 
}