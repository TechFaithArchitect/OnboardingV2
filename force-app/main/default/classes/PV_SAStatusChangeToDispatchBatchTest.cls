@isTest
public class PV_SAStatusChangeToDispatchBatchTest {
    public static Integer numberOfRecords = 100;

    @testSetup
    static void testData() {
        Account acct = PV_TestDataFactory.createAccount('TestAcc', true);
        Contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acct);
        
        OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true,'ST-01',opHrs);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true,acct,pst);

        User usr;
        System.runAs(new User(Id = Userinfo.getUserId())) {
            usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true,usr,'FSL_Technician');
        }
        
        ServiceResource sr = PV_TestDataFactory.createServiceResource(true,acct,con,usr);
        ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,sr,childServiceTerritory,'P');
        WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill',true);

        WorkOrder wo = new WorkOrder();
        wo.Status = 'Unscheduled';
        wo.OwnerId = usr.Id;
        wo.WorkTypeId = wt.Id;
        wo.Vendor__c = 'T-Mobile';
        insert wo;
        
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        
        for (Integer i = 1; i <= numberOfRecords; i++) {
            ServiceAppointment saTest = new ServiceAppointment();
            saTest.Description = 'TestingSA' + i;
            saTest.ParentRecordId = wo.Id;
            saTest.FSSK__FSK_Work_Order__c = wo.Id;
            saTest.ServiceTerritoryId = pst.Id;
            saTest.WorkTypeId = wt.Id;
            saTest.Status = 'Scheduled';
            saTest.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
            saTest.SchedStartTime = System.now();
            saTest.SchedEndTime = System.now().addHours(2);
            saTest.DueDate = System.today().adddays(2);
            saList.add(saTest);
        }
        
        if (!saList.isEmpty()) {
            insert saList;
        }
    }

    @isTest
    static void testBatch() {
        Test.startTest();
        PV_SAStatusChangeToDispatchBatch batchInstance = new PV_SAStatusChangeToDispatchBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();

        List<ServiceAppointment> serviceAppointments = [SELECT Id, Status FROM ServiceAppointment WHERE Status = 'Dispatched'];
        Assert.areEqual(
            numberOfRecords,
            serviceAppointments.size(),
            'testBatch: The number of ServiceAppointment records with status "Dispatched" does not match the expected value.'
        );
    }
    
    @isTest
    static void testBatchException() {
        PV_SAStatusChangeToDispatchBatch.throwException = true;
        
        Test.startTest();
        PV_SAStatusChangeToDispatchBatch batchInstance = new PV_SAStatusChangeToDispatchBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT  Id, Type__c, Provider__c, Component__c, Error__c, CreatedDate
            FROM    Error_Log__c
            WHERE   Component__c = :PV_SAStatusChangeToDispatchBatch.class.getName()
        ];

        Assert.areNotEqual(0, errors.size(), 'testBatchException: Error logs were not created as expected.');
    }
}