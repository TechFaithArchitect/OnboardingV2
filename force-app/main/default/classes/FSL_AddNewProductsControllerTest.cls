@IsTest
public class FSL_AddNewProductsControllerTest {

    @TestSetup
    static void setupTestData() {

            Account acc = PV_TestDataFactory.createAccount('testProduct', true);
            Contact con = PV_TestDataFactory.createContact('Test', 'Hikko123', true, acc);

            User u = PV_TestDataFactory.createTechnicianUser(false, con);
            u.IsActive = true;
            u.ProfileId = [Select Id from profile where Name='External Partner - DCC'].Id;

            insert u;

            System.runAs(u) {
                PV_TestDataFactory.assignPermissionSetGroupToUser(true, u, 'FSL_Dispatcher_and_Technician');

                PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
                permissionSetAssignment.AssigneeId = u.Id;
                permissionSetAssignment.PermissionSetId = [SELECT Id,Name FROM PermissionSet where Name = 'DCC_Service_Resource'].Id;
                insert permissionSetAssignment;
            }

            ServiceResource sr = new ServiceResource(
                Name = 'Test Service Resource',
                RelatedRecordId = u.Id
            );
            insert sr;

            Schema.Location loc = new Schema.Location(
                Name = 'FSL Test Location',
                Service_Resource__c = sr.Id,
                IsInventoryLocation = true,
                IsMobile = true
            );
            insert loc;

            WorkOrder wo = new WorkOrder(
                Status = 'Unscheduled'
            );
            insert wo;

            OperatingHours op = new OperatingHours();
            op.Name = 'Test OH';
            insert op;
        
            ServiceTerritory st = new ServiceTerritory();
            st.Name = 'Test SA';
            st.OperatingHoursId = op.Id;
            st.IsActive = true;
            insert st;

            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = wo.Id,
                FSSK__FSK_Assigned_Service_Resource__c = sr.Id,
                SchedStartTime = System.today().adddays(1),
                SchedEndTime = System.today().adddays(2)
            );
            insert sa;

            Product2 prod = new Product2(
                Name = 'Test Product',
                ProductCode = 'TP123',
                IsActive = true,
                FSL_Product__c = true,
                FSL_Vendor__c = 'DIRECTV',
                IsSerialized = true
            );
            insert prod;

            ProductRequired pr = new ProductRequired(
                ParentRecordId = wo.Id,
                Product2Id = prod.Id,
                QuantityRequired = 5
            );
            insert pr;

            ProductItem pi = new ProductItem(
                Product2Id = prod.Id,
                LocationId = loc.Id,
                QuantityOnHand = 0
            );
            insert pi;

            SerializedProduct sp = new SerializedProduct(
                Product2Id = prod.Id,
                ProductItemId = pi.Id,
                SerialNumber = 'SP123'
            );
            insert sp;
    }

    @IsTest
    static void testGetRequiredProducts() {

        User u = [SELECT Id FROM User WHERE FirstName = 'Test_' LIMIT 1];
        
        Date selectedDate = Date.today();
        
        System.runAs(u) {
            Test.startTest();
            FSL_AppUtils.ResponseWrapper products = FSL_AddNewProductsController.getRequiredProducts(selectedDate);
            Assert.isNotNull(products.state, 'The state should be set');
            Test.stopTest();
        }
    }

    @IsTest
    static void testAddProductToLocation() {

        User u = [SELECT Id FROM User WHERE FirstName = 'Test_' LIMIT 1];
       
        ProductRequired pr = [SELECT Product2Id FROM ProductRequired LIMIT 1];
        Map<String, Object> selectedProduct = new Map<String, Object>{
            'productid' => pr.Product2Id,
            'isSerialized' => true
        };

        String serialCode = 'SP_NEW';

        System.runAs(u) {
            Test.startTest();
            FSL_AddNewProductsController.addProductToLocation(selectedProduct, serialCode);
            List<SerializedProduct> serializedProducts = [SELECT SerialNumber FROM SerializedProduct WHERE SerialNumber = :serialCode];
            System.assertEquals(1, serializedProducts.size(), 'Serialized product should be created');
            Test.stopTest();
        }
    }

    @IsTest
    static void testAddProductToLocationWithoutItems() {
        Test.startTest();

        List<ProductItem> items = [SELECT Id FROM ProductItem];
        delete items;

        User u = [SELECT Id FROM User WHERE FirstName = 'Test_' LIMIT 1];
        ProductRequired pr = [SELECT Product2Id FROM ProductRequired LIMIT 1];

        Map<String, Object> selectedProduct = new Map<String, Object>{
            'productid' => pr.Product2Id,
            'isSerialized' => true
        };

        String serialCode = 'SP_NEW';

        System.runAs(u) {
            FSL_AddNewProductsController.addProductToLocation(selectedProduct, serialCode);
        }

        Test.stopTest();
        List<SerializedProduct> serializedProducts = [SELECT SerialNumber FROM SerializedProduct WHERE SerialNumber = :serialCode];
        System.assertEquals(1, serializedProducts.size(), 'Serialized product should be created');
    }

    @IsTest
    static void testAddProductToLocationDuplicateException() {
        Test.startTest();

        List<ProductItem> items = [SELECT Id FROM ProductItem];
        delete items;

        User u = [SELECT Id FROM User WHERE FirstName = 'Test_' LIMIT 1];
        ProductRequired pr = [SELECT Product2Id FROM ProductRequired LIMIT 1];

        Map<String, Object> selectedProduct = new Map<String, Object>{
            'productid' => pr.Product2Id,
            'isSerialized' => true
        };

        String serialCode = 'SP_NEW';

        System.runAs(u) {
            FSL_AddNewProductsController.addProductToLocation(selectedProduct, serialCode);
            FSL_AddNewProductsController.addProductToLocation(selectedProduct, serialCode);
        }

        Test.stopTest();
    }
}