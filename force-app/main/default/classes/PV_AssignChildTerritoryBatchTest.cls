@isTest
public class PV_AssignChildTerritoryBatchTest {
    
    @TestSetup
    static void makeTestData() {
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) { 
            Account acc1= PV_TestDataFactory.createAccount('Test Account1', true);
            Account acc2= PV_TestDataFactory.createAccount('Test Account2', true);
            contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc1);
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst1 = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-0001',opHrs);
            ServiceTerritory cst1 = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc1, pst1);
            ServiceTerritory cst2 = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc2, pst1);

            WorkType wt1 = PV_TestDataFactory.createWorkType('T-Mobile Site Survey',true);
            WorkType wt2 = PV_TestDataFactory.createWorkType('T-Mobile Home Office Install - Cellular Gateway Only',true);
            WorkType wt3 = PV_TestDataFactory.createWorkType('T-Mobile Commercial Install - w/ External Antenna',true);
            
            Work_Type_SR_Count__c wsr1 =new Work_Type_SR_Count__c();
            wsr1.No_of_skilled_resources__c = 1;
            wsr1.Service_Resource_Percentage__c =50;
            wsr1.Service_Territory__c = cst1.Id;
            wsr1.Work_Type__c = wt1.Id;
            insert wsr1;

            Work_Type_SR_Count__c wsr2 =new Work_Type_SR_Count__c();
            wsr2.No_of_skilled_resources__c = 1;
            wsr2.Service_Resource_Percentage__c =50;
            wsr2.Service_Territory__c = cst2.Id;
            wsr2.Work_Type__c = wt1.Id;
            insert wsr2;

            Work_Type_SR_Count__c wsr3 =new Work_Type_SR_Count__c();
            wsr3.No_of_skilled_resources__c = 1;
            wsr3.Service_Resource_Percentage__c =50;
            wsr3.Service_Territory__c = cst1.Id;
            wsr3.Work_Type__c = wt2.Id;
            insert wsr3;

            Work_Type_SR_Count__c wsr4 =new Work_Type_SR_Count__c();
            wsr4.No_of_skilled_resources__c = 1;
            wsr4.Service_Resource_Percentage__c =50;
            wsr4.Service_Territory__c = cst2.Id;
            wsr4.Work_Type__c = wt2.Id;
            insert wsr4;
            
            Work_Type_SR_Count__c wsr5 =new Work_Type_SR_Count__c();
            wsr5.No_of_skilled_resources__c = 1;
            wsr5.Service_Resource_Percentage__c =50;
            wsr5.Service_Territory__c = cst1.Id;
            wsr5.Work_Type__c = wt3.Id;
            insert wsr5;

            Work_Type_SR_Count__c wsr6 =new Work_Type_SR_Count__c();
            wsr6.No_of_skilled_resources__c = 1;
            wsr6.Service_Resource_Percentage__c =50;
            wsr6.Service_Territory__c = cst2.Id;
            wsr6.Work_Type__c = wt3.Id;
            insert wsr6;
            
            List<WorkOrder> wolist = new List<WorkOrder>();
            WorkOrder wo1 = new WorkOrder();
            wo1.ServiceTerritoryId = pst1.Id;
            wo1.Status = 'Unscheduled';
            wo1.OwnerId = usr.Id;
            wo1.WorkTypeId = wt1.Id;
            wo1.Vendor__c = 'T-Mobile';
            wolist.add(wo1);

            WorkOrder wo2 = new WorkOrder();
            wo2.Status = 'Unscheduled';
            wo2.OwnerId = usr.Id;
            wo2.ServiceTerritoryId = pst1.Id;
            wo2.WorkTypeId = wt2.Id;
            wo2.Vendor__c = 'T-Mobile';
            wolist.add(wo2);

            WorkOrder wo3 = new WorkOrder();
            wo3.Status = 'Unscheduled';
            wo3.OwnerId = usr.Id;
            wo3.ServiceTerritoryId = pst1.Id;
            wo3.WorkTypeId = wt3.Id;
            wo3.Vendor__c = 'T-Mobile';
            wolist.add(wo3);
            insert wolist;
            
            List<ServiceAppointment> salist = new List<ServiceAppointment>();
            ServiceAppointment sa1 = new ServiceAppointment();
            sa1.Status = 'Unscheduled';
            sa1.ParentRecordId = wo1.Id;
            sa1.FSSK__FSK_Work_Order__c = wo1.Id;
            sa1.ServiceTerritoryId = pst1.Id;
            sa1.WorkTypeId = wt1.Id;
            sa1.SchedStartTime = System.Today();
            sa1.SchedEndTime = System.now().addHours(3);
            sa1.DueDate = System.today().adddays(4);
            sa1.EarliestStartTime = System.now();
            salist.add(sa1);

            ServiceAppointment sa2 = new ServiceAppointment();
            sa2.Status = 'Unscheduled';
            sa2.ParentRecordId = wo2.Id;
            sa2.FSSK__FSK_Work_Order__c = wo2.Id;
            sa2.ServiceTerritoryId = pst1.Id;
            sa2.WorkTypeId = wt2.Id;
            sa2.SchedStartTime = System.Today();
            sa2.SchedEndTime = System.now().addHours(3);
            sa2.DueDate = System.today().adddays(4);
            sa2.EarliestStartTime = System.now();
            salist.add(sa2);

            ServiceAppointment sa3 = new ServiceAppointment();
            sa3.Status = 'Unscheduled';
            sa3.ParentRecordId = wo2.Id;
            sa3.FSSK__FSK_Work_Order__c = wo2.Id;
            sa3.ServiceTerritoryId = pst1.Id;
            sa3.WorkTypeId = wt2.Id;
            sa3.SchedStartTime = System.Today();
            sa3.SchedEndTime = System.now().addHours(3);
            sa3.DueDate = System.today().adddays(4);
            sa3.EarliestStartTime = System.now();
            salist.add(sa3);

            ServiceAppointment sa4 = new ServiceAppointment();
            sa4.Status = 'Unscheduled';
            sa4.ParentRecordId = wo3.Id;
            sa4.FSSK__FSK_Work_Order__c = wo3.Id;
            sa4.ServiceTerritoryId = pst1.Id;
            sa4.WorkTypeId = wt3.Id;
            sa4.SchedStartTime = System.Today();
            sa4.SchedEndTime = System.now().addHours(3);
            sa4.DueDate = System.today().adddays(4);
            sa4.EarliestStartTime = System.now();
            salist.add(sa4);

            ServiceAppointment sa5 = new ServiceAppointment();
            sa5.Status = 'Unscheduled';
            sa5.ParentRecordId = wo3.Id;
            sa5.FSSK__FSK_Work_Order__c = wo3.Id;
            sa5.ServiceTerritoryId = pst1.Id;
            sa5.WorkTypeId = wt3.Id;
            sa5.SchedStartTime = System.Today();
            sa5.SchedEndTime = System.now().addHours(3);
            sa5.DueDate = System.today().adddays(4);
            sa5.EarliestStartTime = System.now();
            salist.add(sa5);

            ServiceAppointment sa6 = new ServiceAppointment();
            sa6.Status = 'Unscheduled';
            sa6.ParentRecordId = wo3.Id;
            sa6.FSSK__FSK_Work_Order__c = wo3.Id;
            sa6.ServiceTerritoryId = pst1.Id;
            sa6.WorkTypeId = wt3.Id;
            sa6.SchedStartTime = System.Today();
            sa6.SchedEndTime = System.now().addHours(3);
            sa6.DueDate = System.today().adddays(4);
            sa6.EarliestStartTime = System.now();
            salist.add(sa6);
            insert salist;
            Test.stopTest();
        }
    }
    
    @isTest
    static void tmobileSATest(){
        Test.startTest();
        ServiceTerritory pst1 = [SELECT Id,Name FROM ServiceTerritory WHERE Name = :'ST-0001'];
        List<ServiceTerritory> cst = [SELECT Id,Name,ParentTerritoryId FROM ServiceTerritory WHERE ParentTerritoryId = :pst1.Id];
        List<Work_Type_SR_Count__c> wsr = [SELECT Service_Territory__c, Service_Territory__r.ParentTerritoryId, Work_Type__c, No_of_skilled_resources__c, Service_Resource_Percentage__c FROM Work_Type_SR_Count__c WHERE Service_Territory__r.ParentTerritoryId =: pst1.Id];
        List<WorkOrder> wolist = [SELECT Id, ServiceTerritoryId from WorkOrder  WHERE ServiceTerritoryId =:pst1.Id];
        List<ServiceAppointment> saList = [SELECT Id,Status,AppointmentNumber,FSSK__FSK_Work_Order__c,FSSK__FSK_Work_Order__r.Vendor__c,WorkTypeId,ServiceTerritoryId,ServiceTerritory.ParentTerritoryId FROM ServiceAppointment WHERE ServiceTerritoryId =:pst1.Id];

        PV_AssignChildTerritoryBatch ba = new PV_AssignChildTerritoryBatch();
        Id jobid = Database.executeBatch(ba, 20);
        Test.stopTest();
    }

    @isTest
    static void testWithInactiveTerritory() {
        Test.startTest();
        
        ServiceTerritory pst1 = [SELECT Id,Name FROM ServiceTerritory WHERE Name = 'ST-0001'];
        List<ServiceTerritory> cst = [SELECT Id,Name,ParentTerritoryId,IsActive FROM ServiceTerritory WHERE ParentTerritoryId = :pst1.Id];
        List<Work_Type_SR_Count__c> wsr = [
            SELECT  Service_Territory__c, Service_Territory__r.ParentTerritoryId, Work_Type__c, No_of_skilled_resources__c, Service_Resource_Percentage__c 
            FROM    Work_Type_SR_Count__c 
            WHERE   Service_Territory__r.ParentTerritoryId = :pst1.Id
        ];

        List<WorkOrder> woList = [SELECT Id, ServiceTerritoryId from WorkOrder WHERE ServiceTerritoryId =:pst1.Id];
        List<ServiceAppointment> saList = [
            SELECT  Id,Status,AppointmentNumber,FSSK__FSK_Work_Order__c,FSSK__FSK_Work_Order__r.Vendor__c,WorkTypeId,ServiceTerritoryId,ServiceTerritory.ParentTerritoryId 
            FROM    ServiceAppointment 
            WHERE   ServiceTerritoryId = :pst1.Id
        ];

        for (ServiceTerritory serviceTerritory : cst) {
            serviceTerritory.IsActive = false;
        }
        update cst;

        PV_AssignChildTerritoryBatch ba = new PV_AssignChildTerritoryBatch();
        Id jobId = Database.executeBatch(ba, 20);
        Test.stopTest();

        List<ServiceAppointment> appointmentsWithParentTerritory = [
            SELECT  Id
            FROM    ServiceAppointment
            WHERE   ServiceTerritory.ParentTerritoryId = null
        ];
        Assert.areNotEqual(0, appointmentsWithParentTerritory.size(), 'At least one SA had to stay with Parent Territory');
    }

    @isTest
    static void executeWithSpecificAppointmentIdsTest() {
        Test.startTest();
        
        ServiceTerritory parentServiceTerritory = [SELECT Id,Name FROM ServiceTerritory WHERE Name = 'ST-0001'];
        List<ServiceAppointment> serviceAppointmentList = [
            SELECT  Id
            FROM    ServiceAppointment 
            WHERE   ServiceTerritoryId = :parentServiceTerritory.Id
        ];
        
        List<Id> serviceAppointmentIds = new List<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointmentList) {
            serviceAppointmentIds.add(serviceAppointment.Id);
        }
        
        PV_AssignChildTerritoryBatch batch = new PV_AssignChildTerritoryBatch(serviceAppointmentIds);
        Id jobId = Database.executeBatch(batch, 20);
        Test.stopTest();
    }

    @isTest
    static void startAssignChildTerritoryBatchTest() {
        Test.startTest();
        ServiceTerritory parentServiceTerritory = [SELECT Id,Name FROM ServiceTerritory WHERE Name = 'ST-0001'];
        List<ServiceAppointment> serviceAppointmentList = [
            SELECT  Id
            FROM    ServiceAppointment 
            WHERE   ServiceTerritoryId = :parentServiceTerritory.Id
            LIMIT   2
        ];
        
        List<PV_AssignChildTerritoryBatchAction.Request> requests = new List<PV_AssignChildTerritoryBatchAction.Request>();
        
        for (ServiceAppointment serviceAppointment : serviceAppointmentList) {
            PV_AssignChildTerritoryBatchAction.Request request = new PV_AssignChildTerritoryBatchAction.Request();
            request.serviceAppointmentId = serviceAppointment.Id;
            requests.add(request);
        }
        
        PV_AssignChildTerritoryBatchAction.startAssignChildTerritoryBatch(requests);
        Test.stopTest();
    }

    @isTest
    static void startAssignChildTerritoryBatchNullValuesTest() {
        Test.startTest();
        PV_AssignChildTerritoryBatchAction.startAssignChildTerritoryBatch(null);
        PV_AssignChildTerritoryBatchAction.startAssignChildTerritoryBatch(new List<PV_AssignChildTerritoryBatchAction.Request>());
        
        List<PV_AssignChildTerritoryBatchAction.Request> nullRequests = new List<PV_AssignChildTerritoryBatchAction.Request>();
        PV_AssignChildTerritoryBatchAction.Request nullRequest = new PV_AssignChildTerritoryBatchAction.Request();
        nullRequest.serviceAppointmentId = null;
        nullRequests.add(nullRequest);
        PV_AssignChildTerritoryBatchAction.startAssignChildTerritoryBatch(nullRequests);
        Test.stopTest();
    }
}