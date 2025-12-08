@isTest
public class PV_ExceptionControllerTest {
    @testSetup
    static void testData() {
        Account acct = PV_TestDataFactory.createAccount('TestAcc', true);
        Contact con = PV_TestDataFactory.createContact('firstName', 'lastName', true, acct);
        
        OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01', opHrs);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acct, pst);
        
        User usr = PV_TestDataFactory.createTechnicianUser(true, con);

        System.runAs(usr) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }
        
        ServiceResource sr = PV_TestDataFactory.createServiceResource(true, acct, con, usr);
        sr.Manager__c = UserInfo.getUserId();
        update sr;
        
        ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true, sr, childServiceTerritory, 'P');
        WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill', true);
        WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr, wt, true);
        
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = wo.Id;
        sa.ServiceTerritoryId = pst.Id;
        sa.WorkTypeId = wt.Id;
        sa.Status = 'Scheduled';
        sa.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
        sa.SchedStartTime = System.now();
        sa.SchedEndTime = System.now().addHours(3);
        sa.DueDate = System.today().addDays(3);
        insert sa;
        
        Product2 prod = new Product2();
        prod.Name = 'Fisher';
        prod.Cost__c = 100;
        insert prod;
    }

    @isTest
    static void testSuccessScenarios() {
        Test.startTest();
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        FSL_AppUtils.ResponseWrapper response1 = PV_ExceptionController.getProducts();
        FSL_AppUtils.ResponseWrapper response2 = PV_ExceptionController.getVendorType(sa.Id);
        FSL_AppUtils.ResponseWrapper response3 = PV_ExceptionController.getSharinPixImage(sa.Id);
        Test.stopTest();

        Assert.areEqual('SUCCESS', response1.state, 'The state does not match');
        Assert.areEqual('SUCCESS', response2.state, 'The state does not match');
        Assert.areEqual('SUCCESS', response3.state, 'The state does not match');
    }

    @isTest
    static void testExceptionScenarios() {
        Test.startTest();
        FSL_AppUtils.ResponseWrapper response1;
        FSL_AppUtils.ResponseWrapper response2;
        FSL_AppUtils.ResponseWrapper response3;

        try {
            response1 = PV_ExceptionController.getProducts();
        } catch (Exception e) {
            response1 = new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
        Assert.areEqual('SUCCESS', response1.state, 'The state does not match');

        try {
            response2 = PV_ExceptionController.getVendorType(null);
        } catch (Exception e) {
            response2 = new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
        Assert.areEqual('ERROR', response2.state, 'The state does not match');

        try {
            response3 = PV_ExceptionController.getSharinPixImage(null);
        } catch (Exception e) {
            response3 = new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
        Assert.areEqual('ERROR', response3.state, 'The state does not match');
        
        Test.stopTest();
    }
}