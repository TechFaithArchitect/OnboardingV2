@isTest
public class POECreditCrossCheckTest {
    @TestSetup
    static void makeData() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com'
            );
            insert testAcc;
            Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
            insert userContact;
            Contact testContact1 = new Contact(FirstName = 'testCont', LastName = 'testCont', AccountId = testAcc.Id);
            insert testContact1;
            Contact testContact2 = new Contact(FirstName = 'testCont2', LastName = 'testCont2', AccountId = testAcc.Id);
            insert testContact2;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'Partner Community User'];
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

            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
            update standardPricebook;

            Order testOrder = new Order(
                EffectiveDate = System.today(),
                Status = 'Draft',
                AccountId = testAcc.Id,
                Pricebook2Id = standardPricebook.Id,
                OpportunityId = opp1.Id,
                OwnerId = u.Id
            );
            insert testOrder;
        }
    }

    @isTest
    private static void insertSecondOrderTest24Hours() {
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];
        User partner = [SELECT Id FROM User WHERE LastName = 'Testing2' LIMIT 1];
        List<String> classInput = new List<String>();
        Fraud_Validation_Rules__c val = new Fraud_Validation_Rules__c();
        val.Name = 'CrossCredit';
        val.Time_Lapse__c = 24;
        insert val;
        Test.startTest();
        System.runAs(partner) {
            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
            update standardPricebook;
            Opportunity opp2 = new Opportunity(
                Name = 'TEST2',
                CloseDate = System.today(),
                AccountId = testAcc.Id,
                StageName = 'Qualification',
                Maps_PostalCode__c = '72212'
            );
            insert opp2;
            Order testOrder = new Order(
                EffectiveDate = System.today(),
                Status = 'Draft',
                AccountId = testAcc.Id,
                Pricebook2Id = standardPricebook.Id,
                OpportunityId = opp2.Id
            );
            insert testOrder;
            classInput.add(testOrder.Id);
            POECreditCrossCheck.creditCrossCheck(classInput);
        }
        Test.stopTest();
        Opportunity oppAssert = [SELECT POE_CC_Flag__c FROM Opportunity WHERE Name = 'TEST2' LIMIT 1];
        System.assertEquals(true, oppAssert.POE_CC_Flag__c, 'The opportunity was not updated with the flag');
    }

    @isTest
    private static void insertSecondOrderTest48Hours() {
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];
        User partner = [SELECT Id FROM User WHERE LastName = 'Testing2' LIMIT 1];
        List<String> classInput = new List<String>();
        Fraud_Validation_Rules__c val = new Fraud_Validation_Rules__c();
        val.Name = 'CrossCredit';
        val.Time_Lapse__c = 48;
        insert val;
        Test.startTest();
        System.runAs(partner) {
            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
            update standardPricebook;
            Opportunity opp2 = new Opportunity(
                Name = 'TEST2',
                CloseDate = System.today(),
                AccountId = testAcc.Id,
                StageName = 'Qualification',
                Maps_PostalCode__c = '72212'
            );
            insert opp2;
            Order testOrder = new Order(
                EffectiveDate = System.today(),
                Status = 'Draft',
                AccountId = testAcc.Id,
                Pricebook2Id = standardPricebook.Id,
                OpportunityId = opp2.Id
            );
            insert testOrder;
            classInput.add(testOrder.Id);
            POECreditCrossCheck.creditCrossCheck(classInput);
        }
        Test.stopTest();
        Opportunity oppAssert = [SELECT POE_CC_Flag__c FROM Opportunity WHERE Name = 'TEST2' LIMIT 1];
        System.assertEquals(true, oppAssert.POE_CC_Flag__c, 'The opportunity was not updated with the flag');
    }
}