@isTest(isParallel=false)
public class test_ProductTabController {
    @TestSetup
    static void makeData() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

        User testUser = new User(
            LastName = 'test',
            FirstName = 'test',
            Username = 'test@test.com.testclass',
            Email = 'test@test.com',
            ProfileId = profileId,
            emailencodingkey = 'UTF-8',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            country = 'United States',
            IsActive = true,
            timezonesidkey = 'America/Los_Angeles',
            Alias = 'testUser'
        );

        insert testUser;

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Product2 prod = new Product2(
            Name = 'Test Product',
            Description = 'test product',
            ProductCode = 'codetest',
            Family = 'test'
        );
        insert prod;

        POE_Windstream_Disclaimer__c disclaimer = new POE_Windstream_Disclaimer__c(Name = '1', Disclaimer__c = 'Test');
        insert disclaimer;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Presentation'
        );
        insert opp;

        ContentVersion version = new ContentVersion(
            Title = 'test',
            PathOnClient = 'test.jpg',
            VersionData = EncodingUtil.base64Decode('AA=='),
            Origin = 'H'
        );
        insert version;

        ContentVersion v2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

        ContentDocumentLink docLink = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = v2.ContentDocumentId
        );

        insert docLink;

        Chuzo_Settings__c settings = new Chuzo_Settings__c(
            DTV_Roadrunner_Project__c = true,
            Excluded_Products_Earthlink__c = 'Test1;Test2'
        );
        insert settings;
    }

    @isTest
    static void test_updatePricebookEntry() {
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];

        PricebookEntry pbEntry = new PricebookEntry(
            IsActive = false,
            Product2Id = prod.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 24
        );
        insert pbEntry;

        Opportunity opp = new Opportunity(Name = 'test opp', CloseDate = Date.today(), StageName = 'Prospecting');

        insert opp;

        POE_ACI_Statistic__c st = new POE_ACI_Statistic__c(Product_Selection__c = 0, Opportunity__c = opp.Id);

        insert st;

        Map<Object, Object> product = new Map<Object, Object>{ 'Name' => 'Test Product', 'UnitPrice' => 36 };

        Map<String, Object> data = new Map<String, Object>{
            'Product' => product,
            'ContextId' => opp.Id,
            'Program' => 'DirecTV',
            'OtherProducts' => new List<Object>{ (Object) product }
        };

        ProductTabController.ResponseWrapper response = new ProductTabController.ResponseWrapper();

        test.startTest();
        response = ProductTabController.saveProduct(data);
        test.stopTest();

        PricebookEntry resultpbe = [SELECT Id, IsActive, UnitPrice FROM PricebookEntry WHERE Id = :pbEntry.Id];
        List<OpportunityLineItem> oppLineItem = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];

        System.assertEquals(true, resultpbe.IsActive, 'PricebookEntry is not active');
        System.assertEquals(36, resultpbe.UnitPrice, 'Unit price does not match');
        System.assertEquals('Test Product', (String) response.result.get('ProductName'), 'Product name does not match');
        System.assertEquals(false, oppLineItem.isEmpty(), 'At least one opportunity line item must be created');
    }

    @isTest
    static void test_insertPricebookEntry() {
        Opportunity opp = new Opportunity(Name = 'test opp', CloseDate = Date.today(), StageName = 'Prospecting');

        insert opp;

        POE_ACI_Statistic__c st = new POE_ACI_Statistic__c(Product_Selection__c = 0, Opportunity__c = opp.Id);

        insert st;

        Map<Object, Object> product = new Map<Object, Object>{ 'Name' => 'Test Product', 'UnitPrice' => 36 };

        Map<String, Object> data = new Map<String, Object>{ 'Product' => product, 'ContextId' => opp.Id };

        ProductTabController.ResponseWrapper response = new ProductTabController.ResponseWrapper();

        test.startTest();
        response = ProductTabController.saveProduct(data);
        test.stopTest();

        PricebookEntry resultpbe = [SELECT Id, IsActive, UnitPrice FROM PricebookEntry LIMIT 1];

        System.assertEquals(true, resultpbe.IsActive, 'PricebookEntry is not active');
        System.assertEquals(36, resultpbe.UnitPrice, 'Unit price does not match');
        System.assertEquals('Test Product', (String) response.result.get('ProductName'), 'Product name does not match');
    }

    @isTest
    static void test_insertProduct() {
        Opportunity opp = new Opportunity(Name = 'test opp', CloseDate = Date.today(), StageName = 'Prospecting');

        insert opp;

        POE_ACI_Statistic__c st = new POE_ACI_Statistic__c(Product_Selection__c = 0, Opportunity__c = opp.Id);

        insert st;

        Map<Object, Object> product = new Map<Object, Object>{
            'Name' => 'Test Product 2',
            'UnitPrice' => 36,
            'servRef' => 'newProduct',
            'Family' => 'Test2',
            'Description' => 'new product'
        };

        Map<String, Object> data = new Map<String, Object>{ 'Product' => product, 'ContextId' => opp.Id };

        ProductTabController.ResponseWrapper response = new ProductTabController.ResponseWrapper();

        test.startTest();
        response = ProductTabController.saveProduct(data);
        test.stopTest();

        PricebookEntry resultpbe = [SELECT Id, IsActive, UnitPrice FROM PricebookEntry LIMIT 1];
        Product2 newProduct = [SELECT Id, ProductCode, Family, Description FROM Product2 WHERE Name = 'Test Product 2'];

        System.assertEquals(true, resultpbe.IsActive, 'pricebookentry is not active');
        System.assertEquals(36, resultpbe.UnitPrice, 'unit price does not match');
        System.assertEquals('Test2', newProduct.Family, 'product family does not match');
        System.assertEquals('newProduct', newProduct.ProductCode, 'product code does not match');
        System.assertEquals('new product', newProduct.Description, 'product description do not match');
        System.assertEquals(
            'Test Product 2',
            (String) response.result.get('ProductName'),
            'Product name does not match'
        );
    }

    @isTest
    static void getWindstreamDisclaimersTest() {
        Test.startTest();
        ProductTabController.ResponseWrapper response = ProductTabController.getWindstreamDisclaimers();
        Test.stopTest();

        List<POE_Windstream_Disclaimer__c> resultDisclaimers = (List<POE_Windstream_Disclaimer__c>) response.result.get(
            'Disclaimers'
        );
        System.assert(resultDisclaimers != null, 'The Disclaimers node was not included or null in the result.');
        Integer wsDisclaimerCount = [SELECT COUNT() FROM POE_Windstream_Disclaimer__c];
        System.assertEquals(
            wsDisclaimerCount,
            resultDisclaimers.size(),
            'The Disclaimers node did not include all of the Windstream Disclaimer records.'
        );
    }

    @isTest
    static void getRoadRunnerFlagTest() {
        Test.startTest();
        Chuzo_Settings__c response = ProductTabController.getDTVProjectsFlag();
        Test.stopTest();
        System.assertEquals(true, response.DTV_Roadrunner_Project__c, 'Road Runner flag was not fetched');
    }

    @isTest
    static void getExcludedProductsTest() {
        Test.startTest();
        ProductTabController.ResponseWrapper response = ProductTabController.getEarthLinkExcludedProducts();
        Test.stopTest();
        List<Chuzo_Settings__c> settings = (List<Chuzo_Settings__c>) response.result.get('Excluded Products');
        System.assertEquals(
            'Test1;Test2',
            settings[0].Excluded_Products_Earthlink__c,
            'Excluded products list was not fetched'
        );
    }

    @isTest
    static void getSBSFileTest() {
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        Opportunity opp = opps[0];
        test.startTest();
        ProductTabController.ResponseWrapper response = ProductTabController.getSBSFile(
            new Map<String, Object>{ 'ContextId' => opp.Id }
        );
        test.stopTest();

        String docId = (String) response.result.get('Id');

        System.assert(docId != null, 'Response should not be null');
    }

    @isTest
    static void saveSBSFileTest() {
        Account acc = new Account(Name = 'test account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            CloseDate = System.Today(),
            Maps_PostalCode__c = '72212',
            StageName = 'Opportunity'
        );
        insert opp;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String mockContent = 'Unit Test Attachment Body';
        inputMap.put('ContextId', opp.Id);
        inputMap.put('strSignElement', mockContent);
        inputMap.put('Update', false);

        Test.startTest();
        ProductTabController.ResponseWrapper response = ProductTabController.saveSBSFile(inputMap);
        Test.stopTest();
        System.assert((ContentVersion) response.result.get('cVersion') != null, 'Insert failed');
    }

    @isTest
    static void getInternationalPackage_test() {
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
                recordTypeId = rtype.Id,
                POE_Espanol_Package__c = true
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
            ProductTabController.ResponseWrapper response = ProductTabController.GetInternationalPackage();
            test.stopTest();

            Map<String, Object> accounts = (Map<String, Object>) response.result.get('Account');

            System.assert((Boolean) accounts.get('POE_Espanol_Package__c'), 'Espanol pakacke boolean must be true');
        }
    }
    @isTest
    static void testGetViasatBNLData() {
        Viasat_BNL_Form_Settings__c viasatSetting = new Viasat_BNL_Form_Settings__c(
            leadSource__c = 'TestLeadSource',
            viasatOrgUrl__c = 'https://www.example.com'
        );
        insert viasatSetting;

        Test.startTest();

        ProductTabController.ResponseWrapper response = ProductTabController.getViasatBNLData();
        Test.stopTest();

        System.assert.areNotEqual(null, response);
        System.assert.areEqual(UserInfo.getOrganizationId(), (String) response.result.get('orgId'));
        System.assert.areEqual('TestLeadSource', (String) response.result.get('leadSource__c'));
        System.assert.areEqual('https://www.example.com', (String) response.result.get('viasatOrgUrl__c'));
    }

    @isTest
    static void getVideoFlagTest() {
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
                recordTypeId = rtype.Id,
                POE_Espanol_Package__c = true
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
            Test.startTest();
            Boolean response = ProductTabController.getVideoFlag();
            Test.stopTest();
            System.assertEquals(false, response, 'Video flag was not fetched');
        }
    }

    @isTest
    static void test_saveOrderItems_insert() {
        Account acc = new Account(Name = 'Order Test Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Order Test Opp',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        insert opp;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update pb;
        Order ord = new Order(
            AccountId = acc.Id,
            OpportunityId = opp.Id,
            Pricebook2Id = pb.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;
        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Product A',
                'code' => 'CODEA',
                'family' => 'FamA',
                'description' => 'DescA',
                'price' => 10
            },
            new Map<String, Object>{
                'name' => 'Product B',
                'code' => 'CODEB',
                'family' => 'FamB',
                'description' => 'DescB',
                'price' => 20
            }
        };
        Test.startTest();
        ProductTabController.ResponseWrapper resp = ProductTabController.saveOrderItems(items, ord.Id, true);
        Test.stopTest();
        List<OrderItem> orderItems = [
            SELECT Id, Product2Id, PricebookEntryId, UnitPrice
            FROM OrderItem
            WHERE OrderId = :ord.Id
        ];
        System.assertEquals(2, orderItems.size(), 'Should have 2 order items');
        List<Product2> products = [
            SELECT Id, Name, ProductCode, Family, Description
            FROM Product2
            WHERE ProductCode IN ('CODEA', 'CODEB')
        ];
        System.assertEquals(2, products.size(), 'Should have 2 products');
        List<PricebookEntry> pbes = [
            SELECT Id, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id = :pb.Id AND Product2Id IN :products
        ];
        System.assertEquals(2, pbes.size(), 'Should have 2 PBEs');
    }

    @isTest
    static void test_saveOrderItems_update() {
        Account acc = new Account(Name = 'Order Test Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Order Test Opp',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        insert opp;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update pb;
        Order ord = new Order(
            AccountId = acc.Id,
            OpportunityId = opp.Id,
            Pricebook2Id = pb.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;
        // Insert initial items
        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Product A',
                'code' => 'CODEA',
                'family' => 'FamA',
                'description' => 'DescA',
                'price' => 10
            },
            new Map<String, Object>{
                'name' => 'Product B',
                'code' => 'CODEB',
                'family' => 'FamB',
                'description' => 'DescB',
                'price' => 20
            }
        };
        ProductTabController.saveOrderItems(items, ord.Id, true);
        // Now update with only one item
        List<Map<String, Object>> items2 = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Product A',
                'code' => 'CODEA',
                'family' => 'FamA',
                'description' => 'DescA',
                'price' => 15
            }
        };
        Test.startTest();
        ProductTabController.ResponseWrapper resp2 = ProductTabController.saveOrderItems(items2, ord.Id, false);
        Test.stopTest();
        List<OrderItem> orderItems2 = [
            SELECT Id, Product2Id, PricebookEntryId, UnitPrice
            FROM OrderItem
            WHERE OrderId = :ord.Id
        ];
        System.assertEquals(1, orderItems2.size(), 'Should have 1 order item after update');
        System.assertEquals(15, orderItems2[0].UnitPrice, 'OrderItem price should be updated');
    }

    @isTest
    static void test_saveOrderItems_missingCode() {
        Account acc = new Account(Name = 'Order Test Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Order Test Opp',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        insert opp;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update pb;
        Order ord = new Order(
            AccountId = acc.Id,
            OpportunityId = opp.Id,
            Pricebook2Id = pb.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;
        Boolean caught = false;
        try {
            List<Map<String, Object>> badItems = new List<Map<String, Object>>{
                new Map<String, Object>{ 'name' => 'No Code', 'price' => 5 }
            };
            ProductTabController.saveOrderItems(badItems, ord.Id, false);
        } catch (Exception e) {
            caught = true;
        }
        System.assert(caught, 'Should throw if code is missing');
    }
}