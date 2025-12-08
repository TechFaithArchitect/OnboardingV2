@isTest
public with sharing class BuyFlowLeadConsentBoxControllerTest {
    @TestSetup
    static void makeData() {
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
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
                Name = 'Test Account BuyFlowConsentBox',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
                P10_Invoice_Account__c = 'Example',
                recordTypeId = rtype.Id
            );
            insert testAcc;

            Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
            insert userContact;

            Profile p = TestHelper.getGeneralProfile();
            User u = new User(
                Alias = 'standt',
                Email = '11052022standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingBuyFlowConsentBox',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '11052022GDGstandarduser@testorg.com'
            );
            insert u;

            Opportunity opp = new Opportunity(Name = 'test opp', StageName = 'Presentation', CloseDate = Date.today(),OwnerId = u.Id);
            insert opp;
        }
    }

    @isTest
    static void testIsHomeConciergeDisabled() { 
        List<User> user = [SELECT Id, AccountId FROM User WHERE LastName = 'TestingBuyFlowConsentBox' LIMIT 1];
        List<Opportunity> opp = [SELECT Id FROM Opportunity WHERE OwnerId = :user[0].Id LIMIT 1];
        Boolean isHomeConciergeEnabled = false;
        System.runAs(user[0]) {
            Test.startTest();
            isHomeConciergeEnabled = BuyFlowLeadConsentBoxController.isHomeConciergeEnabled(opp[0].Id);
            Test.stopTest();
        }
        Assert.isFalse(isHomeConciergeEnabled, 'The result should be false');
    }

    @isTest
    static void testIsHomeConciergeEnabled() { 
        List<User> user = [SELECT Id, AccountId FROM User WHERE LastName = 'TestingBuyFlowConsentBox' LIMIT 1];
        List<Opportunity> opp = [SELECT Id FROM Opportunity WHERE OwnerId = :user[0].Id LIMIT 1];
        Boolean isHomeConciergeEnabled = false;
        List<Account> acc = [SELECT Id, Home_Concierge_Enabled__c FROM Account WHERE Name = 'Test Account BuyFlowConsentBox'];
        acc[0].Home_Concierge_Enabled__c = true;
        update acc;
        System.runAs(user[0]) {
            Test.startTest();
            isHomeConciergeEnabled = BuyFlowLeadConsentBoxController.isHomeConciergeEnabled(opp[0].Id);
            Test.stopTest();
        }
        Assert.isTrue(isHomeConciergeEnabled, 'The result should be true');
    }
}