@isTest
public class POE_LeadConversionControllerTest {
    @TestSetup
    static void makeData() {
        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' 
            AND Name = 'Dealer' 
            AND isActive = true
            LIMIT 1
        ];

        Account testAcc = new Account(
            Name = 'Test',
            ShippingStreet = 'Test Street',
            POE_Dealer_Office_Email__c = 'poeleadconversioncontrollertest@hikko.is',
            P10_Invoice_Account__c = 'POE_LeadConversionCo',
            recordTypeId = rtype.Id
        );
        insert testAcc;

        Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
        insert userContact;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Owner Profile'];
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

        testAcc.POE_ICL_Owner__c = userContact.Id;
        update testAcc;

    }

    @isTest
    private static void convertLeadTest() {
        Lead myLead = new Lead(
            LastName = 'Conversion',
            Type__c = 'Phone Sales',
            Phone = '1231',
            FirstName = 'Test',
            Email = 'test@test.com',
            City = 'Little Rock',
            State = 'Arkansas',
            Country = 'United States',
            PostalCode = '72231',
            Street = 'Rahling Rd',
            Company = 'POE_LeadConversionCo'
        );
        insert myLead;

        List<Lead> nl = [
            SELECT FirstName, LastName, Phone, Email, City, State, Country, PostalCode, Street, Company
            FROM Lead
            WHERE LastName = 'Conversion'
        ];
        List<List<Lead>> leadList = new List<List<Lead>>();
        leadList.add(nl);
        List<List<Opportunity>> testOpp = POE_LeadConversionController.convertLead(leadList);
        System.AssertEquals(testOpp.size() == 1, true, 'Lead successfully converted');
    }

    @isTest
    private static void convertLeadTestNoFirstName() {
        Lead myLead = new Lead(
            LastName = 'Conversion',
            Type__c = 'Phone Sales',
            Phone = '1231',
            Email = 'test@test.com',
            City = 'Little Rock',
            State = 'Arkansas',
            Country = 'United States',
            PostalCode = '72231',
            Street = 'Rahling Rd'
        );
        insert myLead;

        List<Lead> nl = [
            SELECT FirstName, LastName, Phone, Email, City, State, Country, PostalCode, Street, Company
            FROM Lead
            WHERE LastName = 'Conversion'
        ];
        List<List<Lead>> leadList = new List<List<Lead>>();
        leadList.add(nl);

        List<List<Opportunity>> testOpp = POE_LeadConversionController.convertLead(leadList);

        System.AssertEquals(testOpp.size() == 1, true, 'Lead successfully converted');
    }
}