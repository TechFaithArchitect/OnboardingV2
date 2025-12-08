@isTest
public class PV_CustomChargeControllerTest {
    public static final String FSL_VENDOR = 'COSTCO';
    public static final String DEALER_RECORD_TYPE = 'POE_Dealer';

    @testSetup
    static void makeTestData() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            RecordType dealerRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = :DEALER_RECORD_TYPE AND SObjectType = 'Account'];
            Account account = new Account();
            account.Name = 'TestAcc';
            account.Available_FSL_Vendors__c = FSL_VENDOR;
            account.RecordTypeId = dealerRecordType.Id;
            insert account;

            contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,account);            
            OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, account, pst);
            
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            
            ServiceResource sr = PV_TestDataFactory.createServiceResource(true,account,con,usr);
            sr.Manager__c = UserInfo.getUserId();
            update sr;
            
            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,sr,childServiceTerritory,'P');
            WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill',true);

            WorkOrder workOrder = new WorkOrder();
            workOrder.Status = 'Unscheduled';
            workOrder.OwnerId = usr.Id;
            workOrder.WorkTypeId = wt.Id;
            workOrder.Vendor__c = FSL_Vendor;
            insert workOrder;
   
            ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
            serviceAppointment.Status = 'Scheduled';
            serviceAppointment.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
            serviceAppointment.SchedStartTime = System.now();
            serviceAppointment.SchedEndTime = System.now().addHours(3);
            serviceAppointment.DueDate = System.today().adddays(-3);
            serviceAppointment.Dealer__c = account.Id;
            update serviceAppointment;
            
            CustomCharge_Products__c custProd = new CustomCharge_Products__c();
            custProd.Name = 'Fisher';
            custProd.Price__c = 100;
            custProd.Vendor__c = FSL_VENDOR;
            insert custProd;
        }
    }
    
    @isTest
    static void getPrice() {
        Test.startTest();
        CustomCharge_Products__c custProd = [SELECT Name, Id,Price__c FROM CustomCharge_Products__c];
        List<ServiceAppointment> sa = [SELECT Id FROM ServiceAppointment];
        PV_CustomChargeController.getAllProducts();
        PV_CustomChargeController.getProductPrice();
        PV_CustomChargeController.getCustomCharge(sa[0].id);
        PV_CustomChargeController.getSAAmount(sa[0].id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetVendors() {
        Test.startTest();
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        FSL_AppUtils.ResponseWrapper result;

        result = PV_CustomChargeController.getVendors(serviceAppointment.Id);
        Test.stopTest();

        Assert.areEqual(true, result.state != null);
    }    
}