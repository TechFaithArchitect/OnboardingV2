@isTest
public class ConsentDisclaimerPageControllerTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(
            FirstName = 'Test',
            LastName = 'User',
            Phone = '1234567890',
            PersonEmail = 'testuser@example.com',
            Consent_to_Automated_Communications__c = false
        );
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert testOpportunity;

        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Email = 'testuser@example.com',
            Status = 'Open - Not Contacted'
        );
        insert testLead;
    }

    @isTest
    static void testGetLeadDataWithPreviousLeads() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Object> leadData = ConsentDisclaimerPageController.getLeadData(testOpportunity.Id);
        Test.stopTest();

        System.assertEquals(true, leadData.get('hasPrevious'), 'Lead should have previous leads');
        System.assertEquals('Test', leadData.get('firstName'), 'First name should match the test data');
        System.assertEquals('User', leadData.get('lastName'), 'Last name should match the test data');
        System.assertEquals('1234567890', leadData.get('phone'), 'Phone should match the test data');
        System.assertEquals('testuser@example.com', leadData.get('email'), 'Email should match the test data');
    }

    @isTest
    static void testGetLeadDataWithoutPreviousLeads() {
        Account newAccount = new Account(
            FirstName = 'New',
            LastName = 'User',
            Phone = '0987654321',
            PersonEmail = 'newuser@example.com'
        );
        insert newAccount;

        Opportunity newOpportunity = new Opportunity(
            Name = 'New Opportunity',
            AccountId = newAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert newOpportunity;

        Test.startTest();
        Map<String, Object> leadData = ConsentDisclaimerPageController.getLeadData(newOpportunity.Id);
        Test.stopTest();

        System.assertEquals(false, leadData.get('hasPrevious'), 'Lead should not have previous leads');
        System.assertEquals('New', leadData.get('firstName'), 'First name should match the test data');
        System.assertEquals('User', leadData.get('lastName'), 'Last name should match the test data');
        System.assertEquals('0987654321', leadData.get('phone'), 'Phone should match the test data');
        System.assertEquals('newuser@example.com', leadData.get('email'), 'Email should match the test data');
    }

    @isTest
    static void testGetLeadDataWithInvalidId() {
        Test.startTest();
        try {
            ConsentDisclaimerPageController.getLeadData('invalidId');
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateConsent() {
        Opportunity opp = [SELECT ID, AccountId FROM Opportunity LIMIT 1];
        Test.startTest();
        ConsentDisclaimerPageController.updateConsent(opp.ID);
        Test.stopTest();
        Account acc = [
            SELECT Id, Consent_to_Automated_Communications__c
            FROM Account
            WHERE Id = :opp.AccountId
            LIMIT 1
        ];
        System.assertEquals(true, acc.Consent_to_Automated_Communications__c, 'Consert flag was no correctly updated.');
    }
}