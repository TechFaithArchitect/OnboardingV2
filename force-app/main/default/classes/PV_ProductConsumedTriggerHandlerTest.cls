@isTest
public class PV_ProductConsumedTriggerHandlerTest {
    @TestSetup
    static void makeTestData() {
        Id recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account pAcc = new Account();
        pAcc.FirstName = 'Test';
        pAcc.LastName = 'Person Account';
        pAcc.RecordTypeID = recordTypeId;
        insert pAcc;
        
        Account acc= PV_TestDataFactory.createAccount('Test Account', true);        
        contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc);
        User usr = PV_TestDataFactory.createTechnicianUser(true,con);

        System.runAs(new User(Id = UserInfo.getUserId())){
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }

        WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill',true);
        WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);
        wo.AccountId = pAcc.Id;
        update wo;
        
        Product2 pdt = new Product2();
        pdt.Name = 'Test Product';
        pdt.IsActive = True;
        insert pdt;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test001Location';
        loc.LocationType = 'Warehouse';
        loc.IsInventoryLocation = true;
        loc.Account__c = acc.Id;
        loc.IsMobile = true;
        insert loc;

        ServiceResource sr = new ServiceResource();
        sr.Name = 'Test';
        sr.IsActive = TRUE;
        sr.RelatedRecordId = usr.Id;
        sr.Contact__c = con.Id;
        sr.AccountId = acc.Id;
        sr.ResourceType = 'T';
        sr.LocationId = loc.Id;
        insert sr;

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment];
        sa.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
        sa.FSSK__FSK_Work_Order__c = wo.Id;
        update sa;

        ProductItem	pdtItem = new ProductItem();
        pdtItem.Product2Id =pdt.Id;
        pdtItem.LocationId = loc.Id;
        pdtItem.QuantityOnHand = 5;
        insert pdtItem;
        
        ProductConsumed pc = new ProductConsumed();
        pc.WorkOrderId = wo.Id;
        pc.ProductItemId = pdtItem.Id;
        pc.QuantityConsumed = 1;
        insert pc;
        
    }
    
    @isTest
    static void createAssetTest() {
        ProductConsumed pc = [SELECT Id, WorkOrderId, ProductItemId, QuantityConsumed FROM ProductConsumed WHERE QuantityConsumed = 1 LIMIT 1];
        Map<Id, ProductConsumed> pcMap = new Map<Id, ProductConsumed>{pc.Id => pc};
            PV_ProductConsumedTriggerHandler.createAsset(pcMap);
    }
}