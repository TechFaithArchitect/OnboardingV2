@isTest
public class PV_InventoryControllerTest {
    public static final String TEST_VENDOR = Label.DIRECTV;

    @TestSetup
    static void makeTestData() {
        Product2 pd1 = PV_TestDataFactory.createProduct(true,true,'Serialized Product');
        Product2 pd2 = PV_TestDataFactory.createProduct(true,true,'Serialized Product1');
        Product2 pd3 = PV_TestDataFactory.createProduct(true,false,'Non SZ Product 1');
        Product2 pd4 = PV_TestDataFactory.createProduct(true,false,'Non SZ Product 2');

        Account account = PV_TestDataFactory.createAccount('testProduct', true);
        Contact con = PV_TestDataFactory.createContact('Test', 'Hikko123', true, account);
        User user = PV_TestDataFactory.createTechnicianUser(true, con);

        Schema.Location loc1 = new Schema.Location(
            Name = 'Test Location 1',
            LocationType = 'Van',
            IsMobile = true,
            IsInventoryLocation = true
        );
        insert loc1;

        Id dealerId = [SELECT Id FROM Account LIMIT 1].Id;
        WorkType workType = PV_TestDataFactory.createWorkType('Test Work Type', true);

        WorkOrder workOrder = new WorkOrder();
        workOrder.AccountId = dealerId;
        workOrder.Status = 'Unscheduled';
        workOrder.OwnerId = user.Id;
        workOrder.WorkTypeId = workType.Id;
        workOrder.Vendor__c = TEST_VENDOR;
        insert workOrder;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        serviceAppointment.Dealer__c = dealerId;
        update serviceAppointment;
    }

    @isTest
    static void getProductTest() {
        User u = [SELECT Id FROM User WHERE FirstName = 'Test_' LIMIT 1];
        System.RunAs(u) {
            Test.startTest();
            List<PV_InventoryController.SObjectResult> resultList = PV_InventoryController.getResults('Serialized Product1', 'Product2');
            Test.stopTest();
            Assert.areEqual(1, resultList.size(), 'Should have returned one result');
        }
    }

    @isTest
    static void getProductAdminTest() {
        Test.startTest();
        List<PV_InventoryController.SObjectResult> resultList = PV_InventoryController.getResults('Serialized Product1', 'Product2');
        Test.stopTest();
        Assert.areEqual(1, resultList.size(), 'Should have returned one result');
    }

    @isTest
    static void getLocationTest(){
        Test.startTest();
        List<PV_InventoryController.SObjectResult> resultList = PV_InventoryController.getResults('Test', 'Location');
        Test.stopTest();
        Assert.areEqual(1, resultList.size(), 'Should have returned one result');
    }

    @isTest
    static void userInformationTest(){
        Test.startTest();
        PV_InventoryController.UserInformation result = PV_InventoryController.getUserInformation();
        Test.stopTest();
        Assert.isFalse(result.isTechnician, 'The user should not be a technician');
    }

    @isTest
    static void serializedProductCheckTest(){
        Test.startTest();
        Boolean isSerialized = PV_InventoryController.serializedProductCheck([Select Id From Product2 where Name ='Serialized Product' limit 1].Id);
        Test.stopTest();
        Assert.isTrue(isSerialized, 'The product should be serialized');
    }

    @isTest
    static void addInventoryProductsTest(){
        String serializesPd1 = [Select Id From Product2 where Name ='Serialized Product' limit 1].Id;
        String serializesPd2 = [Select Id From Product2 where Name ='Serialized Product1' limit 1].Id;
        String nonSerializesPd1 = [Select Id From Product2 where Name ='Non SZ Product 1' limit 1].Id;
        String nonSerializesPd2 = [Select Id From Product2 where Name ='Non SZ Product 2' limit 1].Id;
        String locationId = [Select Id From Location where Name ='Test Location 1' limit 1].Id;
        string szpdtransfer = '[{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL3","Quantity":"","IsSerialized":true},{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL1","Quantity":"","IsSerialized":true},{"ProductId":\"'+serializesPd2+'\","SerialNumber":"KL2","Quantity":"","IsSerialized":true}]';
        string nonszpdtransfer = '[{"ProductId":\"'+nonSerializesPd1+'\","SerialNumber":"","Quantity":"10","IsSerialized":false},{"ProductId":\"'+nonSerializesPd1+'\","SerialNumber":"","Quantity":"10","IsSerialized":false},{"ProductId":\"'+nonSerializesPd2+'\","SerialNumber":"","Quantity":"20","IsSerialized":false}]';
        string szpdtransfer1 = '[{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL4","Quantity":"","IsSerialized":true}]';

        Test.startTest();
        PV_InventoryController.addInventoryProducts(nonszpdtransfer,locationId);
        PV_InventoryController.addInventoryProducts(szpdtransfer,locationId);
        PV_InventoryController.addInventoryProducts(szpdtransfer1,locationId);
        Test.stopTest();    

        ProductItem pitem =  [SELECT id,Product2Id, QuantityOnHand from ProductItem where Product2Id = :serializesPd1];
        ProductItem pitem1 =  [SELECT id,Product2Id, QuantityOnHand from ProductItem where Product2Id = :nonSerializesPd1];
        Assert.areEqual(3, pitem.QuantityOnHand, 'The Quantity On Hand does not match');
        Assert.areEqual(20, pitem1.QuantityOnHand, 'The Quantity On Hand does not match');
    }

    @isTest
    static void getScannerUrlsTest() {
        Test.startTest();
        Map<String, String> result = PV_InventoryController.getScannerUrls();
        Test.stopTest();

        Assert.areNotEqual(null, result, 'The returned map should not be null');
        Assert.isTrue(result.containsKey('communityUrl'), 'The map should contain the communityUrl key');
        Assert.isTrue(result.containsKey('internalUrl'), 'The map should contain the internalUrl key');
    }

    @isTest
    static void fetchProductsTest() {

        Product2 testProduct = [SELECT Id FROM Product2 WHERE IsActive = true AND FSL_Vendor__c = :TEST_VENDOR AND Name = 'Serialized Product' LIMIT 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = testProduct.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        List<Product2> result = PV_InventoryController.fetchProducts('Serial', TEST_VENDOR);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 product');
        Assert.areEqual(testProduct.Id, result[0].Id, 'Returned product should match test product');
    }
}