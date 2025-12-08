@isTest
public class POE_ChuzoOpportunityListControllerTest {
    @TestSetup
    static void makeData() {
        Account testAcc = new Account(
            Name = 'Test',
            ShippingStreet = 'Test Street',
            POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com'
        );
        insert testAcc;

        Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
        insert userContact;

        Profile p = TestHelper.getGeneralProfile();
        User u = new User(
            Alias = 'standt',
            Email = '11052082standarduser@testorg.com',
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

        Opportunity opp1 = new Opportunity(
            Name = 'TEST1',
            CloseDate = System.today(),
            OwnerId = u.Id,
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp1;
        Opportunity opp2 = new Opportunity(
            Name = 'TEST2',
            CloseDate = System.today(),
            OwnerId = u.Id,
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp2;
        Opportunity opp3 = new Opportunity(
            Name = 'TEST3',
            CloseDate = System.today(),
            OwnerId = u.Id,
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp3;
    }

    @isTest
    static void testGetOppotunities() {
        User testUser = [SELECT Id FROM User WHERE Name = 'Testing' LIMIT 1];
        List<Opportunity> pp = [SELECT Id, Owner.Name FROM Opportunity];
        Map<String, Object> testInput = new Map<String, Object>{
            'viewType' => POE_ChuzoOpportunityListController.ALL_OPPORTUNITIES_VT
        };

        System.runAs(testUser) {
            test.startTest();
            poe_ChuzoOpportunityListController.ResponseWrapper response = poe_ChuzoOpportunityListController.getOpportunities(
                testInput
            );
            test.stopTest();

            List<Opportunity> opps = (List<Opportunity>) response.result.get('opportunities');

            Assert.areEqual(3, opps.size(), 'No opps founded');
        }
    }

    @isTest
    static void testGetAccountInformation() {
        User testUser = [SELECT Id FROM User WHERE Name = 'Testing' LIMIT 1];
        Map<String, Object> testInput = new Map<String, Object>{ 'filter' => 'none' };

        System.runAs(testUser) {
            test.startTest();
            poe_ChuzoOpportunityListController.ResponseWrapper response = poe_ChuzoOpportunityListController.getAccountInformation(
                testInput
            );
            test.stopTest();

            List<Account> accounts = (List<Account>) response.result.get('accounts');
            Set<Id> completedSalesIds = (Set<Id>) response.result.get('completed');

            Assert.isNotNull(accounts, 'Accounts should not be null');
            Assert.isNotNull(completedSalesIds, 'Completed sales IDs should not be null');
            Assert.isTrue(accounts.size() <= 200, 'Should return maximum 200 accounts');
        }
    }

    @isTest
    static void testGetAccountInformationWithFilter() {
        User testUser = [SELECT Id FROM User WHERE Name = 'Testing' LIMIT 1];
        Map<String, Object> testInput = new Map<String, Object>{ 'filter' => 'Test' };

        System.runAs(testUser) {
            test.startTest();
            poe_ChuzoOpportunityListController.ResponseWrapper response = poe_ChuzoOpportunityListController.getAccountInformation(
                testInput
            );
            test.stopTest();

            List<Account> accounts = (List<Account>) response.result.get('accounts');
            Set<Id> completedSalesIds = (Set<Id>) response.result.get('completed');

            Assert.isNotNull(accounts, 'Accounts should not be null');
            Assert.isNotNull(completedSalesIds, 'Completed sales IDs should not be null');
            Assert.isTrue(accounts.size() <= 200, 'Should return maximum 200 accounts');
        }
    }

    @isTest
    static void testGetAccountInformationWithOrderCreatedOpportunities() {
        User testUser = [SELECT Id FROM User WHERE Name = 'Testing' LIMIT 1];

        // Create an account owned by the test user
        Account testAcc = new Account(
            Name = 'Test Account for Order Created',
            ShippingStreet = 'Test Street',
            POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
            OwnerId = testUser.Id
        );
        insert testAcc;

        // Create an opportunity with 'Order Created' stage
        Opportunity orderCreatedOpp = new Opportunity(
            Name = 'Order Created Test',
            CloseDate = System.today(),
            OwnerId = testUser.Id,
            AccountId = testAcc.Id,
            StageName = 'Order Created',
            Maps_PostalCode__c = '72212'
        );
        insert orderCreatedOpp;

        Map<String, Object> testInput = new Map<String, Object>{ 'filter' => 'none' };

        System.runAs(testUser) {
            test.startTest();
            poe_ChuzoOpportunityListController.ResponseWrapper response = poe_ChuzoOpportunityListController.getAccountInformation(
                testInput
            );
            test.stopTest();

            List<Account> accounts = (List<Account>) response.result.get('accounts');
            Set<Id> completedSalesIds = (Set<Id>) response.result.get('completed');

            Assert.isNotNull(accounts, 'Accounts should not be null');
            Assert.isNotNull(completedSalesIds, 'Completed sales IDs should not be null');
            Assert.isTrue(
                completedSalesIds.contains(testAcc.Id),
                'Should include account with Order Created opportunity'
            );
        }
    }

    @isTest
    static void testGetAccountInformationWithMultipleAccounts() {
        User testUser = [SELECT Id FROM User WHERE Name = 'Testing' LIMIT 1];

        // Create additional test accounts owned by the test user
        Account testAcc2 = new Account(
            Name = 'Test Account 2',
            ShippingStreet = 'Test Street 2',
            POE_Dealer_Office_Email__c = 'DealerEmail2@testorg1.com',
            OwnerId = testUser.Id
        );
        insert testAcc2;

        Account testAcc3 = new Account(
            Name = 'Test Account 3',
            ShippingStreet = 'Test Street 3',
            POE_Dealer_Office_Email__c = 'DealerEmail3@testorg1.com',
            OwnerId = testUser.Id
        );
        insert testAcc3;

        // Create opportunities for the new accounts
        Opportunity opp1 = new Opportunity(
            Name = 'Order Created Test 1',
            CloseDate = System.today(),
            OwnerId = testUser.Id,
            AccountId = testAcc2.Id,
            StageName = 'Order Created',
            Maps_PostalCode__c = '72212'
        );
        insert opp1;

        Opportunity opp2 = new Opportunity(
            Name = 'Order Created Test 2',
            CloseDate = System.today(),
            OwnerId = testUser.Id,
            AccountId = testAcc3.Id,
            StageName = 'Order Created',
            Maps_PostalCode__c = '72212'
        );
        insert opp2;

        Map<String, Object> testInput = new Map<String, Object>{ 'filter' => 'none' };

        System.runAs(testUser) {
            test.startTest();
            poe_ChuzoOpportunityListController.ResponseWrapper response = poe_ChuzoOpportunityListController.getAccountInformation(
                testInput
            );
            test.stopTest();

            List<Account> accounts = (List<Account>) response.result.get('accounts');
            Set<Id> completedSalesIds = (Set<Id>) response.result.get('completed');

            Assert.isNotNull(accounts, 'Accounts should not be null');
            Assert.isNotNull(completedSalesIds, 'Completed sales IDs should not be null');
            Assert.isTrue(accounts.size() <= 200, 'Should return maximum 200 accounts');
            Assert.isTrue(
                completedSalesIds.contains(testAcc2.Id),
                'Should include second account with Order Created opportunity'
            );
            Assert.isTrue(
                completedSalesIds.contains(testAcc3.Id),
                'Should include third account with Order Created opportunity'
            );
        }
    }
}