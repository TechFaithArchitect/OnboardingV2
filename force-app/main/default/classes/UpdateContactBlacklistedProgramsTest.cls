@isTest
private class UpdateContactBlacklistedProgramsTest {
    @isTest
    static void testUpdateContacts() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, Blacklisted_Programs__c = 'EarthLink'));
        }
        insert testAccounts;

        List<Contact> testContacts = new List<Contact>();
        for (Account acc : testAccounts) {
            Contact c1 = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id,
                POE_Blacklisted_Programs__c = 'EarthLink;Windstream',
                D2D_Programs__c = 'Altice',
                POE_Event_Programs__c = 'Altice;DirecTV',
                POE_Programs_Available__c = 'Altice;DirecTV',
                POE_Retail_Programs__c = 'Altice;DirecTV'
            );
            testContacts.add(c1);
            Contact c2 = new Contact(
                FirstName = 'Test',
                LastName = 'Contact 2',
                AccountId = acc.Id,
                POE_Blacklisted_Programs__c = 'DirecTV',
                D2D_Programs__c = 'EarthLink;Altice',
                POE_Event_Programs__c = 'EarthLink;Altice',
                POE_Programs_Available__c = 'EarthLink;Altice',
                POE_Retail_Programs__c = 'EarthLink;Altice'
            );
            testContacts.add(c2);
            Contact c3 = new Contact(
                FirstName = 'Test',
                LastName = 'Contact 3',
                AccountId = acc.Id,
                POE_Blacklisted_Programs__c = 'Altice',
                D2D_Programs__c = 'EarthLink;DirecTV',
                POE_Event_Programs__c = 'EarthLink;DirecTV',
                POE_Programs_Available__c = 'EarthLink;DirecTV',
                POE_Retail_Programs__c = 'EarthLink;DirecTV'
            );
            testContacts.add(c3);
        }
        insert testContacts;

        Test.startTest();
        UpdateContactBlacklistedPrograms.updateContacts(new List<Id>{ testAccounts[0].Id, testAccounts[1].Id });
        Test.stopTest();

        List<Contact> updatedContacts = [
            SELECT Id, POE_Blacklisted_Programs__c, POE_Retail_Programs__c
            FROM Contact
            WHERE AccountId IN :testAccounts
        ];
        System.assert.areEqual(
            'EarthLink;Windstream',
            updatedContacts[0].POE_Blacklisted_Programs__c,
            'POE_Blacklisted_Programs__c should not change'
        );
        System.assert.areEqual(
            'EarthLink;DirecTV',
            updatedContacts[1].POE_Blacklisted_Programs__c,
            'POE_Blacklisted_Programs__c EarthLink should be added'
        );
        System.assert.areEqual(
            'DirecTV',
            updatedContacts[2].POE_Retail_Programs__c,
            'POE_Blacklisted_Programs__c EarthLink should be removed'
        );
    }
}