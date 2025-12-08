@isTest
public class ReturnProductControllerTest {
    
    @testSetup
    static void setupTestData() {
       
        Product2 testProduct = new Product2(Name = 'Test Product', IsSerialized = true);
        insert testProduct;

        WorkOrder wo = new WorkOrder();
        wo.Subject = 'Test WO';
        wo.Vendor__c = 'T-Mobile';
        insert wo;

        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Schema.Location testLocation = new Schema.Location();
        testLocation.Name = 'Test Location';
        testLocation.IsInventoryLocation = true;
        testLocation.IsMobile = true;
        insert testLocation;

        ServiceResource testServiceResource = new ServiceResource(
            Name = 'Test Service Resource',
            RelatedRecordId = testUser.Id,
            LocationId = testLocation.Id
        );
        insert testServiceResource; 
    }

    @isTest
    static void testReturnProduct() {
        
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();

        ReturnProductController.returnProduct(
            'Test Product',
            'SN123456',
            'Damaged',
            testWorkOrder.Id,
            null
        );
        
        Test.stopTest();

        ReturnOrder createdReturnOrder = [SELECT Id, Status FROM ReturnOrder LIMIT 1];
        System.assertNotEquals(null, createdReturnOrder, 'ReturnOrder should be created');
        System.assertEquals('Submited', createdReturnOrder.Status, 'ReturnOrder status should be "Submitted"');
    }
}