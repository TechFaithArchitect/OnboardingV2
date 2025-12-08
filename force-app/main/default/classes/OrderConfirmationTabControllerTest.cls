@isTest
public class OrderConfirmationTabControllerTest {
    @TestSetup
    static void makeData() {
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        User adminUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;
        update adminUser;
        System.runAs(adminUser) {
            RecordType rtype = [
                SELECT Name, Id
                FROM RecordType
                WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
                LIMIT 1
            ];
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Presentation',
                CloseDate = Date.today()
            );

            insert opp;

            Account ac = new Account(Name = 'test account');
            insert ac;

            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
            update standardPricebook;

            Product2 prod = new Product2(
                Name = 'Test Product',
                Description = 'test product',
                ProductCode = 'codetest',
                Family = 'test'
            );
            insert prod;

            PricebookEntry pbe = new PricebookEntry(
                UnitPrice = 20,
                Pricebook2Id = standardPricebook.Id,
                Product2Id = prod.Id
            );
            insert pbe;

            Contact userContact = new Contact(
                FirstName = 'test',
                LastName = 'testOrderConfirmation',
                AccountId = ac.Id
            );
            insert userContact;

            Profile p = TestHelper.getGeneralProfile();
            User u = new User(
                Alias = 'standt',
                Email = '11052022standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'testOrderConfirmation',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '11052022GDGstandarduser@testorg.com'
            );
            insert u;
        }
    }

    @isTest
    static void test_savePaymentAttempts() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        test.startTest();
        OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.savePaymentAttempts(
            new Map<String, Object>{ 'ContextId' => oppId, 'attempts' => 4, 'setOpportunityPaymentLimit' => true }
        );
        test.stopTest();

        Opportunity opp = [
            SELECT Id, POE_QuantityOfAttempts__c, POE_Payment_Limit_Reached__c
            FROM Opportunity
            WHERE Id = :oppId
        ];

        System.assertEquals(4, opp.POE_QuantityOfAttempts__c, 'Quantity of attempts must be the same');
        System.assert(opp.POE_Payment_Limit_Reached__c, 'Payment Limit Reached must be true');
    }

    @isTest
    static void test_saveCartDTV() {
        Id pbeId = [SELECT Id FROM PricebookEntry LIMIT 1].Id;
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;

        Order ord = new Order(
            AccountId = accId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        OrderItem oi = new OrderItem(OrderId = ord.Id, PricebookEntryId = pbeId, UnitPrice = 20, Quantity = 3);
        insert oi;

        test.startTest();
        OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.saveCart(
            new Map<String, Object>{ 'fee' => 29.95, 'orderItemId' => oi.Id }
        );
        test.stopTest();

        List<OrderItem> result = [SELECT Id, UnitPrice FROM OrderItem];

        System.assert(!result.isEmpty(), 'Order item list should not be empty');
        System.assertEquals(29.95, result[0].UnitPrice, 'UnitPrice does not match');
        System.assertEquals((String) response.result.get('Id'), result[0].Id, 'Id does not match');
    }

    @isTest
    static void test_saveConfigurationDTV() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;

        Order ord = new Order(
            AccountId = accId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        List<Object> configurations = new List<Object>();
        Map<Object, Object> conf = new Map<Object, Object>{ 'fee' => '20.30', 'name' => 'conf 1', 'type' => 'Monthly' };
        configurations.add(conf);
        conf = new Map<Object, Object>{ 'fee' => '40', 'name' => 'conf 2', 'type' => 'Monthly' };
        configurations.add(conf);
        test.startTest();
        OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.saveConfigurations(
            new Map<String, Object>{ 'orderId' => ord.Id, 'Configurations' => configurations }
        );
        test.stopTest();

        List<POE_Order_Configurations__c> insertedConfigurations = [SELECT Id FROM POE_Order_Configurations__c];

        System.assertEquals(true, (Boolean) response.result.get('UpsertSuccess'), 'Upsert success must be true');
        System.assertEquals(2, insertedConfigurations.size(), 'must be 2 configurations inserted');
    }

    @isTest
    static void test_updateWorkOrderId() {
        Id pbeId = [SELECT Id FROM PricebookEntry LIMIT 1].Id;
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;

        String testInternalWorkOrderId = '11111111';

        Order ord = new Order(
            AccountId = accId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        OrderItem oi = new OrderItem(OrderId = ord.Id, PricebookEntryId = pbeId, UnitPrice = 20, Quantity = 3);
        insert oi;

        test.startTest();
        OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.updateWorkOrderId(
            new Map<String, Object>{ 'orderId' => ord.Id, 'internalWorkOrderId' => testInternalWorkOrderId }
        );
        test.stopTest();

        List<Order> result = [SELECT Id, POE_OrderId__c FROM Order WHERE Id = :ord.Id];

        System.assert(!result.isEmpty(), 'Order list should not be empty');
        System.assertEquals(testInternalWorkOrderId, result[0].POE_OrderId__c, 'Internal work order Id does not match');
    }

    @isTest
    static void sendElectronicSummaryTest() {
        String testEmail = 'test@example.com';
        String testBody = 'https://www.test.com';
        String serviceType = 'test';

        Test.startTest();
        OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.sendElectronicSummary(
            new Map<String, Object>{ 'email' => testEmail, 'body' => testBody, 'serviceType' => serviceType }
        );
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(
            1,
            emailInvocations,
            'No email was sent or email invocations were not updated as expected.'
        );
        System.assertEquals(
            false,
            response.result.get('error'),
            'The response includes an error when the operation was successful.'
        );
    }

    @isTest
    static void test_saveCartSpectrum() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;

        Order testOrder = new Order(
            AccountId = accId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;

        PricebookEntry testPricebookEntry = [SELECT Id FROM PricebookEntry LIMIT 1];
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        List<Map<String, Object>> orderList = new List<Map<String, Object>>();
        Map<String, Object> orderItemData = new Map<String, Object>{
            'Id' => testOrderItem.Id,
            'OrderId' => testOrderItem.OrderId,
            'Quantity' => 2,
            'PricebookEntryId' => testOrderItem.PricebookEntryId,
            'POE_Status__c' => 'Pending Installation',
            'UnitPrice' => 150
        };
        orderList.add(orderItemData);

        Test.startTest();
        OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.saveCartSpectrum(
            orderList
        );
        Test.stopTest();

        Assert.areEqual(
            true,
            response.result.containsKey('UpsertSuccess'),
            'Response should contain key "UpsertSuccess"'
        );
        Assert.areEqual(true, response.result.get('UpsertSuccess'), 'UpsertSuccess should be true');
        Assert.areEqual(1, response.result.get('UpdatedCount'), 'UpdatedCount should be 1');

        OrderItem updatedOrderItem = [
            SELECT Quantity, UnitPrice, POE_Status__c
            FROM OrderItem
            WHERE Id = :testOrderItem.Id
        ];
        Assert.areEqual(2, updatedOrderItem.Quantity, 'Quantity should be updated to 2');
        Assert.areEqual(150, updatedOrderItem.UnitPrice, 'UnitPrice should be updated to 150');
        Assert.areEqual(
            'Pending Installation',
            updatedOrderItem.POE_Status__c,
            'POE_Status__c should be "Pending Installation"'
        );
    }

    @isTest
    static void testSaveReferralData_Success() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, Object> testData = new Map<String, Object>{
            'ContextId' => testOpp.Id,
            'referralOption' => 'Other',
            'referralDetail' => 'Detail'
        };
        Test.startTest();
        OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.saveReferralData(
            testData
        );
        Test.stopTest();

        System.assertNotEquals(response, null, 'Response should not be null');
        System.assertEquals(
            response.result.containsKey('UpsertSuccess'),
            true,
            'UpsertSuccess should exist in response'
        );
        System.assertEquals(response.result.get('UpsertSuccess'), true, 'UpsertSuccess should be true');

        Opportunity updatedOpp = [
            SELECT Referral_Option__c, Referral_Detail__c
            FROM Opportunity
            WHERE Id = :testOpp.Id
        ];
        System.assertEquals(updatedOpp.Referral_Option__c, 'Other', 'Referral_Option__c should be updated');
        System.assertEquals(updatedOpp.Referral_Detail__c, 'Detail', 'Referral_Detail__c should be updated');
    }

    @isTest
    static void testSaveReferralData_MissingContextId() {
        Map<String, Object> testData = new Map<String, Object>{
            'referralOption' => 'Other',
            'referralDetail' => 'Detail'
        };

        try {
            Test.startTest();
            OrderConfirmationTabController.saveReferralData(testData);
            Test.stopTest();
            System.assert(false, 'Method should have thrown an AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Should be return an error');
        }
    }
    @isTest
    static void testGetDealerAccountName() {
        User u = [SELECT Id, Account.Name, LastName FROM User WHERE LastName = 'testOrderConfirmation' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.getDealerAccountName();
            Test.stopTest();

            // Validate dealer name
            String dealerName = (String) response.result.get('dealerName');
            System.assertEquals(u.Account.Name, dealerName, 'Account name is not being correctly retrieved');
        }
    }

    @isTest
    static void test_updateOrderItemsComponentAndPhone() {
        // Setup: create Account, Opportunity, Product2, PricebookEntry, Order, OrderItems
        Account acc = new Account(Name = 'OrderItemTestAcc');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'OrderItemTestOpp',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        insert opp;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update pb;
        Product2 prod1 = new Product2(Name = 'Prod1', ProductCode = 'PCODE1', Family = 'Test', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Prod2', ProductCode = 'PCODE2', Family = 'Test', IsActive = true);
        insert new List<Product2>{ prod1, prod2 };
        PricebookEntry pbe1 = new PricebookEntry(
            Product2Id = prod1.Id,
            Pricebook2Id = pb.Id,
            UnitPrice = 10,
            IsActive = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Product2Id = prod2.Id,
            Pricebook2Id = pb.Id,
            UnitPrice = 20,
            IsActive = true
        );
        insert new List<PricebookEntry>{ pbe1, pbe2 };
        Order ord = new Order(
            AccountId = acc.Id,
            OpportunityId = opp.Id,
            Pricebook2Id = pb.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;
        OrderItem oi1 = new OrderItem(
            OrderId = ord.Id,
            Product2Id = prod1.Id,
            PricebookEntryId = pbe1.Id,
            Quantity = 1,
            UnitPrice = 10
        );
        OrderItem oi2 = new OrderItem(
            OrderId = ord.Id,
            Product2Id = prod2.Id,
            PricebookEntryId = pbe2.Id,
            Quantity = 1,
            UnitPrice = 20
        );
        insert new List<OrderItem>{ oi1, oi2 };
        // Prepare input: only update oi1, oi2 will be deleted (no componentCode)
        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productCode' => 'PCODE1', 'componentCode' => 'COMP1', 'phone' => '1234567890' },
            new Map<String, Object>{ 'productCode' => 'PCODE2', 'componentCode' => null, 'phone' => null }
        };
        Test.startTest();
        OrderConfirmationTabController.ResponseWrapper resp = OrderConfirmationTabController.updateOrderItemsComponentAndPhone(
            ord.Id,
            items,
            'Order Submission Log'
        );
        Test.stopTest();
        // Assert oi1 is updated
        OrderItem updatedOi1 = [
            SELECT Id, Component_Code__c, Telephone_Number__c, POE_Status__c
            FROM OrderItem
            WHERE Id = :oi1.Id
        ];
        System.assertEquals('COMP1', updatedOi1.Component_Code__c, 'Component_Code__c should be updated');
        System.assertEquals('1234567890', updatedOi1.Telephone_Number__c, 'Telephone_Number__c should be updated');
        System.assertEquals('Pending Installation', updatedOi1.POE_Status__c, 'POE_Status__c should be updated');
        // Assert oi2 is deleted
        List<OrderItem> deletedOi2 = [SELECT Id FROM OrderItem WHERE Id = :oi2.Id];
        System.assertEquals(0, deletedOi2.size(), 'OrderItem with no componentCode should be deleted');
        // Assert response counts
        System.assertEquals(2, resp.result.get('updatedCount'), 'Should update 2 order items');
        System.assertEquals(1, resp.result.get('deletedCount'), 'Should delete 1 order item');
    }

    @isTest
    static void testUpdateE911TermsSent() {
        Opportunity testOpp = [SELECT Id, Frontier_911_Terms_Sent__c FROM Opportunity LIMIT 1];

        // Verify initial state
        System.assertEquals(
            false,
            testOpp.Frontier_911_Terms_Sent__c,
            'Initial Frontier_911_Terms_Sent__c should be false'
        );
        Test.startTest();
        OrderConfirmationTabController.ResponseWrapper response = OrderConfirmationTabController.updateE911TermsSent(
            testOpp.Id
        );
        Test.stopTest();

        // Verify response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(
            true,
            response.result.containsKey('UpsertSuccess'),
            'UpsertSuccess should exist in response'
        );
        System.assertEquals(true, response.result.get('UpsertSuccess'), 'UpsertSuccess should be true');

        // Verify the field was updated
        Opportunity updatedOpp = [SELECT Id, Frontier_911_Terms_Sent__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(
            true,
            updatedOpp.Frontier_911_Terms_Sent__c,
            'Frontier_911_Terms_Sent__c should be updated to true'
        );
    }

    @isTest
    static void testUpdateE911TermsSent_InvalidRecordId() {
        String invalidRecordId = '001000000000000';

        try {
            Test.startTest();
            OrderConfirmationTabController.updateE911TermsSent(invalidRecordId);
            Test.stopTest();
            System.assert(false, 'Method should have thrown an AuraHandledException for invalid record ID');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('Script-thrown exception'),
                'Should return an error for invalid record ID'
            );
        }
    }
}