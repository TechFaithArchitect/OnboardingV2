@isTest
public with sharing class PersonAccountConverterTest {
    @TestSetup
    static void makeData() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Id consumerAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Consumer')
                .getRecordTypeId();

            Account testAcc = new Account(
                Name = 'Test',
                RecordTypeId = consumerAccRecordTypeId,
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com'
            );
            insert testAcc;
            Account testAccNoContact = new Account(
                Name = 'TestNoContact',
                RecordTypeId = consumerAccRecordTypeId,
                ShippingStreet = 'Test Street NoContact',
                POE_Dealer_Office_Email__c = 'DealerEmailNocontact@testorg1.com'
            );
            insert testAccNoContact;
            Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
            insert userContact;
            Contact testContact1 = new Contact(FirstName = 'testCont', LastName = 'testCont', AccountId = testAcc.Id);
            insert testContact1;
            Contact testContact2 = new Contact(FirstName = 'testCont2', LastName = 'testCont2', AccountId = testAcc.Id);
            insert testContact2;

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
            User u2 = new User(
                Alias = 'standt',
                Email = '11034234standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing2',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = testContact1.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '110520333GDGstandarduser@testorg.com'
            );
            insert u2;
            Opportunity opp1 = new Opportunity(
                Name = 'TEST1',
                CloseDate = System.today(),
                OwnerId = u.Id,
                AccountId = testAcc.Id,
                StageName = 'Qualification',
                Maps_PostalCode__c = '72212'
            );
            insert opp1;

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
                OpportunityId = opp1.Id,
                OwnerId = u.Id,
                POE_Program__c = 'EarthLink'
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
    }

    @isTest
    private static void testBatchJob() {
        List<Account> consumerAccs = [
            SELECT
                Id,
                Name,
                FirstName,
                LastName,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingCountry,
                BillingPostalCode,
                vlocity_cmt__CustomerPriority__c,
                vlocity_cmt__vCustomerPriority__c,
                ShippingStreet,
                ShippingCity,
                ShippingState,
                ShippingPostalCode,
                ShippingCountry,
                Phone,
                POE_Require_TPV__c,
                vlocity_cmt__PremisesId__c,
                POE_Dealer_Code__c,
                POE_ICL_Owner__c,
                POE_Office_Start_Date__c,
                POE_Active_In_SF__c,
                POE_Bonus_Start_Date__c,
                POE_Office_Close_Date__c,
                POE_Status_Reason__c,
                POE_Dealer_Office_Email__c,
                POE_Secondary_Phone__c,
                Division__c,
                Region__c,
                Territory__c,
                Company_ID__c,
                vlocity_cmt__BillFrequency__c,
                vlocity_cmt__AccountPaymentType__c,
                vlocity_cmt__EnableAutopay__c,
                vlocity_cmt__BillDeliveryMethod__c,
                vlocity_cmt__BillingEmailAddress__c,
                vlocity_cmt__AutoPaymentMethodId__c,
                vlocity_cmt__AutoPaymentAmount__c,
                vlocity_cmt__CLTV__c,
                vlocity_cmt__Churn__c,
                POE_Programs_available__c,
                POE_Programs_Available__pc,
                vlocity_cmt__DirectoryListed__c,
                vlocity_cmt__ContactPreferences__c,
                ParentId,
                vlocity_cmt__SLA__c,
                vlocity_cmt__vSLA__c,
                vlocity_cmt__Status__c,
                vlocity_cmt__Status__pc,
                OwnerId,
                (
                    SELECT
                        Id,
                        Pricebook2Id,
                        AccountId,
                        POE_Dealer__c,
                        RecordTypeId,
                        Type,
                        EffectiveDate,
                        Status,
                        ShippingStreet,
                        ShippingPostalCode,
                        ShippingCountry,
                        ShippingCity,
                        ShippingState
                    FROM Orders
                ),
                (
                    SELECT
                        Id,
                        Name,
                        Salutation,
                        FirstName,
                        MiddleName,
                        vlocity_cmt__MiddleName__c,
                        LastName,
                        Suffix,
                        Email,
                        Phone,
                        AccountId,
                        Title
                    FROM Contacts
                )
            FROM Account
            WHERE RecordType.Name = 'Consumer'
        ];
        Test.startTest();
        PersonAccountConverter.convertMethod(consumerAccs);
        Test.stopTest();
        Id consumerAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        List<Account> accs = [
            SELECT Id, RecordType.DeveloperName
            FROM Account
            WHERE RecordTypeId = :consumerAccRecordTypeId
        ];
        System.assertEquals(4, accs.size(), 'Job not executed');
    }
}