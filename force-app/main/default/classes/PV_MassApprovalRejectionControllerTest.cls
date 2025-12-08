@isTest
public class PV_MassApprovalRejectionControllerTest {
    @testSetup
    static void setupMethod() {
        System.runAs(new User(Id = Userinfo.getUserId())){
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
            ex1.Dealer__c = acct.id;
            ex1.Customer__c = acct.Id;
            ex1.Approved__c = False;
            ex1.Service_Appointment__c=sa.Id;
            ex1.Type__c = 'Repair';
            ex1.Approver__c = UserInfo.getUserId();
            insert ex1;
            
            Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
            app.setObjectId(ex1.id);
            Approval.ProcessResult rslt = approval.process(app);
        }
        
    } 
    
    @isTest
    static void getSubmittedRecordsTest(){
        
        Test.startTest();
        List<PV_MassApprovalRejectionController.SubmittedRecordsWrapper> result = PV_MassApprovalRejectionController.getSubmittedRecords();
        Test.stopTest();
        
        Assert.areEqual(1, result.size(), 'The service should have returned one result');
    }

    @isTest
    static void getObjectNameTest() {
        Account acc = [SELECT Id,Name FROM Account  WHERE Name =: 'TestAcc'];
        Exception__c ex = [SELECT Id,Name,Dealer__c,Customer__c FROM Exception__c WHERE Dealer__c=:acc.Id];
        string recordId=ex.Id;
        
        Test.startTest();
        PV_MassApprovalRejectionController.getObjectName(recordId);
        Test.stopTest();
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(ex.id);
        Assert.areEqual(ex.Id, app.getObjectId(), 'The approval object Id did not match');
        
    }

    @isTest
    static void processRecordsTest() {
        Test.startTest();
        Account acc = [SELECT Id,Name FROM Account  WHERE Name = :'TestAcc'];
        Exception__c ex1 = [SELECT Id,Name,Dealer__c,Customer__c FROM Exception__c WHERE Dealer__c = :acc.Id];
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(ex1.id);
        app.setComments('Records Approved');
        app.processdefinitionnameorid = 'Approve';
        
        List<Id> workitemids = new List<Id>();
        List<Exception__c> ex = [SELECT Id,Name,Dealer__c,Customer__c,Approved__c FROM Exception__c WHERE Dealer__c = :acc.Id];
        for(Exception__c exs : ex){
            workitemids.add(exs.Id);
        }
        
        PV_MassApprovalRejectionController.processRecords(workitemids, app.getProcessDefinitionNameOrId(), app.getComments());
        Test.stopTest();
        
        Assert.areEqual('Records Approved', app.getComments(), 'The approval comment does not match');
    }
}