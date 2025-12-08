@isTest
public with sharing class POEShellOrderControllerTest {
    @TestSetup
    static void makeData() {
        Account testAcc = new Account(Name = 'Account Test');
        insert testAcc;
        Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
        insert userContact;
        Contact testContact1 = new Contact(FirstName = 'Account', LastName = 'Test', AccountId = testAcc.Id);
        insert testContact1;
        Contact testContact2 = new Contact(FirstName = 'testCont2', LastName = 'testCont2', AccountId = testAcc.Id);
        insert testContact2;

        Opportunity opp1 = new Opportunity(
            Name = 'TEST1',
            CloseDate = System.today(),
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp1;
        Opportunity opp2 = new Opportunity(
            Name = 'TEST2',
            CloseDate = System.today(),
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp2;
        Opportunity opp3 = new Opportunity(
            Name = 'TEST3',
            CloseDate = System.today(),
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp3;
        Opportunity opp4 = new Opportunity(
            Name = 'TEST4',
            CloseDate = System.today(),
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp4;

        Product2 product = new Product2(
            Description = 'Integration Product',
            IsActive = true,
            Name = 'Integration',
            ProductCode = 'IP1',
            Family = 'EarthLink'
        );
        insert product;

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        PricebookEntry entry = new PricebookEntry(
            IsActive = true,
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 500.00
        );
        insert entry;

        Order testOrder = new Order(
            EffectiveDate = System.today(),
            Status = 'Draft',
            AccountId = testAcc.Id,
            Pricebook2Id = standardPricebook.Id,
            OpportunityId = opp1.Id
        );
        insert testOrder;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = product.Id,
            Quantity = 1,
            PricebookEntryId = entry.Id,
            UnitPrice = entry.UnitPrice
        );
        insert testOrderItem;
    }
    @isTest
    private static void getInitialDataTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        POEShellOrderController.InitialData data = new POEShellOrderController.InitialData();
        Test.startTest();
        data = POEShellOrderController.getInitialData(opp.Id);
        Test.stopTest();
        System.assertEquals(acc.Id, data.order.AccountId, 'The data was not correctly read');
    }

    @isTest
    private static void saveDataWithNoUpdatesTest() {
        Id recType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Shell Order').getRecordTypeId();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        POEShellOrderController.saveData(
            'Account',
            'Test',
            opp.Id,
            null,
            '1111111111',
            '2222222222',
            '12345',
            '2050-07-25',
            'Low Signal',
            recType
        );
        Test.stopTest();
        List<Order> orders = [SELECT Id FROM Order WHERE Type = 'Call Center'];
        System.assertEquals(1, orders.size(), 'The data was not correctly inserted');
    }

    @isTest
    private static void saveDataWithUpdatesTest() {
        Id recType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Shell Order').getRecordTypeId();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        POEShellOrderController.saveData(
            'Insert',
            'Test',
            opp.Id,
            null,
            '1111111111',
            '2222222222',
            '12345',
            '2050-07-25',
            'Low Signal',
            recType
        );
        Test.stopTest();
        List<Order> orders = [SELECT Id FROM Order WHERE Type = 'Call Center'];
        System.assertEquals(1, orders.size(), 'The data was not correctly inserted');
    }
}