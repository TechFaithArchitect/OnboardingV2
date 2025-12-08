@isTest
public class ContactPrincipalOwnerTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        // Create one Account to share
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Insert one existing Contact marked as Principal Owner
        Contact con1 = new Contact(
            FirstName = 'Existing',
            LastName = 'Owner',
            AccountId = acct.Id,
            Principal_Owner__c = true
        );
        insert con1;
    }

    @isTest
    static void testInsertSecondPrincipalOwner_shouldFail() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Contact con2 = new Contact(
            FirstName = 'New',
            LastName = 'Contact',
            AccountId = acct.Id,
            Principal_Owner__c = true
        );

        Test.startTest();
        try {
            insert con2;
            System.assert(false, 'Insert should have failed due to duplicate principal owner.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Only one contact per Account can be the Principal Owner.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateToPrincipalOwner_shouldFail() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Contact con3 = new Contact(
            FirstName = 'Another',
            LastName = 'Contact',
            AccountId = acct.Id,
            Principal_Owner__c = false
        );
        insert con3;

        con3.Principal_Owner__c = true;

        Test.startTest();
        try {
            update con3;
            System.assert(false, 'Update should have failed due to duplicate principal owner.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Only one contact per Account can be the Principal Owner.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateSamePrincipalOwner_shouldPass() {
        Contact existing = [SELECT Id, Principal_Owner__c FROM Contact WHERE Principal_Owner__c = true LIMIT 1];
        existing.FirstName = 'Updated';

        Test.startTest();
        update existing;
        Test.stopTest();

        Contact updated = [SELECT FirstName FROM Contact WHERE Id = :existing.Id];
        System.assertEquals('Updated', updated.FirstName);
    }

    @isTest
    static void testInsertPrincipalOwner_whenNoneExists_shouldPass() {
        Account newAcct = new Account(Name = 'New Account');
        insert newAcct;

        Contact con = new Contact(
            FirstName = 'Solo',
            LastName = 'Owner',
            AccountId = newAcct.Id,
            Principal_Owner__c = true
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        System.assertEquals(true, con.Principal_Owner__c);
    }
}