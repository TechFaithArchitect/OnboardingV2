@isTest
public class FSL_NonSerializedCompControllerTest {
    
    @TestSetup
    static void makeData() {
        Account account = PV_TestDataFactory.createAccount('TestAcc', true);
        contact contact = PV_TestDataFactory.createContact('firstName', 'lastName', true, account);
        
        OperatingHours operatingHours = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        ServiceTerritory parentServiceTerritory = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01', operatingHours);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, account, parentServiceTerritory);
        User user = PV_TestDataFactory.createTechnicianUser(true, contact);

        System.runAs(user) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, user, 'FSL_Technician');
        }
        
        ServiceResource serviceResource = PV_TestDataFactory.createServiceResource(true, account, contact, user);
        serviceResource.Manager__c = UserInfo.getUserId();
        update serviceResource;
        
        ServiceTerritoryMember serviceTerritoryMember = PV_TestDataFactory.createServiceTerritoryMember(true, serviceResource, childServiceTerritory, 'P');

        WorkType workType = new WorkType();
        workType.Name = 'Cable Construction';
        workType.DurationType = 'Minutes';
        workType.EstimatedDuration = 60;
        workType.Vendor__c = 'WOW';
        insert workType;
        
        WorkOrder workOrder = new WorkOrder();
        workOrder.Status = 'Onsite';
        workOrder.WorkTypeId = workType.Id;
        workOrder.Vendor__c = 'WOW';
        insert workOrder;

        ServiceAppointment serviceAppointment = new ServiceAppointment();
        serviceAppointment.Status = 'Onsite';
        serviceAppointment.ParentRecordId = workOrder.Id;
        serviceAppointment.FSSK__FSK_Work_Order__c = workOrder.Id;
        serviceAppointment.WorkTypeId = workType.Id;
        serviceAppointment.SchedStartTime = System.Today();
        serviceAppointment.SchedEndTime = System.now().addHours(3);
        serviceAppointment.DueDate = System.today().adddays(4);
        serviceAppointment.EarliestStartTime = System.now();
        insert serviceAppointment;

        Product2 product1 = PV_TestDataFactory.createProduct(true, true, 'Serialized Product');
        Product2 product2 = PV_TestDataFactory.createProduct(true, true, 'Serialized Product1');
        Product2 product3 = PV_TestDataFactory.createProduct(true, false, 'Non Serialized Product 1');
        Product2 product4 = PV_TestDataFactory.createProduct(true, false, 'Non Serialied Product 2');

        serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];

        Schema.Location location = new Schema.Location(
            Name = 'Test Location 1',
            LocationType = 'Van',
            IsMobile = true,
            IsInventoryLocation = true,
            Service_Resource__c = serviceResource.Id
        );
        insert location;

        List<ProductItem> productItemList = new List<ProductItem>();
        productItemList.add(new ProductItem(Product2Id = product3.Id, LocationId = location.Id, QuantityOnHand = 100));
        productItemList.add(new ProductItem(Product2Id = product4.Id, LocationId = location.Id, QuantityOnHand = 100));
        insert productItemList;

        AssignedResource assignedResource = new AssignedResource(
            ServiceResourceId = serviceResource.Id,
            ServiceAppointmentId = serviceAppointment.Id
        );
        insert assignedResource;
    }

    @isTest
    static void testConsumeNonSerializedProducts() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Schema.Location location = [SELECT Id FROM Location LIMIT 1];

        List<ProductItem> productItemList = [SELECT Product2Id FROM ProductItem WHERE LocationId = :location.Id];
        List<FSL_NonSerializedCompController.ProductItemWrapper> wrapperList = new List<FSL_NonSerializedCompController.ProductItemWrapper>();
        
        for (ProductItem productItem : productItemList) {
            FSL_NonSerializedCompController.ProductItemWrapper wrapper = new FSL_NonSerializedCompController.ProductItemWrapper();
            wrapper.productId = productItem.Product2Id;
            wrapper.quantity = '2';
            wrapperList.add(wrapper);
        }

        Map<String, Object> formData = new Map<String, Object>{
            'Id' => workOrder.Id
        };

        Test.startTest();
        FSL_NonSerializedCompController.consumeNonSerializedProducts(formData, JSON.serialize(wrapperList), location.Id);
        Test.stopTest();

        List<ProductConsumed> consumedList = [SELECT QuantityConsumed FROM ProductConsumed WHERE WorkOrderId = :workOrder.Id];
        Assert.areEqual(wrapperList.size(), consumedList.size(), 'All products should be consumed.');
        Assert.areEqual(2, consumedList[0].QuantityConsumed, 'Quantity should match wrapper input.');
    }

    @isTest
    static void testGetProductDetails() {
        Product2 product = [SELECT Id FROM Product2 WHERE IsActive = true AND IsSerialized = false LIMIT 1];

        Test.startTest();
        Product2 result = FSL_NonSerializedCompController.getProductDetails(product.Id);
        Test.stopTest();

        Assert.areEqual(product.Id, result.Id, 'The product does not match');
    }

    @isTest
    static void testUpdateWorkOrder() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];

        Map<String, Object> formData = new Map<String, Object>{
            'Id' => workOrder.Id,
            'signalLevel' => '55',
            'beginningTickMark' => 'BTM1',
            'endTickMark' => 'ETM1',
            'cableValidation' => true,
            'conduitValidation' => false,
            'connectorValidation' => true
        };

        Test.startTest();
        FSL_NonSerializedCompController.updateWorkOrder(formData);
        Test.stopTest();

        WorkOrder updatedWorkOrder = [
            SELECT
                Signal_Level__c, Beginning_Tick_Mark__c, End_Tick_Mark__c, Cable_and_Equipment_Check__c, 
                Cable_Conduit_Aesthetic_Check__c, Connector_and_Equipment_Attachment_Check__c
            FROM    WorkOrder
            WHERE   Id = :workOrder.Id
        ];

        Assert.areEqual('55', updatedWorkOrder.Signal_Level__c, 'The Signal Level does not match');
        Assert.areEqual('BTM1', updatedWorkOrder.Beginning_Tick_Mark__c, 'The Beginning Tick Mark does not match');
        Assert.areEqual('ETM1', updatedWorkOrder.End_Tick_Mark__c, 'The End Tick Mark does not match');
        Assert.areEqual(true, updatedWorkOrder.Cable_and_Equipment_Check__c, 'The Cable and Equipment Check does not match');
        Assert.areEqual(false, updatedWorkOrder.Cable_Conduit_Aesthetic_Check__c, 'The Cable Conduit Aesthetic Check does not match');
        Assert.areEqual(true, updatedWorkOrder.Connector_and_Equipment_Attachment_Check__c, 'The Connector and Equipment Attachment Check does not match');
    }
}