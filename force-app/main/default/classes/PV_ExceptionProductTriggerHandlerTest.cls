@isTest
public class PV_ExceptionProductTriggerHandlerTest {
    @TestSetup
    static void makeTestData() {
        Account acct = PV_TestDataFactory.createAccount('TestAcc', true);
        contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acct);
        
        OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acct, pst);
        User usr = PV_TestDataFactory.createTechnicianUser(true,con);

        System.runAs(usr) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }
        
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
        sa.DueDate = System.today().adddays(365);
        insert sa;
        
        Exception__c ex1 = new Exception__c();
        ex1.Dealer__c = acct.id;
        ex1.Customer__c = acct.Id;
        ex1.Approved__c = False;
        ex1.Service_Appointment__c=sa.Id;
        ex1.Type__c = 'Repair';
        insert ex1;
        
        Product2 prod = new Product2();
        prod.Name = 'Fisher';
        prod.Cost__c = 100;
        insert prod;
    }
    
    @isTest
    static void testData() {
        List<Account> acct1 = [SELECT Id FROM Account];
        List<ServiceAppointment> sa1 = [SELECT Id FROM ServiceAppointment];
        List<Exception__c>exp = [SELECT Id FROM Exception__c];
        List <Product2> product = [SELECT Id FROM Product2];
        Exception_Product__c expProducts = new Exception_Product__c();
        expProducts.Exception__c = exp[0].Id;
        expProducts.Product_del__c = product[0].Id;
        insert expProducts;
    }

    @isTest
    static void testData1() {
        try {
            List<Account> acct1 = [SELECT Id FROM Account];
            List<ServiceAppointment> sa1 = [SELECT Id FROM ServiceAppointment];
            List<Exception__c>exp = [SELECT Id FROM Exception__c];
            List <Product2> product = [SELECT Id FROM Product2];
            Exception_Product__c expProducts = new Exception_Product__c();
            insert expProducts;
        }
        catch (Exception ex) {
           // System.assertEquals('expected text', ex.getMessage());
        }
    }
}