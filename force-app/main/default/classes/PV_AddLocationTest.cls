@istest
public class PV_AddLocationTest {
    public static final String PV_BUSINESS_UNIT = System.Label.FSL_PV_Business_Unit;
    public static final String OTHER_BUSINESS_UNIT = 'Direct Connect Connections';

    @testSetup
    static void makeData() {
        Account acc = PV_TestDataFactory.createAccount('Test ABCD', true);
        Contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acc);

        User usr = PV_TestDataFactory.createTechnicianUser(true,con);
        System.runAs(usr){
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }

        ServiceResource sr = PV_TestDataFactory.createServiceResource(true,acc,con,usr);
    }
    
    @isTest
    public static void submitForApprovalTest() {
        Account acc = [SELECT Id, Business_Unit__c FROM Account LIMIT 1];
        acc.Business_Unit__c = PV_BUSINESS_UNIT;
        update acc;

        Contact con = [SELECT Id FROM Contact LIMIT 1];
        User usr = [SELECT Id FROM User LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

        Process_Approval__c pa = new Process_Approval__c();
        Id rtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Process_Approval__c' AND Name = 'Location Approval' LIMIT 1].Id;
        pa.RecordTypeId = rtId;
        pa.Location_Name__c = 'Test001Location';
        pa.Location_Type__c = 'Warehouse';
        pa.Account__c = acc.Id;
        pa.Inventory_Location__c = true;
        pa.Mobile_Location__c = false;
        insert pa;
        
        Schema.Location loct = new Schema.Location();
        loct.Name = 'Test001Location';
        loct.LocationType = 'Warehouse';
        loct.IsInventoryLocation = true;
        loct.Account__c = acc.Id;
        loct.IsMobile = false;
        insert loct;
        
        Process_Approval__c pa1 = new Process_Approval__c();
        Id rtpId = [SELECT Id FROM RecordType WHERE SobjectType = 'Process_Approval__c' AND Name = 'Location Approval' LIMIT 1].Id;
        pa1.RecordTypeId = rtpId;
        pa1.Location_Name__c = 'Test001Location';
        pa1.Location_Type__c = 'Warehouse';
        pa1.Account__c = acc.Id;
        pa1.Inventory_Location__c = true;
        pa1.Mobile_Location__c = false;
        insert pa1;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test002Location';
        loc.LocationType = 'Van';
        loc.IsInventoryLocation = true;
        loc.Account__c = acc.Id;
        loc.IsMobile = true;
        insert loc;
        
        Schema.Location locn = new Schema.Location();
        locn.Name = 'Test003Location';
        locn.LocationType = 'Van';
        locn.IsInventoryLocation = false;
        locn.Account__c = acc.Id;
        locn.IsMobile = false;
        insert locn;
        
        Test.startTest();
        PV_AddLocation.submitForLocationApproval('Test001Location','Warehouse', acc.Id,true,false, '');
        PV_AddLocation.submitForLocationApproval('Test002Location','Van', acc.Id,true,true, sr.Id);
        Test.stopTest();
        
        Boolean hasThrownException = false;
        try {
            PV_AddLocation.submitForLocationApproval('Test003Location','Van', acc.Id,false,false, sr.Id);
        } catch(Exception e) {
            hasThrownException = true;
        }
        Assert.isTrue(hasThrownException, 'Should have thrown an exception');
    }

    @isTest
    public static void createLocationRecordTest() {
        Account account = [SELECT Id, Business_Unit__c FROM Account LIMIT 1];
        account.Business_Unit__c = OTHER_BUSINESS_UNIT;
        update account;

        Test.startTest();
        PV_AddLocation.submitForLocationApproval('Location Name','Warehouse',account.Id,true,false,null);
        Test.stopTest();

        List<Schema.Location> locations = [SELECT Id FROM Location];
        Assert.areEqual(1, locations.size(), 'createLocationRecordTest: Unexpected number of Location records.');
    }

    @isTest
    public static void getServiceResourcesTest () {
        Account acc = PV_TestDataFactory.createAccount('Test ABCD', true);
        Contact con = PV_TestDataFactory.createContact('firstNamegetServiceResourcesTest', 'lastNamegetServiceResourcesTest',true,acc);
        User usr = PV_TestDataFactory.createTechnicianUser(false,con);
        usr.CommunityNickname = 'PV_AddLocationTest_User';
        insert usr;
        System.runAs(usr){
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }
        ServiceResource sr = PV_TestDataFactory.createServiceResource(true,acc,con,usr);
        Test.startTest();
        List<PV_AddLocation.ResourceWrapper> result = PV_AddLocation.getServiceResources(acc.Id);
        Test.stopTest();
        
        Assert.areEqual(2, result.size(), 'the service resources were pulled incorrectly');
    }
}