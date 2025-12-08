@isTest
private class POE_OrderRelatedListsControllerTest {
    @TestSetup
    static void makeData(){
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            IsActive = true
        );
        insert testProduct;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100.00
        );
        insert testOrderItem;
        
        POE_Order_Configurations__c testConfig = new POE_Order_Configurations__c(
            Name = 'Test Config',
            Order__c = testOrder.Id,
            Fee_Type__c = 'Monthly',
            Amount__c = 50.00
        );
        insert testConfig;
    }
    
    @isTest
    static void testGetOrderRelatedData() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        
        Test.startTest();
        Object result = POE_OrderRelatedListsController.getOrderRelatedData(testOrder.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}