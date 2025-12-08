@isTest(seeAllData=true)
public class BrightspeedOrderStatusTest {
    // Mock HTTP callout
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"messageStatus":[{"statusCode":"200","internalStatusCode":"","statusMessage":"","timestamp":"2024-12-16 12:03:05"}],' +
                '"transactionId":"PXOS-33311501-0293-4a1f-9fde-8822725e9f6a",' +
                '"orderCount":"2",' +
                '"partnerOrderStatus":[{"orderDetailAndCustomerInfo":[{' +
                '"partnerOrderId":"2c1bc1a6-a941-4eba-8a2b-58b640ea6355",' +
                '"partnerReferenceId":"123987546",' +
                '"partnerId":"BS223150",' +
                '"salesCode":"20000859",' +
                '"agentId":"agentinfohere",' +
                '"ACSID":"38973khjhjk",' +
                '"TFN":"18005551212",' +
                '"customerInfo":{"customerName":"firstname lastname","contactNumber":"5553211212","emailAddress":"none@gmail.com","serviceAddress":{"streetAddress":"801 LAKE AVE E","unit":"","city":"LADYSMITH","stateCode":"WI","zipCode":"54848"}},' +
                '"order":{"orderCreateDate":"2024-12-09 15:42:47","orderStatusDate":"12/12/2024","orderStatusSourceSystem":"partner","orderStatus":"Completed","orderDueDate":"12/12/2024","actualInstallationDate":"12/14/2024","accountNumber":"200238909","orderNumber":"WI1100003744","voiceTN":"5555551212","dslMigrator":false,' +
                '"orderLineItems":[{"productFamilyName":"BrightSpeed Internet","quantity":1,"productName":"BrightSpeed Internet 1 Gig","compCode":"HSI 1G","status":"Completed","action":"I"},' +
                '{"productFamilyName":"BrightSpeed Voice","quantity":1,"productName":"Digital Voice Standard","compCode":"VOIP","status":"Canceled","action":"O"},' +
                '{"productFamilyName":"BrightSpeed Add-ons","quantity":1,"productName":"Brightspeed Total Home Tech Support","compCode":"BRSPD THTS","status":"Completed","action":"I"}]}}' +
                ',{' +
                '"partnerOrderId":"2c1bc1a6-a941-4eba-8a2b-58b640ea6355",' +
                '"partnerReferenceId":"123987546",' +
                '"partnerId":"BS223150",' +
                '"salesCode":"20000859",' +
                '"agentId":"agentinfohere",' +
                '"ACSID":"38973khjhjk",' +
                '"TFN":"18005551212",' +
                '"customerInfo":{"customerName":"firstname lastname","contactNumber":"5553211313","emailAddress":"none2@gmail.com","serviceAddress":{"streetAddress":"2501 LAKE AVE E","unit":"","city":"LADYSMITH","stateCode":"WI","zipCode":"54848"}},' +
                '"order":{"orderCreateDate":"2024-12-10 15:42:47","orderStatusDate":"12/13/2024","orderStatusSourceSystem":"partner","orderStatus":"Completed","orderDueDate":"12/12/2024","actualInstallationDate":"12/12/2024","accountNumber":"200284035","orderNumber":"WI1100005241","voiceTN":"5555551313","dslMigrator":false,' +
                '"orderLineItems":[{"productFamilyName":"BrightSpeed Internet","quantity":1,"productName":"BrightSpeed Internet 2 Gig","compCode":"HSI 1G","status":"Completed","action":"I"},' +
                '{"productFamilyName":"BrightSpeed Voice","quantity":1,"productName":"Digital Voice Standard","compCode":"VOIP","status":"Canceled","action":"O"}]}}' +
                ']}]}'
            );
            return res;
        }
    }

    @isTest
    static void testOrderStatusSync() {
        // Setup test data
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Activate Standard Price Book for test context
        Pricebook2 standardPb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        System.debug('Queried Standard Price Book: Id=' + standardPb.Id + ', IsActive=' + standardPb.IsActive);
        System.assertNotEquals(null, standardPb, 'Standard Price Book not found!');
        if (!standardPb.IsActive) {
            standardPb.IsActive = true;
            update standardPb;
            System.debug('Standard Price Book activated.');
        }
        System.assertEquals(true, standardPb.IsActive, 'Standard Price Book is not active!');

        Date today = Date.today();
        List<Order> orders = new List<Order>{
            new Order(
                Name = 'Order 1',
                Status = 'Draft',
                POE_OrderNumber__c = 'WI1100003744',
                AccountId = acct.Id,
                EffectiveDate = today,
                Pricebook2Id = standardPb.Id
            ),
            new Order(
                Name = 'Order 2',
                Status = 'Draft',
                POE_OrderNumber__c = 'WI1100005241',
                AccountId = acct.Id,
                EffectiveDate = today,
                Pricebook2Id = standardPb.Id
            )
        };
        insert orders;
        System.debug('Inserted Orders: ' + orders);
        for (Order o : orders) {
            System.debug('Order Id=' + o.Id + ', Pricebook2Id=' + o.Pricebook2Id);
            System.assertNotEquals(null, o.Pricebook2Id, 'Order Pricebook2Id is null for order: ' + o.Id);
        }

        // Create Products and PricebookEntries for each unique component_code__c
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'HSI 1G', IsActive = true),
            new Product2(Name = 'VOIP', IsActive = true),
            new Product2(Name = 'BRSPD THTS', IsActive = true)
        };
        insert products;

        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Product2 p : products) {
            entries.add(
                new PricebookEntry(Product2Id = p.Id, Pricebook2Id = standardPb.Id, UnitPrice = 100, IsActive = true)
            );
        }
        insert entries;

        Map<String, Id> pbeMap = new Map<String, Id>();
        for (PricebookEntry pbe : entries) {
            pbeMap.put(pbe.Product2.Name, pbe.Id);
        }

        // Improved mapping: query back to ensure all fields are populated
        Map<Id, String> productIdToName = new Map<Id, String>();
        for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Id IN :products]) {
            productIdToName.put(p.Id, p.Name);
        }
        pbeMap.clear();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :productIdToName.keySet() AND Pricebook2Id = :standardPb.Id
        ]) {
            pbeMap.put(productIdToName.get(pbe.Product2Id), pbe.Id);
        }
        System.debug('pbeMap after query: ' + pbeMap);

        // Defensive checks
        System.assertNotEquals(null, pbeMap.get('HSI 1G'), 'HSI 1G PricebookEntryId should not be null');
        System.assertNotEquals(null, pbeMap.get('VOIP'), 'VOIP PricebookEntryId should not be null');
        System.assertNotEquals(null, pbeMap.get('BRSPD THTS'), 'BRSPD THTS PricebookEntryId should not be null');

        List<OrderItem> items = new List<OrderItem>{
            // Order 1
            new OrderItem(
                OrderId = orders[0].Id,
                Quantity = 1,
                PricebookEntryId = pbeMap.get('HSI 1G'),
                component_code__c = 'HSI 1G',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            ),
            new OrderItem(
                OrderId = orders[0].Id,
                Quantity = 1,
                PricebookEntryId = pbeMap.get('VOIP'),
                component_code__c = 'VOIP',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            ),
            new OrderItem(
                OrderId = orders[0].Id,
                Quantity = 1,
                PricebookEntryId = pbeMap.get('BRSPD THTS'),
                component_code__c = 'BRSPD THTS',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            ),
            // Order 2
            new OrderItem(
                OrderId = orders[1].Id,
                Quantity = 1,
                PricebookEntryId = pbeMap.get('HSI 1G'),
                component_code__c = 'HSI 1G',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            ),
            new OrderItem(
                OrderId = orders[1].Id,
                Quantity = 1,
                PricebookEntryId = pbeMap.get('VOIP'),
                component_code__c = 'VOIP',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            )
        };
        insert items;

        // Register mock
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Call the invocable method instead of directly enqueuing the queueable
        BrightspeedOrderStatusAction.startOrderStatusSync(new List<Integer>{ 60 });
        Test.stopTest();

        // Debug orders after queueable runs and use for assertions
        List<Order> updatedOrders = [SELECT Id, Status, POE_OrderNumber__c FROM Order WHERE Id IN :orders];
        for (Order o : updatedOrders) {
            System.debug(
                'Order after queueable: Id=' +
                o.Id +
                ', POE_OrderNumber__c=' +
                o.POE_OrderNumber__c +
                ', Status=' +
                o.Status
            );
        }
        System.assertEquals('Activated', updatedOrders[0].Status, 'Order 1 status should be updated');
        System.assertEquals('Activated', updatedOrders[1].Status, 'Order 2 status should be updated');

        Map<String, OrderItem> itemMap = new Map<String, OrderItem>();
        for (OrderItem oi : [
            SELECT Id, OrderId, component_code__c, POE_Status__c
            FROM OrderItem
            WHERE OrderId IN :orders
        ]) {
            itemMap.put(oi.OrderId + ':' + oi.component_code__c, oi);
        }
        // Order 1
        System.assertEquals(
            'Activated',
            itemMap.get(orders[0].Id + ':HSI 1G').POE_Status__c,
            'Order 1 HSI 1G should be Activated'
        );
        System.assertEquals(
            'Canceled',
            itemMap.get(orders[0].Id + ':VOIP').POE_Status__c,
            'Order 1 VOIP should be Canceled'
        );
        System.assertEquals(
            'Activated',
            itemMap.get(orders[0].Id + ':BRSPD THTS').POE_Status__c,
            'Order 1 BRSPD THTS should be Activated'
        );
        // Order 2
        System.assertEquals(
            'Activated',
            itemMap.get(orders[1].Id + ':HSI 1G').POE_Status__c,
            'Order 2 HSI 1G should be Activated'
        );
        System.assertEquals(
            'Canceled',
            itemMap.get(orders[1].Id + ':VOIP').POE_Status__c,
            'Order 2 VOIP should be Canceled'
        );
    }

    @isTest
    static void testOrderStatusSyncWithMissingOrder() {
        // Setup test data - only create one order, leave the other missing to test behavior
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Activate Standard Price Book for test context
        Pricebook2 standardPb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        if (!standardPb.IsActive) {
            standardPb.IsActive = true;
            update standardPb;
        }

        Date today = Date.today();
        // Only create one order - WI1100003744 exists, WI1100005241 will be missing
        List<Order> orders = new List<Order>{
            new Order(
                Name = 'Order 1',
                Status = 'Draft',
                POE_OrderNumber__c = 'WI1100003744',
                AccountId = acct.Id,
                EffectiveDate = today,
                Pricebook2Id = standardPb.Id
            )
        };
        insert orders;

        // Create Products and PricebookEntries
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'HSI 1G', IsActive = true),
            new Product2(Name = 'VOIP', IsActive = true),
            new Product2(Name = 'BRSPD THTS', IsActive = true)
        };
        insert products;

        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Product2 p : products) {
            entries.add(
                new PricebookEntry(Product2Id = p.Id, Pricebook2Id = standardPb.Id, UnitPrice = 100, IsActive = true)
            );
        }
        insert entries;

        // Create OrderItems for the existing order
        Map<String, Id> pbeMap = new Map<String, Id>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :products AND Pricebook2Id = :standardPb.Id
        ]) {
            pbeMap.put(pbe.Product2Id, pbe.Id);
        }

        List<OrderItem> items = new List<OrderItem>{
            new OrderItem(
                OrderId = orders[0].Id,
                Quantity = 1,
                PricebookEntryId = pbeMap.get(products[0].Id),
                component_code__c = 'HSI 1G',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            ),
            new OrderItem(
                OrderId = orders[0].Id,
                Quantity = 1,
                PricebookEntryId = pbeMap.get(products[1].Id),
                component_code__c = 'VOIP',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            ),
            new OrderItem(
                OrderId = orders[0].Id,
                Quantity = 1,
                PricebookEntryId = pbeMap.get(products[2].Id),
                component_code__c = 'BRSPD THTS',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            )
        };
        insert items;

        // Register mock
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        BrightspeedOrderStatusAction.startOrderStatusSync(new List<Integer>{ 60 });
        Test.stopTest();

        // Verify the existing order was updated
        List<Order> updatedOrders = [SELECT Id, Status, POE_OrderNumber__c FROM Order WHERE Id IN :orders];
        System.assertEquals('Activated', updatedOrders[0].Status, 'Existing order status should be updated');
    }

    @isTest
    static void testOrderStatusSyncWithNullPartnerOrderId() {
        // Test behavior when partnerOrderId is null
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Activate Standard Price Book for test context
        Pricebook2 standardPb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        if (!standardPb.IsActive) {
            standardPb.IsActive = true;
            update standardPb;
        }

        Date today = Date.today();
        // Only create one order - WI1100003744 exists, WI1100005241 will be missing
        List<Order> orders = new List<Order>{
            new Order(
                Name = 'Order 1',
                Status = 'Draft',
                POE_OrderNumber__c = 'WI1100003744',
                AccountId = acct.Id,
                EffectiveDate = today,
                Pricebook2Id = standardPb.Id
            )
        };
        insert orders;

        // Create minimal products and order items for the existing order
        List<Product2> products = new List<Product2>{ new Product2(Name = 'HSI 1G', IsActive = true) };
        insert products;

        List<PricebookEntry> entries = new List<PricebookEntry>{
            new PricebookEntry(
                Product2Id = products[0].Id,
                Pricebook2Id = standardPb.Id,
                UnitPrice = 100,
                IsActive = true
            )
        };
        insert entries;

        List<OrderItem> items = new List<OrderItem>{
            new OrderItem(
                OrderId = orders[0].Id,
                Quantity = 1,
                PricebookEntryId = entries[0].Id,
                component_code__c = 'HSI 1G',
                POE_Status__c = 'Draft',
                UnitPrice = 100
            )
        };
        insert items;

        // Create a mock that returns data with null partnerOrderId
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorWithNullPartnerOrderId());
        BrightspeedOrderStatusAction.startOrderStatusSync(new List<Integer>{ 60 });
        Test.stopTest();

        // Verify the existing order was updated
        List<Order> updatedOrders = [SELECT Id, Status FROM Order WHERE Id IN :orders];
        System.assertEquals('Activated', updatedOrders[0].Status, 'Existing order status should be updated');
    }

    // Mock HTTP callout with null partnerOrderId for testing
    class MockHttpResponseGeneratorWithNullPartnerOrderId implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"messageStatus":[{"statusCode":"200","internalStatusCode":"","statusMessage":"","timestamp":"2024-12-16 12:03:05"}],' +
                '"transactionId":"PXOS-33311501-0293-4a1f-9fde-8822725e9f6a",' +
                '"orderCount":"2",' +
                '"partnerOrderStatus":[{"orderDetailAndCustomerInfo":[{' +
                '"partnerOrderId":"2c1bc1a6-a941-4eba-8a2b-58b640ea6355",' +
                '"partnerReferenceId":"123987546",' +
                '"partnerId":"BS223150",' +
                '"salesCode":"20000859",' +
                '"agentId":"agentinfohere",' +
                '"ACSID":"38973khjhjk",' +
                '"TFN":"18005551212",' +
                '"customerInfo":{"customerName":"firstname lastname","contactNumber":"5553211212","emailAddress":"none@gmail.com","serviceAddress":{"streetAddress":"801 LAKE AVE E","unit":"","city":"LADYSMITH","stateCode":"WI","zipCode":"54848"}},' +
                '"order":{"orderCreateDate":"2024-12-09 15:42:47","orderStatusDate":"12/12/2024","orderStatusSourceSystem":"partner","orderStatus":"Completed","orderDueDate":"12/12/2024","actualInstallationDate":"12/14/2024","accountNumber":"200238909","orderNumber":"WI1100003744","voiceTN":"5555551212","dslMigrator":false,' +
                '"orderLineItems":[{"productFamilyName":"BrightSpeed Internet","quantity":1,"productName":"BrightSpeed Internet 1 Gig","compCode":"HSI 1G","status":"Completed","action":"I"}]}}' +
                ',{' +
                '"partnerOrderId":null,' +
                '"partnerReferenceId":"123987546",' +
                '"partnerId":"BS223150",' +
                '"salesCode":"20000859",' +
                '"agentId":"agentinfohere",' +
                '"ACSID":"38973khjhjk",' +
                '"TFN":"18005551212",' +
                '"customerInfo":{"customerName":"firstname lastname","contactNumber":"5553211313","emailAddress":"none2@gmail.com","serviceAddress":{"streetAddress":"2501 LAKE AVE E","unit":"","city":"LADYSMITH","stateCode":"WI","zipCode":"54848"}},' +
                '"order":{"orderCreateDate":"2024-12-10 15:42:47","orderStatusDate":"12/13/2024","orderStatusSourceSystem":"partner","orderStatus":"Completed","orderDueDate":"12/12/2024","actualInstallationDate":"12/12/2024","accountNumber":"200284035","orderNumber":"WI1100005241","voiceTN":"5555551313","dslMigrator":false,' +
                '"orderLineItems":[{"productFamilyName":"BrightSpeed Internet","quantity":1,"productName":"BrightSpeed Internet 2 Gig","compCode":"HSI 1G","status":"Completed","action":"I"}]}}' +
                ']}]}'
            );
            return res;
        }
    }

    // Custom mock class that accepts any API response string
    class CustomMockHttpResponseGenerator implements HttpCalloutMock {
        private String apiResponse;

        public CustomMockHttpResponseGenerator(String apiResponse) {
            this.apiResponse = apiResponse;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.apiResponse);
            return res;
        }
    }

    // Method to test queueable with custom API response from Developer Console
    public static void testQueueableWithCustomResponse(String apiResponseJson) {
        // Set up the custom mock
        Test.setMock(HttpCalloutMock.class, new CustomMockHttpResponseGenerator(apiResponseJson));

        // Create a test request
        BrightspeedOrderStatusAction.OrderStatusRequest request = new BrightspeedOrderStatusAction.OrderStatusRequest();
        request.salesCode = '20000859';
        request.size = 10;
        request.page = 0;

        // Execute the queueable
        System.enqueueJob(new BrightspeedOrderStatusQueueable(request));

        System.debug('Queueable job enqueued with custom API response');
        System.debug('API Response used: ' + apiResponseJson);
    }

    // Convenience method with a sample API response for quick testing
    public static void testQueueableWithSampleResponse() {
        String sampleResponse =
            '{"messageStatus":[{"statusCode":"200","internalStatusCode":"","statusMessage":"","timestamp":"2024-12-16 12:03:05"}],' +
            '"transactionId":"PXOS-33311501-0293-4a1f-9fde-8822725e9f6a",' +
            '"orderCount":"1",' +
            '"partnerOrderStatus":[{"orderDetailAndCustomerInfo":[{' +
            '"partnerOrderId":"test-123",' +
            '"partnerReferenceId":"123987546",' +
            '"partnerId":"BS223150",' +
            '"salesCode":"20000859",' +
            '"agentId":"agentinfohere",' +
            '"ACSID":"38973khjhjk",' +
            '"TFN":"18005551212",' +
            '"customerInfo":{"customerName":"Test Customer","contactNumber":"5553211212","emailAddress":"test@gmail.com","serviceAddress":{"streetAddress":"123 TEST ST","unit":"","city":"TEST CITY","stateCode":"WI","zipCode":"12345"}},' +
            '"order":{"orderCreateDate":"2024-12-09 15:42:47","orderStatusDate":"12/12/2024","orderStatusSourceSystem":"partner","orderStatus":"Canceled","orderDueDate":"12/12/2024","actualInstallationDate":"12/14/2024","accountNumber":"200238909","orderNumber":"TEST123456","voiceTN":"5555551212","dslMigrator":false,' +
            '"orderLineItems":[{"productFamilyName":"BrightSpeed Internet","quantity":1,"productName":"BrightSpeed Internet 1 Gig","compCode":"HSI 1G","status":"Canceled","action":"I"}]}}' +
            ']}]}';

        testQueueableWithCustomResponse(sampleResponse);
    }
}