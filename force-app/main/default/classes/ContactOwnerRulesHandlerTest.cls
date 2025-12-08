@isTest
public class ContactOwnerRulesHandlerTest {

    @isTest
    static void test_PrincipalOwner_sets_Owner_and_AuthorizedSigner() {
        Contact c = new Contact(
            FirstName = 'Principal',
            LastName = 'Owner',
            Principal_Owner__c = true
        );
        insert c;

        Contact result = [SELECT Owner__c, Add_to_Agreements__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(true, result.Owner__c, 'Owner__c should be set to true when Principal_Owner__c is true');
        System.assertEquals(true, result.Add_to_Agreements__c, 'Add_to_Agreements__c should be set to true when Principal_Owner__c is true');
    }

    @isTest
    static void test_OwnerOnly_sets_AuthorizedSigner() {
        Contact c = new Contact(
            FirstName = 'OwnerOnly',
            LastName = 'Contact',
            Principal_Owner__c = false,
            Owner__c = true
        );
        insert c;

        Contact result = [SELECT Add_to_Agreements__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(true, result.Add_to_Agreements__c, 'Add_to_Agreements__c should be true when Owner__c is true and Principal_Owner__c is false');
    }

    @isTest
    static void test_Neither_sets_AuthorizedSigner_leftAsIs() {
        Contact c = new Contact(
            FirstName = 'NoOne',
            LastName = 'Set',
            Principal_Owner__c = false,
            Owner__c = false,
            Add_to_Agreements__c = false
        );
        insert c;

        Contact result = [SELECT Add_to_Agreements__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(false, result.Add_to_Agreements__c, 'Add_to_Agreements__c should remain false if neither Principal_Owner__c nor Owner__c is true');
    }

    @isTest
    static void test_Update_to_PrincipalOwner_sets_fields() {
        Contact c = new Contact(
            FirstName = 'Updater',
            LastName = 'NowOwner',
            Principal_Owner__c = false,
            Owner__c = false,
            Add_to_Agreements__c = false
        );
        insert c;

        c.Principal_Owner__c = true;
        update c;

        Contact result = [SELECT Owner__c, Add_to_Agreements__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(true, result.Owner__c);
        System.assertEquals(true, result.Add_to_Agreements__c);
    }

}