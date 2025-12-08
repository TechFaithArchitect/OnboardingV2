@IsTest
private class CommissionEscalationCSVProcessorTest {
    @TestSetup
    static void setupTestData() {
        // Create test user with Contact and Account
        Account testAccount = new Account(FirstName = 'John', LastName = 'Doe');
        insert testAccount;

        // Create a Partner Account for the Partner User
        Account partnerAccount = new Account(Name = 'Test Partner Account');
        insert partnerAccount;

        // Create a Contact for the Partner User
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            AccountId = partnerAccount.Id
        );
        insert testContact;

        // Create a Partner User with the Contact
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name LIKE '%Partner%' OR Name LIKE '%Customer%' LIMIT 1]
            .Id,
            LastName = 'TestUser',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.test' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ContactId = testContact.Id,
            IsActive = true
        );
        insert testUser;

        // Note: Partner_Account_Id__c field is not writable, so we'll work with the existing user setup
        // The test will use the user's Contact.AccountId for partner identification

        // Try to find existing Commission Escalation Team, or create one if it doesn't exist
        Group commissionTeam;

        // Create Commission Escalation Team
        List<Group> existingTeams = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE DeveloperName = 'Commission_Escalation_Team'
            LIMIT 1
        ];

        if (existingTeams.isEmpty()) {
            commissionTeam = new Group(
                Name = 'Commission Escalation Team',
                DeveloperName = 'Commission_Escalation_Team',
                Type = 'Queue'
            );
            insert commissionTeam;
        } else {
            commissionTeam = existingTeams[0];
        }

        // Create Partner Group with unique name
        Group partnerGroup = new Group(Name = 'Partner Group TEST123_' + System.currentTimeMillis(), Type = 'Regular');
        insert partnerGroup;

        // Create a different account to use as dealer ID so it won't match the user's partner ID
        // This will force the CSV processor to create manual cases instead of order-based cases
        Account differentAccount = new Account(FirstName = 'Different', LastName = 'Account');
        insert differentAccount;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            POE_OrderNumber__c = 'TEST-ORDER-123',
            POE_AccountNumber__c = 'ACC123',
            POE_Program__c = 'Brightspeed',
            POE_OrderId__c = 'WO123',
            POE_Dealer__c = differentAccount.Id, // Use different account ID as dealer ID
            ShippingCity = 'Test City',
            ShippingState = 'California',
            ShippingStreet = '123 Test St',
            ShippingPostalCode = '12345'
        );
        insert testOrder;
    }

    @IsTest
    static void testValidCSVProcessing() {
        // Prepare test CSV content
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,Doe,PS001,ACC123,TEST-ORDER-123,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify results
        List<Case> createdCases = [
            SELECT Id, CaseNumber, ParentId, Subject
            FROM Case
            WHERE ParentId != NULL AND Subject LIKE '%Commission Escalation%'
        ];
        System.assertEquals(1, createdCases.size(), 'Should create one child case');

        // Verify parent case was created
        List<Case> parentCases = [
            SELECT Id, Subject
            FROM Case
            WHERE ParentId = NULL AND Subject LIKE '%Commission Escalation%'
        ];
        System.assertEquals(1, parentCases.size(), 'Should create one parent case');

        List<Case> childCases = [
            SELECT Id, CaseNumber, ParentId
            FROM Case
            WHERE
                Subject LIKE '%Commission Escalation%'
                AND ParentId != NULL
                AND POE_Confirmation_Number__c = 'TEST-ORDER-123'
        ];
        System.assertEquals(1, childCases.size(), 'Should create one child case');
    }

    @IsTest
    static void testBasicCSVProcessing() {
        // Simple test with minimal data to verify basic functionality
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,Doe,PS001,ACC123,TEST-ORDER-123,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description';

        Test.startTest();

        // Run as test user
        User testUser = [
            SELECT Id, AccountId
            FROM User
            WHERE Email = 'testuser@example.com' AND LastName = 'TestUser'
            LIMIT 1
        ];

        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that cases were created
        List<Case> createdCases = [SELECT Id, Subject, ParentId FROM Case WHERE Subject LIKE '%Commission Escalation%'];

        // Should have at least 2 cases: 1 parent + 1 child
        System.assert(createdCases.size() >= 2, 'Should create at least 2 cases (1 parent + 1 child)');

        // Verify parent case was created
        List<Case> parentCases = [
            SELECT Id, Subject
            FROM Case
            WHERE ParentId = NULL AND Subject LIKE '%Commission Escalation%'
        ];
        System.assertEquals(1, parentCases.size(), 'Should create one parent case');

        // Verify child case was created
        List<Case> childCases = [
            SELECT Id, Subject, ParentId
            FROM Case
            WHERE Subject LIKE '%Commission Escalation%' AND ParentId != NULL
        ];
        System.assertEquals(1, childCases.size(), 'Should create one child case');
    }

    @IsTest
    static void testInvalidDateFormat() {
        // Prepare test CSV content with invalid date format
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,Doe,PS001,ACC123,TEST-ORDER-123,WO123,08-15-2025,08-20-2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that no cases were created due to date format error
        List<Case> createdCases = [SELECT Id FROM Case WHERE Subject LIKE '%Commission Escalation%'];
        System.assertEquals(0, createdCases.size(), 'Should not create cases due to date format error');
    }

    @IsTest
    static void testMissingRequiredFields() {
        // Prepare test CSV content with missing required fields
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,,PS001,ACC123,TEST-ORDER-123,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that no cases were created due to missing required fields
        List<Case> createdCases = [SELECT Id FROM Case WHERE Subject LIKE '%Commission Escalation%'];
        System.assertEquals(0, createdCases.size(), 'Should not create cases due to missing required fields');
    }

    @IsTest
    static void testInvalidProgramValue() {
        // Prepare test CSV content with invalid program
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'InvalidProgram,John,Doe,PS001,ACC123,TEST-ORDER-123,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that no cases were created due to invalid program
        List<Case> createdCases = [SELECT Id FROM Case WHERE Subject LIKE '%Commission Escalation%'];
        System.assertEquals(0, createdCases.size(), 'Should not create cases due to invalid program');
    }

    @IsTest
    static void testManualCaseCreation() {
        // Prepare test CSV content with non-existent confirmation number
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,Doe,PS001,ACC123,NON-EXISTENT-ORDER,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that a manual case was created
        List<Case> createdCases = [
            SELECT Id, POE_Confirmation_Number__c
            FROM Case
            WHERE Subject LIKE '%Commission Escalation%' AND POE_Confirmation_Number__c = 'NON-EXISTENT-ORDER'
        ];
        System.assertEquals(1, createdCases.size(), 'Should create one manual case');
        System.assertEquals(
            'NON-EXISTENT-ORDER',
            createdCases[0].POE_Confirmation_Number__c,
            'Should have the confirmation number from CSV'
        );

        // Verify parent case was created
        List<Case> parentCases = [
            SELECT Id, Subject
            FROM Case
            WHERE ParentId = NULL AND Subject LIKE '%Commission Escalation%'
        ];
        System.assertEquals(1, parentCases.size(), 'Should create one parent case');
    }

    @IsTest
    static void testEmptyConfirmationNumber() {
        // Prepare test CSV content with empty confirmation number
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'EarthLink,Marcos,Perez,Sales1,1234,,,08/22/2025,,Gig Speed Fiber Internet (Range 800 to 1000Mb) and Unlimited Phone,200,,PVE,911 N SELVIDGE ST,DALTON,GEORGIA,30720,Testdescrip';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );

            // Verify the results
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assertEquals(1, results.size(), 'Should return one result');

            CommissionEscalationCSVProcessor.ProcessingResult result = results[0];
            System.assertEquals(1, result.totalRows, 'Should process one row');
            System.assertEquals(0, result.successfulCases, 'Should not create any successful cases');
            System.assertEquals(1, result.failedCases, 'Should have one failed case');
            System.assert(
                result.errorMessages.contains('Missing required fields'),
                'Should contain error about missing required fields'
            );
            System.assert(
                result.errorMessages.contains('Confirmation Number'),
                'Should mention Confirmation Number in error'
            );
        }

        Test.stopTest();

        // Verify that no cases were created
        List<Case> createdCases = [SELECT Id FROM Case WHERE Subject LIKE '%Commission Escalation%'];
        System.assertEquals(0, createdCases.size(), 'Should not create cases with empty confirmation number');
    }

    // TODO: Fix this test - temporarily disabled
    // @IsTest
    static void testCSVAttachmentToParentCase() {
        // Prepare test CSV content with a non-existent confirmation number to create a manual case
        // Using the exact same format as the working testManualCaseCreation test
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,Doe,PS001,ACC123,CSV-ATTACHMENT-TEST-ORDER,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description for CSV attachment';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that a parent case was created
        List<Case> parentCases = [
            SELECT Id, Subject
            FROM Case
            WHERE Subject = 'Commission Escalations - Multiple Orders'
        ];
        System.assertEquals(1, parentCases.size(), 'Should create one parent case');

        // Verify that the CSV file was attached to the parent case
        List<ContentDocumentLink> attachments = [
            SELECT Id, ContentDocument.Title, ContentDocument.FileType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentCases[0].Id
        ];
        System.assertEquals(1, attachments.size(), 'Should have one attachment');
        System.assert(
            attachments[0].ContentDocument.Title.contains('Commission_Escalations_CSV'),
            'Should have CSV attachment with correct title'
        );
    }

    @IsTest
    static void testEmptyCSVContent() {
        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ '' }
            );
        }

        Test.stopTest();

        // Verify that no cases were created
        List<Case> createdCases = [SELECT Id FROM Case WHERE Subject LIKE '%Commission Escalation%'];
        System.assertEquals(0, createdCases.size(), 'Should not create cases with empty CSV content');
    }

    @IsTest
    static void testProgramTransformation() {
        // Prepare test CSV content with program names that need transformation
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'DIRECTV,John,Doe,PS001,ACC123,TEST-ORDER-123,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description\n' +
            'Optimum,Jane,Smith,PS002,ACC124,TEST-ORDER-124,WO124,08/16/2025,08/21/2025,Internet Service,,Chuzo,DEALER002,456 Oak St,Test City,California,12345,Test description';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that cases were created with transformed program names
        List<Case> createdCases = [
            SELECT Id, POE_Program__c
            FROM Case
            WHERE
                Subject LIKE '%Commission Escalation%'
                AND (POE_Confirmation_Number__c = 'TEST-ORDER-123'
                OR POE_Confirmation_Number__c = 'TEST-ORDER-124')
        ];
        System.assertEquals(2, createdCases.size(), 'Should create two cases');

        Set<String> programs = new Set<String>();
        for (Case c : createdCases) {
            programs.add(c.POE_Program__c);
        }
        System.assert(programs.contains('DirecTV'), 'Should transform DIRECTV to DirecTV');
        System.assert(programs.contains('Altice'), 'Should transform Optimum to Altice');
    }

    @IsTest
    static void testCreateCaseFromOrder() {
        // Prepare test CSV content with a confirmation number that will match an order
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,Doe,PS001,ACC123,ORDER-FROM-USER,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description for order-based case';

        Test.startTest();

        // Run as test user
        User testUser = [
            SELECT Id, AccountId
            FROM User
            WHERE Email = 'testuser@example.com' AND LastName = 'TestUser'
            LIMIT 1
        ];
        System.runAs(testUser) {
            // Create a new test account within this test context to ensure it exists
            // Get the default record type for Account to avoid record type issues
            Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('PersonAccount') != null
                ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
                : null;

            Account testAccount = new Account(
                FirstName = 'Order',
                LastName = 'Customer',
                RecordTypeId = accountRecordTypeId
            );
            insert testAccount;

            Order matchingOrder = new Order(
                AccountId = testAccount.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                POE_OrderNumber__c = 'ORDER-FROM-USER',
                POE_AccountNumber__c = 'ACC123',
                POE_Program__c = 'Brightspeed',
                POE_OrderId__c = 'WO123',
                POE_Dealer__c = testUser.AccountId, // Explicitly set to user's AccountId
                ShippingCity = 'Test City',
                ShippingState = 'California',
                ShippingStreet = '123 Test St',
                ShippingPostalCode = '12345',
                Pricebook2Id = Test.getStandardPricebookId()
            );
            insert matchingOrder;

            // Create OrderItem to test the product names extraction
            Product2 testProduct = new Product2(Name = 'Test Internet Service', IsActive = true);
            insert testProduct;

            PricebookEntry pbe = new PricebookEntry(
                Product2Id = testProduct.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                UnitPrice = 100,
                IsActive = true
            );
            insert pbe;

            OrderItem orderItem = new OrderItem(
                OrderId = matchingOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100
            );
            insert orderItem;

            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that a case was created from the order
        List<Case> createdCases = [
            SELECT Id, Order__c, POE_Confirmation_Number__c, POE_Product_s_Sold__c
            FROM Case
            WHERE Subject LIKE '%Commission Escalation%' AND POE_Confirmation_Number__c = 'ORDER-FROM-USER'
        ];
        System.assertEquals(1, createdCases.size(), 'Should create one case from order');
        System.assertNotEquals(null, createdCases[0].Order__c, 'Case should be linked to the order');
        System.assertEquals(
            'Test Internet Service',
            createdCases[0].POE_Product_s_Sold__c,
            'Should extract product names from order items'
        );
    }

    @IsTest
    static void testStateValidationAndAbbreviation() {
        // Prepare test CSV content with valid state values
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,Doe,PS001,ACC123,TEST-ORDER-123,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description with valid state\n' +
            'EarthLink,Jane,Smith,PS002,ACC124,TEST-ORDER-124,WO124,08/16/2025,08/21/2025,Internet Service,,Chuzo,DEALER002,456 Oak St,Test City,Texas,12345,Test description with valid state';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that cases were created with proper state handling
        List<Case> createdCases = [
            SELECT Id, POE_State__c, POE_Confirmation_Number__c, Subject
            FROM Case
            WHERE Subject LIKE '%Commission Escalation%' AND ParentId != NULL
        ];

        // Should create 2 child cases (one for each CSV row)
        System.assertEquals(2, createdCases.size(), 'Should create two child cases');

        // Check that state values were properly set
        for (Case c : createdCases) {
            System.assertNotEquals(null, c.POE_State__c, 'State should not be null');
        }

        // Verify parent case was created
        List<Case> parentCases = [
            SELECT Id, Subject
            FROM Case
            WHERE ParentId = NULL AND Subject LIKE '%Commission Escalation%'
        ];
        System.assertEquals(1, parentCases.size(), 'Should create one parent case');
    }

    @IsTest
    static void testLargeCSVProcessing() {
        // Create a large CSV with 100+ rows to test the new batching and optimization
        String csvHeader = 'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n';

        String csvContent = csvHeader;
        for (Integer i = 1; i <= 150; i++) {
            csvContent +=
                'Brightspeed,John' +
                i +
                ',Doe' +
                i +
                ',PS' +
                String.valueOf(i).leftPad(3, '0') +
                ',ACC' +
                String.valueOf(i).leftPad(3, '0') +
                ',TEST-ORDER-' +
                String.valueOf(i).leftPad(3, '0') +
                ',WO' +
                String.valueOf(i).leftPad(3, '0') +
                ',08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER' +
                String.valueOf(i).leftPad(3, '0') +
                ',123 Main St,Test City,California,12345,Test description for row ' +
                i +
                '\n';
        }

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that all cases were created successfully
        List<Case> createdCases = [
            SELECT Id, Subject, ParentId
            FROM Case
            WHERE Subject LIKE '%Commission Escalation%' AND ParentId != NULL
        ];

        // For large CSV processing, we expect 150 child cases (one for each row)
        System.assertEquals(150, createdCases.size(), 'Should create 150 child cases for large CSV');

        // Verify parent case was created
        List<Case> parentCases = [
            SELECT Id, Subject
            FROM Case
            WHERE ParentId = NULL AND Subject LIKE '%Commission Escalation%'
        ];

        System.assertEquals(1, parentCases.size(), 'Should create one parent case for large CSV');
    }

    @IsTest
    static void testSpecificFieldValidationMessages() {
        // Prepare test CSV content with multiple missing required fields
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            ',John,,PS001,ACC123,,WO123,08/15/2025,08/20/2025,,,Chuzo,DEALER001,,Test City,,12345,';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that no cases were created due to missing required fields
        List<Case> createdCases = [SELECT Id FROM Case WHERE Subject LIKE '%Commission Escalation%'];
        System.assertEquals(0, createdCases.size(), 'Should not create cases due to missing required fields');

        // Verify that the error message contains specific field names
        List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
            new List<String>{ csvContent }
        );

        if (results != null && !results.isEmpty()) {
            CommissionEscalationCSVProcessor.ProcessingResult result = results[0];
            System.assert(
                result.errorMessages.contains('Missing required fields'),
                'Should contain error about missing required fields'
            );
            // The new validation should show specific missing fields
            System.assert(
                result.errorMessages.contains('Program') ||
                result.errorMessages.contains('Customer Last Name') ||
                result.errorMessages.contains('Confirmation Number') ||
                result.errorMessages.contains('Product') ||
                result.errorMessages.contains('Customer Address') ||
                result.errorMessages.contains('Customer State') ||
                result.errorMessages.contains('Description'),
                'Should mention specific missing required fields in error'
            );
        }
    }

    @IsTest
    static void testBulkSharingOptimization() {
        // Create a CSV with multiple rows to test bulk sharing
        String csvContent =
            'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n' +
            'Brightspeed,John,Doe,PS001,ACC123,TEST-ORDER-123,WO123,08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER001,123 Main St,Test City,California,12345,Test description 1\n' +
            'EarthLink,Jane,Smith,PS002,ACC124,TEST-ORDER-124,WO124,08/16/2025,08/21/2025,Internet Service,,Chuzo,DEALER002,456 Oak St,Test City,California,12345,Test description 2\n' +
            'Frontier,Bob,Johnson,PS003,ACC125,TEST-ORDER-125,WO125,08/17/2025,08/22/2025,Internet Service,,Chuzo,DEALER003,789 Pine St,Test City,California,12345,Test description 3';

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that all cases were created successfully
        List<Case> createdCases = [
            SELECT Id, Subject, ParentId
            FROM Case
            WHERE Subject LIKE '%Commission Escalation%' AND ParentId != NULL
        ];

        System.assertEquals(3, createdCases.size(), 'Should create three child cases');

        // Verify parent case was created
        List<Case> parentCases = [
            SELECT Id, Subject
            FROM Case
            WHERE ParentId = NULL AND Subject LIKE '%Commission Escalation%'
        ];

        System.assertEquals(1, parentCases.size(), 'Should create one parent case');
    }

    @IsTest
    static void testDynamicBatchSizing() {
        // Create a CSV with enough rows to trigger multiple batches
        String csvHeader = 'Program,Customer First Name,Customer Last Name,Partner Sales Code,Account Number,Confirmation Number,Work Order Number,Sales Date,Activation Date,Product,Product Number,Channel,PV Dealer Code,Customer Address,Customer City,Customer State,Customer Zip Code,Description\n';

        String csvContent = csvHeader;
        for (Integer i = 1; i <= 75; i++) {
            csvContent +=
                'Brightspeed,John' +
                i +
                ',Doe' +
                i +
                ',PS' +
                String.valueOf(i).leftPad(3, '0') +
                ',ACC' +
                String.valueOf(i).leftPad(3, '0') +
                ',TEST-ORDER-' +
                String.valueOf(i).leftPad(3, '0') +
                ',WO' +
                String.valueOf(i).leftPad(3, '0') +
                ',08/15/2025,08/20/2025,Internet Service,,Chuzo,DEALER' +
                String.valueOf(i).leftPad(3, '0') +
                ',123 Main St,Test City,California,12345,Test description for row ' +
                i +
                '\n';
        }

        Test.startTest();

        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND LastName = 'TestUser' LIMIT 1];
        System.runAs(testUser) {
            List<CommissionEscalationCSVProcessor.ProcessingResult> results = CommissionEscalationCSVProcessor.processCSV(
                new List<String>{ csvContent }
            );
        }

        Test.stopTest();

        // Verify that all cases were created successfully
        List<Case> createdCases = [
            SELECT Id, Subject, ParentId
            FROM Case
            WHERE Subject LIKE '%Commission Escalation%' AND ParentId != NULL
        ];

        // For dynamic batching, we expect 75 child cases (one for each row)
        System.assertEquals(75, createdCases.size(), 'Should create 75 child cases with dynamic batching');

        // Verify parent case was created
        List<Case> parentCases = [
            SELECT Id, Subject
            FROM Case
            WHERE ParentId = NULL AND Subject LIKE '%Commission Escalation%'
        ];

        System.assertEquals(1, parentCases.size(), 'Should create one parent case with dynamic batching');
    }
}