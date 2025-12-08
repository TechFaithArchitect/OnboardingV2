@isTest
public class PV_UpdateDealerSAWOBatchTest {
    @TestSetup
    static void makeTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            
            Account acc1 = PV_TestDataFactory.createAccount('Test Account1', true);
            Contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc1);
            OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst1 = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-0001',opHrs);
            // ServiceTerritory cst1 = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc1, pst1);
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true,acc1,con,usr);
            // ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes,cst1,'P');
            WorkType wt = PV_TestDataFactory.createWorkType('DIRECTV Install',true);
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);
            /*
            ServiceRes.RelatedRecordId = usr.Id;
            update ServiceRes;
            */
            
            // ServiceAppointment sa01 = new ServiceAppointment();
            // sa01.ParentRecordId = wo.Id;
            // sa01.FSSK__FSK_Work_Order__c = wo.Id;
            // sa01.ServiceTerritoryId = pst1.Id;
            // sa01.WorkTypeId = wt.Id;
            // sa01.Status = 'Unscheduled';
            // sa01.SchedStartTime = System.Today();
            // sa01.SchedEndTime = System.now().addHours(3);
            // sa01.DueDate = System.today().adddays(4);
            // sa01.FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id;
            // sa01.EarliestStartTime = System.now();
            // insert sa01;

            ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :wo.Id];
            sa.FSSK__FSK_Work_Order__c = wo.Id;
            sa.FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id;
            update sa;
            Test.stopTest();
        }
    }

    @isTest
    static void updateDealerTest() {
        Test.startTest();
        PV_UpdateDealerSAWOBatch ba = new PV_UpdateDealerSAWOBatch();
        Id jobid = Database.executeBatch(ba, 20);
        Test.stopTest();
    }
}