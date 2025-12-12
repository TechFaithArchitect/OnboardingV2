@isTest
private class OnboardingPrimaryContactTest {

    @isTest
    static void createsAvoWithPrimaryContact() {
        Account acct = new Account(Name = 'Primary Contact Account');
        insert acct;
        Contact contact = new Contact(LastName = 'Primary', AccountId = acct.Id);
        insert contact;

        Opportunity opp = new Opportunity(
            Name = 'Onboarding Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acct.Id
        );
        insert opp;

        Onboarding__c onboarding = new Onboarding__c(Account__c = acct.Id);
        insert onboarding;

        Test.startTest();
        Id avoId = VendorOnboardingWizardService.createAccountVendorProgramOnboarding(
            acct.Id,
            onboarding.Id,
            opp.Id,
            'Intake',
            contact.Id
        );
        Test.stopTest();

        Account_Vendor_Program_Onboarding__c avo = [
            SELECT Primary_Contact__c
            FROM Account_Vendor_Program_Onboarding__c
            WHERE Id = :avoId
        ];

        System.assertEquals(contact.Id, avo.Primary_Contact__c, 'AVO should store primary contact');
    }
}
