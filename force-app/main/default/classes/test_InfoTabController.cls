@istest
public class test_InfoTabController {
    private static Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    private static User u = new User(
        Alias = 'standt',
        Email = 'standarduser@testorg.com',
        EmailEncodingKey = 'UTF-8',
        FirstName = 'Test',
        LastName = 'Testing',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'unittestinguser@testorg.com',
        POE_FraudObservation__c = false
    );

    @TestSetup
    static void makeData() {
        PermissionSetGroup psg = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName = 'FSL_Dates' LIMIT 1];
        RecordType dealerRT = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];

        if (psg.Status != 'Updated') {
            Test.calculatePermissionSetGroup(psg.Id);
        }

        DIRECTV_Zip_Restriction__c restriction = new DIRECTV_Zip_Restriction__c(Name = '11111');
        insert restriction;

        Opportunity opp = new Opportunity(
            Maps_PostalCode__c = '1234',
            Maps_Street__c = 'Test street',
            Maps_AptNumber__c = '1234',
            Maps_Building__c = '4',
            Maps_City__c = 'Test city',
            Maps_Country__c = 'test country',
            Maps_Floor__c = '3',
            Maps_Latitude__c = 1.23151,
            Maps_Longitude__c = 2.4214,
            Maps_State__c = 'Texas',
            Name = 'Test Opportunity',
            POE_Clicker_Origin__c = 'phonesales',
            StageName = 'Contact',
            CloseDate = Date.today()
        );
        insert opp;

        Account acc = new Account(Name = 'Test');
        insert acc;

        Order ord = new Order(
            OpportunityId = opp.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        Product2 prod = new Product2(Name = 'Test');
        insert prod;

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        PricebookEntry pe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100,
            isActive = true
        );
        insert pe;

        List<POE_Dealer_Code__c> dealerCodes = new List<POE_Dealer_Code__c>();
        dealerCodes.add(
            new POE_Dealer_Code__c(
                POE_Provider__c = 'Altice',
                Zip_Code__c = 64801,
                POE_Dealer_Code__c = 'AAAAA',
                POE_Account__c = acc.Id
            )
        );
        dealerCodes.add(
            new POE_Dealer_Code__c(
                POE_Provider__c = 'Charter/Spectrum',
                Zip_Code__c = 64801,
                POE_Affiliate_Id__c = 'AFFILIATE1',
                Spectrum_Sales_Id__c = 'SALES1',
                POE_Account__c = acc.Id
            )
        );
        insert dealerCodes;

        WorkType testWorkType = new WorkType(Name = 'test', EstimatedDuration = 60);
        insert testWorkType;

        Chuzo_Settings__c settings = new Chuzo_Settings__c(
            Earthlink_Promo_Codes__c = 'test:123;test2:234',
            FSL_Work_Type_Id__c = testWorkType.Id,
            Frontier_Quote_Resume_Project__c = true
        );
        insert settings;

        Account dealer = new Account(Name = 'Dealer Account', RecordTypeId = dealerRT.Id);
        insert dealer;

        Contact con = new Contact(
            FirstName = 'Dealer',
            LastName = 'Contact',
            Email = 'contact@example.com',
            AccountId = dealer.Id,
            POE_Functional_Role__c = 'Office Manager'
        );
        insert con;

        Id standardProfile = TestHelper.getGeneralProfile().Id;

        User agent = new User(
            Username = 'testuserquoteresume' + String.valueOf(Math.random()) + '@example.com',
            FirstName = 'Test',
            LastName = 'Agent',
            Email = 'testuserquoteresumefrontier@example.com',
            Alias = 'tuser',
            ProfileId = standardProfile,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = con.Id
        );
        insert agent;

        System.runAs(agent) {
            Account customer = new Account(
                FirstName = 'Customer',
                LastName = 'Account',
                Phone = '1234567890',
                PersonEmail = 'test@example.com'
            );
            insert customer;

            Opportunity mainOpp = new Opportunity(
                Name = 'Main Opp',
                StageName = 'Opportunity',
                Maps_PostalCode__c = '75074',
                CloseDate = Date.today().addDays(10),
                AccountId = customer.Id,
                POE_Dealer__c = dealer.Id,
                Frontier_Quote_ID__c = 'FQ-' + String.valueOf(Math.random()),
                Frontier_Quote_Number__c = 'FN-' + String.valueOf(Math.random())
            );
            insert mainOpp;

            for (Integer i = 0; i < 2; i++) {
                Opportunity otherOpp = new Opportunity(
                    Name = 'Other Opp ' + i,
                    StageName = 'Opportunity',
                    CloseDate = Date.today().addDays(5),
                    AccountId = customer.Id,
                    OwnerId = agent.Id,
                    POE_Dealer__c = dealer.Id,
                    Frontier_Quote_ID__c = 'FQ-' + i,
                    Frontier_Quote_Number__c = 'FN-' + i
                );
                insert otherOpp;
            }
        }

    }

    @isTest
    static void testGetAddressInfo() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        System.runAs(u) {
            Map<String, Object> data = new Map<String, Object>{ 'Id' => oppId };

            test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.getAddressInfo(data);
            test.stopTest();

            Opportunity opp = (Opportunity) response.result.get('Opportunity');

            System.assertEquals('Test street', opp.Maps_Street__c, 'Street do not match');
            System.assertEquals('1234', opp.Maps_PostalCode__c, 'Postal code do not match');
            System.assertEquals('Contact', opp.StageName, 'Opportunity Stage do not match');
            System.assertEquals(false, (Boolean) response.result.get('IsOwner'), 'IsOwner field must be false');
        }
    }

    @isTest
    static void testSaveGeoLocalization() {
        Map<String, Object> data = new Map<String, Object>{
            'maps__Location__c' => new Map<Object, Object>{
                'maps__Latitude__c' => 1.21241,
                'maps__Longitude__c' => 3.1241,
                'POE_GeoCode_Origin__c' => 'test origin',
                'POE_GeoCode_Sub_Origin__c' => 'suborigin'
            }
        };

        test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.saveGeoLocalization(data);
        test.stopTest();
        maps__Location__c location = [SELECT Id FROM maps__Location__c LIMIT 1];

        system.assertEquals(true, (Boolean) response.result.get('UpsertSuccess'), 'The upsert status must be true');
        system.assertEquals(location.Id, (String) response.result.get('Id'), 'Maps Location Id do not match');
    }

    @isTest
    static void testSetClickerRetailTrack() {
        System.runAs(u) {
            Map<String, Object> data = new Map<String, Object>{
                'operation' => 'setTrack',
                'userId' => System.UserInfo.getUserId(),
                'isCount' => true,
                'action' => 'Serviceability Check'
            };

            test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.setClickerRetailTrack(data);
            test.stopTest();

            System.assertEquals(false, (Boolean) response.result.get('FraudFlag'), 'Fraud Flag must be false');
            System.assertEquals(0, (Integer) response.result.get('countCompleted'), 'countCompleted do not match');
            System.assertEquals(0, (Integer) response.result.get('countContact'), 'countContact do not match');
            System.assertEquals(0, (Integer) response.result.get('countProduct'), 'countProduct do not match');
            System.assertEquals(
                1,
                (Integer) response.result.get('countServiceability'),
                'countServiceability do not match'
            );
            System.assertNotEquals(
                null,
                response.result.get('inProgressRetail'),
                'InProgressRetail field should not be null'
            );
        }
    }

    @isTest
    static void testSetClickerEventTrack() {
        System.runAs(u) {
            Map<String, Object> data = new Map<String, Object>{
                'operation' => 'setTrack',
                'userId' => System.UserInfo.getUserId(),
                'isCount' => true,
                'action' => 'Serviceability Check'
            };

            test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.setClickerEventTrack(data);
            test.stopTest();

            System.assertEquals(false, (Boolean) response.result.get('FraudFlag'), 'Fraud Flag must be false');
            System.assertEquals(0, (Integer) response.result.get('countCompleted'), 'countCompleted do not match');
            System.assertEquals(0, (Integer) response.result.get('countContact'), 'countContact do not match');
            System.assertEquals(0, (Integer) response.result.get('countProduct'), 'countProduct do not match');
            System.assertEquals(
                1,
                (Integer) response.result.get('countServiceability'),
                'countServiceability do not match'
            );
            System.assertNotEquals(
                null,
                response.result.get('inProgressEvent'),
                'inProgressEvent field should not be null'
            );
        }
    }

    @isTest
    static void testSetClickerCallCenterTrack() {
        System.runAs(u) {
            Map<String, Object> data = new Map<String, Object>{
                'operation' => 'setTrack',
                'userId' => System.UserInfo.getUserId(),
                'isCount' => true,
                'action' => 'Serviceability Check'
            };

            test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.setClickerCallCenterTrack(data);
            test.stopTest();

            System.assertEquals(false, (Boolean) response.result.get('FraudFlag'), 'Fraud Flag must be false');
            System.assertEquals(0, (Integer) response.result.get('countCompleted'), 'countCompleted do not match');
            System.assertEquals(0, (Integer) response.result.get('countContact'), 'countContact do not match');
            System.assertEquals(0, (Integer) response.result.get('countProduct'), 'countProduct do not match');
            System.assertEquals(
                1,
                (Integer) response.result.get('countServiceability'),
                'countServiceability do not match'
            );
            System.assertNotEquals(
                null,
                response.result.get('inProgressTrack'),
                'inProgressTrack field should not be null'
            );
        }
    }

    @isTest
    static void testSaveOpportunityAddressInformation() {
        System.runAs(u) {
            Map<Object, Object> opp = new Map<Object, Object>{
                'Maps_PostalCode__c' => '1234',
                'Maps_Street__c' => 'Test street',
                'Maps_AptNumber__c' => '1234',
                'Maps_Building__c' => '4',
                'Maps_City__c' => 'Test city',
                'Maps_Country__c' => 'test country',
                'Maps_Floor__c' => '3',
                'Maps_Latitude__c' => 1.23151,
                'Maps_Longitude__c' => 2.4214,
                'Maps_State__c' => 'Texas',
                'Name' => 'Test Opportunity 2',
                'POE_Clicker_Origin__c' => 'phonesales',
                'StageName' => 'Contact',
                'CloseDate' => Date.today()
            };

            Map<String, Object> data = new Map<String, Object>{
                'opportunity' => opp,
                'latitude' => 1.2124,
                'longitude' => 2.2412,
                'origin' => 'phonesales'
            };

            test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.saveOpportunityAddressInformation(data);
            test.stopTest();

            List<Opportunity> opps = [SELECT Id, Name FROM Opportunity WHERE Maps_City__c = 'Test city'];
            Opportunity newopp = opps[1];

            System.assertEquals(
                newopp.Id,
                (String) response.result.get('opportunityId'),
                'Opportunity Id do not match'
            );
        }
    }

    @isTest
    static void testGetCharterInformation() {
        System.runAs(u) {
            Map<String, Object> input = new Map<String, Object>{ 'program' => 'Altice' };

            Test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.getCharterInformation(input);
            Test.stopTest();

            System.assertEquals(
                u.Email,
                (String) response.result.get('userEmail'),
                'The userEmail variable does not match the running User\'s Email'
            );
            System.assertEquals(
                u.FirstName,
                (String) response.result.get('firstName'),
                'The firstName variable does not match the running User\'s FirstName'
            );
            System.assertEquals(
                u.LastName,
                (String) response.result.get('lastName'),
                'The lastName variable does not match the running User\'s LastName'
            );
            System.assert(
                String.isNotBlank((String) response.result.get('url')),
                'The url field is blank for the specified program, but a value was expected'
            );
            System.assert(
                String.isNotBlank((String) response.result.get('salesId')),
                'The salesId field is blank for the specified program, but a value was expected'
            );
        }
    }

    @isTest
    static void testSaveIframeClient() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => oppId,
            'firstName' => 'NonExisting',
            'lastName' => 'Account',
            'street' => 'Test Address',
            'city' => 'Test city',
            'state' => 'NY',
            'zipCode' => '72212',
            'phone' => '1231235234',
            'mobile' => '1231235234',
            'email' => 'test@test.com',
            'origin' => 'callcenter',
            'program' => 'Charter/Spectrum',
            'isCallOrder' => 'true',
            'consent' => false
        };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.saveIframeClient(input);
        Test.stopTest();

        System.assert(
            response.result.get('Opportunity') != null,
            'The Opportunity from the input was not included in the response.'
        );
        System.assert(
            response.result.get('Order') != null,
            'No Order was created or it was not included in the response.'
        );

        Opportunity testOpp = (Opportunity) response.result.get('Opportunity');
        System.assertEquals(oppId, testOpp.Id, 'The Opportunity Id from the response does not match the input.');
    }

    @isTest
    static void testSetClickerMDUTrack() {
        System.runAs(u) {
            Map<String, Object> data = new Map<String, Object>{
                'operation' => 'setTrack',
                'userId' => System.UserInfo.getUserId(),
                'isCount' => true,
                'action' => 'Serviceability Check'
            };

            test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.setClickerMDUTrack(data);
            test.stopTest();

            System.assertEquals(false, (Boolean) response.result.get('FraudFlag'), 'Fraud Flag must be false');
            System.assertEquals(0, (Integer) response.result.get('countCompleted'), 'countCompleted do not match');
            System.assertEquals(0, (Integer) response.result.get('countContact'), 'countContact do not match');
            System.assertEquals(0, (Integer) response.result.get('countProduct'), 'countProduct do not match');
            System.assertEquals(
                1,
                (Integer) response.result.get('countServiceability'),
                'countServiceability do not match'
            );
            System.assertNotEquals(
                null,
                response.result.get('inProgressMDU'),
                'inProgressMDU field should not be null'
            );
        }
    }

    @isTest
    static void testAssociateProductWithOrder() {
        Id orderId = [SELECT Id FROM Order LIMIT 1].Id;
        Map<String, Object> input = new Map<String, Object>{
            'name' => 'Test',
            'orderId' => orderId,
            'isConflictOrder' => true
        };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.associateProductWithOrder(input);
        Test.stopTest();

        Integer orderItemCount = [SELECT COUNT() FROM OrderItem WHERE OrderId = :orderId];
        System.assertEquals(1, orderItemCount, 'No Order Product record was created.');
        System.assert(
            response.result.get('OrderItem') != null,
            'The new Order Product was not included in the response.'
        );

        OrderItem resultOrderItem = (OrderItem) response.result.get('OrderItem');
        System.assertEquals(
            orderId,
            resultOrderItem.OrderId,
            'The OrderId of the Order Product included in the response does not match the input.'
        );
    }

    @isTest
    static void testSaveBuyflowTab() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Map<String, Object> input = new Map<String, Object>{ 'tab' => 'Offers', 'oppId' => oppId };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.saveBuyflowTab(input);
        Test.stopTest();

        System.assert(
            response.result.get('Opportunity') != null,
            'The updated Opportunity was not included in the response.'
        );

        Opportunity resultOpportunity = (Opportunity) response.result.get('Opportunity');
        System.assertEquals('Offers', resultOpportunity.Tab_Reached__c, 'The Tab value was no correctly updated.');
    }

    @isTest
    static void testSaveOpportunityStage() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Map<String, Object> input = new Map<String, Object>{
            'ContextId' => oppId,
            'earliestDate' => Date.today(),
            'installationDate' => Date.today().addDays(3)
        };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.saveOpportunityStage(input);
        Test.stopTest();

        System.assert(
            response.result.get('Opportunity') != null,
            'The new Opportunity was not included in the response.'
        );
        Opportunity resultOpp = (Opportunity) response.result.get('Opportunity');
        System.assertEquals(
            oppId,
            resultOpp.Id,
            'The Id of the Opportunity included in the response does not match the input.'
        );

        Order orderRelatedToOpp = [SELECT Status FROM Order WHERE OpportunityId = :OppId LIMIT 1];
        System.assertEquals(
            'Pending Installation',
            orderRelatedToOpp.Status,
            'The Order\'s status was not updated to "Pending Installation".'
        );

        List<POE_ACI_Statistic__c> aciStatisticList = [
            SELECT Id, Product_Selection__c, Order_Created__c, Credit_Check__c, Presentation__c, Contact__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :oppId
            LIMIT 1
        ];
        System.assertEquals(1, aciStatisticList.size(), 'No ACI Statistic record was upserted.');

        POE_ACI_Statistic__c aciStatistic = aciStatisticList[0];
        System.assertEquals(
            1,
            aciStatistic.Product_Selection__c,
            'Incorrect value assigned to the Product_Selection__c field.'
        );
        System.assertEquals(
            1,
            aciStatistic.Order_Created__c,
            'Incorrect value assigned to the Order_Created__c field.'
        );
        System.assertEquals(1, aciStatistic.Credit_Check__c, 'Incorrect value assigned to the Credit_Check__c field.');
        System.assertEquals(1, aciStatistic.Presentation__c, 'Incorrect value assigned to the Presentation__c field.');
        System.assertEquals(1, aciStatistic.Contact__c, 'Incorrect value assigned to the Contact__c field.');
    }

    @isTest
    static void testUpdateOrderBillingAddress() {
        Order inputOrder = [SELECT Id, AccountId FROM Order LIMIT 1];
        String zip = '7357';
        String street = 'Test street';
        String city = 'Test city';
        String state = 'NY';

        Map<String, Object> input = new Map<String, Object>{
            'orderId' => inputOrder.Id,
            'zip' => zip,
            'street' => street,
            'city' => city,
            'state' => state
        };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.updateOrderBillingAddress(input);
        Test.stopTest();

        System.assert(response.result.get('Order') != null, 'The updated Order was not included in the response.');
        Order resultOrder = (Order) response.result.get('Order');
        System.assertEquals(
            inputOrder.Id,
            resultOrder.Id,
            'The Id of the Order included in the response does not match the input.'
        );
        Order updatedOrder = [
            SELECT
                Id,
                BillingCity,
                BillingStateCode,
                BillingStreet,
                BillingPostalCode,
                Account.Id,
                Account.BillingCity,
                Account.BillingStateCode,
                Account.BillingStreet,
                Account.BillingPostalCode
            FROM Order
            WHERE Id = :inputOrder.Id
        ];
        System.assertEquals(
            zip,
            updatedOrder.BillingPostalCode,
            'The Order\'s BillingPostalCode field does not match the input.'
        );
        System.assertEquals(
            street,
            updatedOrder.BillingStreet,
            'The Order\'s BillingStreet field does not match the input.'
        );
        System.assertEquals(city, updatedOrder.BillingCity, 'The Order\'s BillingCity field does not match the input.');
        System.assertEquals(
            state,
            updatedOrder.BillingStateCode,
            'The Order\'s BillingState field does not match the input.'
        );

        System.assert(response.result.get('Account') != null, 'The updated Account was not included in the response.');
        Account resultAccount = (Account) response.result.get('Account');
        System.assertEquals(
            inputOrder.AccountId,
            resultAccount.Id,
            'The Id of the Account included in the response does not match the input.'
        );
        Account updatedAccount = updatedOrder.Account;
        System.assertEquals(
            zip,
            updatedAccount.BillingPostalCode,
            'The Account\'s BillingPostalCode field does not match the input.'
        );
        System.assertEquals(
            street,
            updatedAccount.BillingStreet,
            'The Account\'s BillingStreet field does not match the input.'
        );
        System.assertEquals(
            city,
            updatedAccount.BillingCity,
            'The Account\'s BillingCity field does not match the input.'
        );
        System.assertEquals(
            state,
            updatedAccount.BillingStateCode,
            'The Account\'s BillingState field does not match the input.'
        );
    }

    @isTest
    static void testSetAddressDiscrepancy() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Map<String, Object> input = new Map<String, Object>{ 'ContextId' => oppId };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.setAddressDiscrepancy(input);
        Test.stopTest();

        System.assert(
            response.result.get('Opportunity') != null,
            'The updated Opportunity was not included in the response.'
        );
        Opportunity resultOpportunity = (Opportunity) response.result.get('Opportunity');
        System.assertEquals(
            oppId,
            resultOpportunity.Id,
            'The Id of the Opportunity included in the response does not match the input.'
        );

        Opportunity updatedOpportunity = [SELECT POE_AddressDiscrepancy__c FROM Opportunity WHERE Id = :oppId];
        System.assert(
            updatedOpportunity.POE_AddressDiscrepancy__c,
            'The Address Discrepancy flag was not set in the Opportunity.'
        );
    }

    @isTest
    static void testAddNewProduct() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Map<String, Object> input = new Map<String, Object>{ 'ContextId' => oppId };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.addNewProduct(input);
        Test.stopTest();

        System.assert(
            response.result.get('Opportunity') != null,
            'The updated Opportunity was not included in the response.'
        );
        Opportunity resultOpportunity = (Opportunity) response.result.get('Opportunity');
        System.assertEquals(
            oppId,
            resultOpportunity.POE_ParentOpportunity__c,
            'The Parent Opportunity Id of the Opportunity included in the response does not match the input.'
        );

        Opportunity createdOpportunity = [
            SELECT Id, CloseDate, POE_New_Product_Opportunity__c, StageName
            FROM Opportunity
            WHERE Id = :resultOpportunity.Id
        ];
        System.assertEquals(
            Date.today(),
            createdOpportunity.CloseDate,
            'The inserted Opportunity\'s CloseDate field is not the current date.'
        );
        System.assertEquals(
            'Opportunity',
            createdOpportunity.StageName,
            'The inserted Opportunity\'s StageName field is not "Opportunity".'
        );
        System.assert(
            createdOpportunity.POE_New_Product_Opportunity__c,
            'The New Product Opportunity flag was not set in the inserted Opportunity.'
        );
    }

    @isTest
    static void testGetIPStackSettings() {
        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.getIPStackSettings();
        Test.stopTest();

        System.assert(
            String.isNotBlank((String) response.result.get('ip')),
            'The IP field of the response is null, empty or a blank string.'
        );
        System.assert(
            String.isNotBlank((String) response.result.get('region_name')),
            'The Region field of the response is null, empty or a blank string.'
        );
    }

    @isTest
    static void testSaveIPStatisticRecord() {
        System.runAs(u) {
            Map<String, Object> input = new Map<String, Object>{
                'userId' => u.Id,
                'ip' => '123.123.123.123',
                'ContextId' => [SELECT Id FROM Opportunity LIMIT 1]
                .Id
            };

            Test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.saveIPStatisticRecord(input);
            Test.stopTest();

            System.assert(
                response.result.get('statistic') != null,
                'The inserted Fraud Validation Statistics record was not included in the response.'
            );

            Fraud_Validation_Statistics__c resultStatistic = (Fraud_Validation_Statistics__c) response.result.get(
                'statistic'
            );
            System.assert(
                String.isNotBlank(resultStatistic.Id),
                'The Fraud Validation Statistics record was not inserted or it does not have its Id field set.'
            );
            System.assertEquals(
                u.ContactId,
                resultStatistic.Contact__c,
                'The Contact__c field of the Fraud Validation Statistics record does not match the input.'
            );
            System.assert(
                resultStatistic.Last_Updated__c != null,
                'The Last_Updated__c field of the Fraud Validation Statistics is null.'
            );
            System.assertEquals(
                'Suspicious IP Address',
                resultStatistic.Validation_Rule__c,
                'The Validation_Rule__c field of the Fraud Validation Statistics record is incorrect.'
            );
            System.assertEquals(
                '123.123.123.123',
                resultStatistic.IP_Address__c,
                'The IP_Address__c field of the Fraud Validation Statistics record does not match the input.'
            );
        }
    }

    @isTest
    static void getDealerCodeTestAltice() {
        System.runAs(u) {
            Map<String, Object> input = new Map<String, Object>{ 'program' => 'Altice', 'zipCode' => 64801 };

            Test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.getDealerCode(input);
            Test.stopTest();

            System.assert(response.result.get('Codes') != null, 'No Dealer Codes were found for test zipCode.');
        }
    }

    @isTest
    static void testGetOppReferenceNumber() {
        Opportunity opp = [SELECT Id, POE_Reference_Number__c FROM Opportunity LIMIT 1];
        Map<String, Object> input = new Map<String, Object>{ 'ContextId' => opp.Id };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.getOppReferenceNumber(input);
        Test.stopTest();

        Assert.areEqual(
            opp.POE_Reference_Number__c,
            response.result.get('referenceNumber'),
            'The reference number included in the response was not as expected'
        );
    }

    @isTest
    static void testUpdateAutoPay() {
        Opportunity opp = [SELECT Id, POE_Reference_Number__c FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1];

        Test.startTest();
        InfoTabController.updateAutoPay(true, true, opp.Id, false);
        Test.stopTest();

        Opportunity result = [
            SELECT Id, AutoPay__c, POE_Reference_Number__c
            FROM Opportunity
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        Assert.areEqual(true, result.AutoPay__c, 'AutoPay value was not updated');
    }

    @isTest
    static void testSaveFrontierQuoteNumber() {
        Opportunity opp = [SELECT Id, Frontier_Quote_ID__c, Frontier_Quote_Number__c FROM Opportunity LIMIT 1];
        String quoteNumber = '12355';
        String quoteId = '125436';
        Map<String, Object> myData = new Map<String, Object>{
            'recordId' => opp.Id,
            'quoteId' => quoteId,
            'quoteNumber' => quoteNumber
        };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.saveFrontierQuoteNumber(myData);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Frontier_Quote_ID__c, Frontier_Quote_Number__c FROM Opportunity LIMIT 1];

        Assert.areEqual(updatedOpp.Frontier_Quote_ID__c, quoteId, 'The quote ID in the response was not as expected');
    }

    @isTest
    static void testSaveFrontierBTN() {
        Opportunity opp = [SELECT Id, Frontier_BTN__c, Frontier_Quote_Number__c FROM Opportunity LIMIT 1];
        String btn = '12355';
        Map<String, Object> myData = new Map<String, Object>{ 'recordId' => opp.Id, 'btn' => btn };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.saveFrontierBTN(myData);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Frontier_BTN__c, Frontier_Quote_Number__c FROM Opportunity LIMIT 1];

        Assert.areEqual(updatedOpp.Frontier_BTN__c, btn, 'The BTN in the response was not as expected');
    }

    @isTest
    static void testGetDealerInfo() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];

        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test User Account',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
                P10_Invoice_Account__c = 'Example',
                recordTypeId = rtype.Id
            );
            insert testAcc;
            Contact userContact = new Contact(
                FirstName = 'test',
                LastName = 'test',
                AccountId = testAcc.Id,
                POE_Functional_Role__c = 'Office Manager'
            );
            insert userContact;

            Profile p = TestHelper.getGeneralProfile();
            User u = new User(
                Alias = 'standt',
                Email = '11052022standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '11052022GDGstandarduser@testorg.com'
            );
            insert u;
        }

        User newUser = [SELECT Id FROM User WHERE Email = '11052022standarduser@testorg.com' LIMIT 1];

        System.runAs(newUser) {
            test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.getDealerInfo(new Map<String, Object>());
            test.stopTest();

            Map<String, Object> users = (Map<String, Object>) response.result.get('Users');
            Map<String, Object> accounts = (Map<String, Object>) response.result.get('Accounts');

            System.assertEquals('Testing', (String) users.get('LastName'), 'LastName do not match');
            System.assertEquals('Test User Account', (String) accounts.get('Name'), 'Account name do not match');
        }
    }

    @isTest
    static void getEarthlinkPromoCodesTest() {
        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.getEarthlinkPromoCodes();
        Test.stopTest();

        Assert.isNotNull(response.result.get('promoCodes'), 'The promoCodes list was null.');
        List<Object> promoCodes = (List<Object>) response.result.get('promoCodes');
        Assert.isTrue(promoCodes.size() > 0, 'The promoCodes list had no elements.');
    }

    @isTest
    static void getGeoCodeDataTest() {
        Test.startTest();
        String address = '417 Mission Street, San Francisco, California 94105 USA';
        Map<String, Object> myData = new Map<String, Object>{ 'address' => address };
        InfoTabController.ResponseWrapper response = InfoTabController.getGeoCodeData(myData);
        Test.stopTest();
        Map<String, Object> data = (Map<String, Object>) response.result.get('data');
        Map<String, Object> position = (Map<String, Object>) data.get('position');
        System.assertEquals(37.7897784, (Decimal) position.get('lat'), 'Latitude does not match');
        System.assertEquals(-122.3973206, (Decimal) position.get('lng'), 'Longitude does not match');
    }

    @isTest
    static void getDTVAddressRegExTest() {
        Test.startTest();
        InfoTabController.ResponseWrapper res = InfoTabController.getDTVAddressRegEx();
        Test.stopTest();

        Assert.isNotNull(
            res.result.get('dtvAddressRegEx'),
            'No regular expression was returned in the dtvAddressRegEx field.'
        );
    }
    @isTest
    static void saveACIPresentationTest() {
        POE_Retail_Store__c store = new POE_Retail_Store__c();
        store.Name = 'Test Store';
        store.Location__latitude__s = 34.000;
        store.Location__longitude__s = 50.000;
        store.POE_City__c = 'San Francisco';
        store.POE_State__c = 'California';
        store.POE_Street_Address__c = 'Test Street';
        store.POE_Zip_Code__c = '94105';
        insert store;

        POE_Clicker_Retail_Track__c track = new POE_Clicker_Retail_Track__c();
        track.POE_Store__c = store.Id;
        insert track;

        Opportunity opp = new Opportunity(
            Maps_PostalCode__c = '1234',
            Maps_Street__c = 'Test street',
            Maps_AptNumber__c = '1234',
            Maps_Building__c = '4',
            Maps_City__c = 'Test city',
            Maps_Country__c = 'test country',
            Maps_Floor__c = '3',
            Maps_Latitude__c = 1.23151,
            Maps_Longitude__c = 2.4214,
            Maps_State__c = 'Texas',
            Name = 'Test Retail Opportunity',
            POE_Clicker_Origin__c = 'retail',
            StageName = 'Contact',
            CloseDate = Date.today()
        );
        insert opp;

        Map<String, Object> myData = new Map<String, Object>{ 'ContextId' => opp.Id };
        test.startTest();
        String res = InfoTabController.saveACIPresentation(JSON.serialize(myData));
        test.stopTest();

        List<POE_ACI_Statistic__c> aciStatistic = [
            SELECT Id, Product_Selection__c, Presentation__c, Store__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
        ];

        List<Opportunity> updatedOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];

        Assert.isTrue(!aciStatistic.isEmpty(), 'ACI Statistic was not created properly');
        Assert.areEqual(store.Id, aciStatistic[0].Store__c, 'Store does not match');
        Assert.areEqual('DM', updatedOpportunity[0].StageName, 'Opportunity Stage was not updated properly');
    }

    @isTest
    static void getAccountFSLDatesConfigTest() {
        UserRole userrole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        User adminUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;
        update adminUser;
        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];

        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test User Account',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
                P10_Invoice_Account__c = 'Example',
                recordTypeId = rtype.Id,
                POE_FSL_Dates_Enabled__c = true
            );
            insert testAcc;
            Contact userContact = new Contact(
                FirstName = 'test',
                LastName = 'test',
                AccountId = testAcc.Id,
                POE_Functional_Role__c = 'Team Lead'
            );
            insert userContact;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'Owner Profile'];
            User u = new User(
                Alias = 'standt',
                Email = 'getAccountFSLDatesConfigTest11042024@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'getAccountFSLDatesConfigTest11042024@testorg.com'
            );
            insert u;

            PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'FSL_Dates' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetGroupId = psg.Id);
            insert psa;
        }

        User newUser = [
            SELECT Id
            FROM User
            WHERE UserName = 'getAccountFSLDatesConfigTest11042024@testorg.com'
            LIMIT 1
        ];
        Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();

        System.runAs(newUser) {
            Test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.getAccountFSLDatesConfig();
            Test.stopTest();

            Assert.isTrue(
                (Boolean) response.result.get('isFSLDatesEnabled'),
                'The isFSLDatesEnabled field in the response result did not match the value of the POE_FSL_Dates_Enabled__c field.'
            );
            Assert.AreEqual(
                settings.FSL_Work_Type_Id__c,
                (String) response.result.get('defaultWorkTypeId'),
                'The defaultWorkTypeId field in the response did not match the Chuzo Settings OWD.'
            );
        }
    }

    @isTest
    static void getWorkOrderIdByServiceAppIdTest() {
        WorkOrder testWO = new WorkOrder(Vendor__c = 'DIRECTV', CurrencyIsoCode = 'USD');
        insert testWO;

        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = testWO.Id, Status = 'Unscheduled');
        insert sa;

        Map<String, Object> myData = new Map<String, Object>{ 'serviceAppointmentId' => sa.Id };

        Test.startTest();
        InfoTabController.ResponseWrapper response = InfoTabController.getWorkOrderIdByServiceAppId(myData);
        Test.stopTest();

        String woId = (String) response.result.get('workOrderId');
        Assert.areEqual(testWO.Id, woId, 'The retrieved Work Order Id does not match the expected one.');
    }
    @isTest
    static void testGetAgentReferralCodes() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;
        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];
        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test User Account',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
                P10_Invoice_Account__c = 'Example',
                recordTypeId = rtype.Id
            );
            insert testAcc;

            Contact userContact = new Contact(
                FirstName = 'test',
                LastName = 'test',
                AccountId = testAcc.Id,
                POE_Functional_Role__c = 'Office Manager'
            );
            insert userContact;

            Profile p = TestHelper.getGeneralProfile();
            User u = new User(
                Alias = 'standt',
                Email = '11052022standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '11052022GDGstandarduser@testorg.com'
            );
            insert u;
        }
        User newUser = [SELECT Id, ContactId FROM User WHERE Email = '11052022standarduser@testorg.com' LIMIT 1];

        Map<String, Object> myData = new Map<String, Object>{ 'userId' => newUser.Id };
        Test.startTest();
        test_InfoTabController.createReferralCodeData();
        Test.stopTest();
        List<Contact> contacts = [
            SELECT Id, Name, (SELECT Id, Agent__c, Referral_Code__c FROM Agent_ReferralCode_Associations__r)
            FROM Contact
            WHERE Id IN (SELECT ContactId FROM User WHERE Id = :newUser.Id)
        ];
        Assert.areEqual(10, contacts[0].Agent_ReferralCode_Associations__r.size(), 'Code were not assign correctly');
    }

    @isTest
    static void saveOpportunityReferralCodeTest() {
        Opportunity opp = new Opportunity(
            Maps_PostalCode__c = '1234',
            Maps_Street__c = 'Test street',
            Maps_AptNumber__c = '1234',
            Maps_Building__c = '4',
            Maps_City__c = 'Test city',
            Maps_Country__c = 'test country',
            Maps_Floor__c = '3',
            Maps_Latitude__c = 1.23151,
            Maps_Longitude__c = 2.4214,
            Maps_State__c = 'Texas',
            Name = 'Test Opportunity',
            POE_Clicker_Origin__c = 'phonesales',
            StageName = 'Contact',
            CloseDate = Date.today()
        );
        insert opp;
        Referral_Code__c referralCode = new Referral_Code__c(
            Referral_Code__c = 'TestReferralCode',
            Primary_Brand_Color__c = '#0324f',
            Secondary_Brand_Color__c = '#fcb10',
            Title__c = 'test',
            Subtitle__c = 'test',
            Body__c = 'test'
        );
        insert referralCode;
        Test.startTest();
        Map<String, Object> myData = new Map<String, Object>{ 'oppId' => opp.Id, 'referralCode' => referralCode.Id };
        InfoTabController.ResponseWrapper response = InfoTabController.saveOpportunityReferralCode(myData);
        Test.stopTest();
        Opportunity updatedOpp = (Opportunity) response.result.get('Opportunity');
        Assert.areEqual(updatedOpp.Referral_Code__c, referralCode.Id, 'Referral Code was not added properly');
    }

    @isTest
    static void getZipRestrictionsTest() {
        String zipCode = '11111';
        Test.startTest();
        Boolean response = InfoTabController.getRestrictedZips(zipCode);
        Test.stopTest();
        Assert.areEqual(false, response, 'Zip Code check was not properly done.');
    }

    @isTest
    static void testGetQuoteResumeDataAsOwner() {
        List<Opportunity> result = new List<Opportunity>();
        Opportunity mainOpp = [SELECT Id FROM Opportunity WHERE Maps_PostalCode__c = '75074' LIMIT 1];
        User runningUser = [SELECT Id FROM User WHERE Email = 'testuserquoteresumefrontier@example.com' LIMIT 1];

        Test.startTest();
        System.runAs(runningUser) {
            result = InfoTabController.getQuoteResumeData(mainOpp.Id);
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'There should be some related opportunities returned');
    }

    @isTest
    static void testGetQuoteResumeDataAsNonOwner() {
        List<Opportunity> result = new List<Opportunity>();
        Contact con = [SELECT Id FROM Contact WHERE Email = 'contact@example.com' LIMIT 1];
        con.POE_Functional_Role__c = 'Office Representative';
        update con;

        User runningUser = [SELECT Id FROM User WHERE Email = 'testuserquoteresumefrontier@example.com' LIMIT 1];
        Opportunity mainOpp = [SELECT Id FROM Opportunity WHERE Maps_PostalCode__c = '75074' LIMIT 1];

        Test.startTest();
        System.runAs(runningUser) {
            result = InfoTabController.getQuoteResumeData(mainOpp.Id);
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'There should be some related opportunities returned');
    }

    @future
    public static void createReferralCodeData() {
        User newUser = [SELECT Id, ContactId FROM User WHERE Email = '11052022standarduser@testorg.com' LIMIT 1];

        List<Referral_Code__c> newReferralCodes = new List<Referral_Code__c>();
        List<Agent_ReferralCode_Association__c> referralCodeAssociationsToCreate = new List<Agent_ReferralCode_Association__c>();
        for (Integer i = 0; i < 10; i++) {
            Referral_Code__c record = new Referral_Code__c(
                Referral_Code__c = 'TestReferralCode' + i,
                Primary_Brand_Color__c = '#0324f',
                Secondary_Brand_Color__c = '#fcb10',
                Title__c = 'test' + i,
                Subtitle__c = 'test' + i,
                Body__c = 'test' + i
            );
            newReferralCodes.add(record);
        }
        insert (newReferralCodes);

        if (newUser != null) {
            Id agentId = newUser.ContactId;
            for (Referral_Code__c rc : newReferralCodes) {
                Agent_ReferralCode_Association__c record = new Agent_ReferralCode_Association__c(
                    Agent__c = agentId,
                    Referral_Code__c = rc.Id
                );
                referralCodeAssociationsToCreate.add(record);
            }
            insert referralCodeAssociationsToCreate;
            Map<String, Object> myData = new Map<String, Object>{ 'userId' => newUser.Id };
            InfoTabController.ResponseWrapper response = InfoTabController.getAgentReferralCodes(myData);
        }
    }

    @isTest
    static void testUpdateProgramRestrictionNotification() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Program_Sales_Restriction__c> restrictions = new List<Program_Sales_Restriction__c>();
        List<String> validPrograms = new List<String>{ 'DirecTV', 'Frontier' };

        for (Integer i = 0; i < 2; i++) {
            restrictions.add(
                new Program_Sales_Restriction__c(
                    Account__c = testAccount.Id,
                    Program__c = validPrograms[i],
                    Limit__c = 10,
                    Start_Date__c = Date.today(),
                    End_Date__c = Date.today().addDays(30),
                    Notified__c = false,
                    Limit_Reached__c = false
                )
            );
        }
        insert restrictions;

        List<String> restrictionIds = new List<String>();
        for (Program_Sales_Restriction__c restriction : restrictions) {
            restrictionIds.add(restriction.Id);
        }

        Test.startTest();
        InfoTabController.updateProgramRestrictionNotification(restrictionIds);
        Test.stopTest();

        List<Program_Sales_Restriction__c> updatedRestrictions = [
            SELECT Id, Notified__c, Limit_Reached__c
            FROM Program_Sales_Restriction__c
            WHERE Id IN :restrictionIds
        ];

        for (Program_Sales_Restriction__c restriction : updatedRestrictions) {
            System.assertEquals(true, restriction.Notified__c, 'Notified field should be true');
            System.assertEquals(true, restriction.Limit_Reached__c, 'Limit_Reached field should be true');
        }
    }

    @isTest
    static void testSaveTransactionId() {
        // Get the test opportunity created in makeData()
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        String testTransactionId = 'TEST_TRANSACTION_12345';

        Map<String, Object> myData = new Map<String, Object>{
            'transactionId' => testTransactionId,
            'recordId' => testOpp.Id
        };

        System.runAs(u) {
            Test.startTest();
            InfoTabController.ResponseWrapper response = InfoTabController.saveTransactionId(myData);
            Test.stopTest();

            // Verify the response
            System.assertNotEquals(null, response, 'Response should not be null');
            System.assertNotEquals(null, response.result, 'Response result should not be null');
            System.assertEquals(
                testTransactionId,
                (String) response.result.get('transactionId'),
                'Transaction ID should match'
            );

            // Verify the opportunity was updated
            Opportunity updatedOpp = [SELECT Id, Frontier_Quote_ID__c FROM Opportunity WHERE Id = :testOpp.Id];
            System.assertEquals(
                testTransactionId,
                updatedOpp.Frontier_Quote_ID__c,
                'Frontier_Quote_ID__c should be updated with transaction ID'
            );
        }
    }
}