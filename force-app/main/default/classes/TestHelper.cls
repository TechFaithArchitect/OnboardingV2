@isTest
public class TestHelper {
    
    public static Profile getGeneralProfile() {
        return [SELECT Id FROM Profile WHERE Name = 'External Partner – General'];
    }

    public static User getAdminUser() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String uniqueUserName = 'testsysadminuser' + DateTime.now().getTime() + '@test.com';

        User adminUser = new User(
            ProfileId = adminProfile.Id,
            Alias = 'sysadm',
            Email = uniqueUserName,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test Sysadmin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );

        return adminUser;
    }

    public static List<Account> getAccounts(Integer count) {
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < count; i++) {
            Account testAccount = new Account(
                Name = 'Test Account ' + i
            );

            testAccounts.add(testAccount);
        }

        return testAccounts;
    }

    public static List<Lead> getLeads(Integer count) {
        List<Lead> testLeads = new List<Lead>();
        Id chuzoLeadRTId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get('Chuzo_Lead').getRecordTypeId();

        for (Integer i = 0; i < count; i++) {
            Lead testLead = new Lead(
                RecordTypeId = chuzoLeadRTId,
                FirstName = 'Lead',
                LastName = 'Test ' + i,
                Concierge_Status__c = 'new',
                Phone = '4444444484', 
                Email = 'test@test.com', 
                Interested_Programs__c = 'DIRECTV;Spectrum',
                Preferred_Contact_Method__c = 'Email',
                Preferred_Contact_Time__c = '1:00 pm to 2:00 pm',
                Street = 'Test Street',
                Address_Line_2__c = 'Test Apt',
                Address_Line_2_Type__c = 'None',
                City = 'Test City',
                StateCode = 'CA',
                PostalCode = '91750'
            );

            testLeads.add(testLead);
        }

        return testLeads;
    }
}