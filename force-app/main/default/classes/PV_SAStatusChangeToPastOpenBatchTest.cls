@isTest
public class PV_SAStatusChangeToPastOpenBatchTest {
    static testmethod void test() {
        
        System.runAs(new User(Id = Userinfo.getUserId())){
            Account acct= PV_TestDataFactory.createAccount('TestAcc', true);
            contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acct);
            
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acct, pst);
            
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            
            ServiceResource sr = PV_TestDataFactory.createServiceResource(true,acct,con,usr);
            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,sr,childServiceTerritory,'P');
            WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill',true);
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);
            
            // Create test Service Appointment to be updated by batch
            List<ServiceAppointment>saList = new List<ServiceAppointment>();
            
            for(Integer i = 1; i <= 100; i++){
                ServiceAppointment saTest = new ServiceAppointment();
                saTest.Description = 'TestingSA' + i;
                saTest.ParentRecordId = wo.Id;
                saTest.ServiceTerritoryId = pst.Id;
                saTest.WorkTypeId = wt.Id;
                saTest.Status = 'Dispatched';
                saTest.FSSK__FSK_Work_Order__c =wo.Id;
                saTest.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
                saTest.SchedStartTime = System.now().adddays(-1);
                saTest.SchedEndTime = System.now().addHours(3);
                saTest.DueDate = System.today().adddays(3);
                saList.add(saTest);
            }
            if(!saList.isEmpty()){
                insert saList;
            }
            
            Test.startTest();
            PV_SAStatusChangeToPastOpenBatch b = new PV_SAStatusChangeToPastOpenBatch();
            Database.executeBatch(b);
            Test.stopTest();
        }
    }
}