@isTest
private class OnboardingGetDataHandlerTest {
    @isTest
    static void testGetRelatedRecords() {
        // Create related Account
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Create required Contact for Principal_Owner__c
        Contact principal = new Contact(FirstName = 'Test', LastName = 'Owner', AccountId = acct.Id, Principal_Owner__c = true);
        insert principal;

        // Create related records with "Not Started" status or default values
        Contract contract = new Contract(AccountId = acct.Id, Status = 'Draft', StartDate = Date.today(), ContractTerm = 12, Principal_Owner__c = principal.Id);
        insert contract;

        Background_Check__c background = new Background_Check__c(Status__c = 'Not Started', Account__c = acct.Id, Contact__c = principal.Id);
        insert background;

        License__c businessLicense = new License__c(Status__c = 'Not Started', Account__c = acct.Id, Contact__c = principal.Id);
        insert businessLicense;

        Dealer_Compliance__c compliance = new Dealer_Compliance__c(Status__c = 'Not Started', Account__c = acct.Id);
        insert compliance;

        Credit_Check__c creditCheck = new Credit_Check__c(Status__c = 'Not Started', Account__c = acct.Id, Contact__c = principal.Id);
        insert creditCheck;

        ERP_Setup__c erp = new ERP_Setup__c(Status__c = 'Not Started', Account__c = acct.Id);
        insert erp;

        Labor_Form__c labor = new Labor_Form__c(Status__c = 'Not Started', Account__c = acct.Id, Contact__c = principal.Id);
        insert labor;

        Net_Terms__c netTerms = new Net_Terms__c(Status__c = 'Not Started', Account__c = acct.Id);
        insert netTerms;

        Clearing_House__c clearing = new Clearing_House__c(Status__c = 'Not Started', Account__c = acct.Id);
        insert clearing;

        License__c driverLicense = new License__c(Status__c = 'Not Started', Account__c = acct.Id, Contact__c = principal.Id);
        insert driverLicense;

        // Create Onboarding record with all relationships
        Onboarding__c onboarding = new Onboarding__c(
            Account__c = acct.Id,
            Contract__c = contract.Id,
            Background_Check__c = background.Id,
            Business_License__c = businessLicense.Id,
            Compliance__c = compliance.Id,
            Credit_Check__c = creditCheck.Id,
            ERP_Setup__c = erp.Id,
            Labor_Form__c = labor.Id,
            Net_Terms__c = netTerms.Id,
            Clearing_House__c = clearing.Id,
            Drivers_License__c = driverLicense.Id
        );
        insert onboarding;

        // Execute class logic
        List<Id> recordIds = new List<Id>{ onboarding.Id };

        Test.startTest();
        List<OnboardingGetDataHandler.ResultWrapper> results = OnboardingGetDataHandler.getRelatedRecords(recordIds);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size());
        OnboardingGetDataHandler.ResultWrapper res = results[0];

        System.assertNotEquals(null, res.onboardingRecord);
        System.assertNotEquals(null, res.backgroundCheckRecord);
        System.assertNotEquals(null, res.contractRecord);

        System.assertEquals('Not Started', res.backgroundCheckRecord.Status__c);
        System.assertEquals('Test Account', res.backgroundCheckRecord.Account__r.Name);
        System.assertEquals('Draft', res.contractRecord.Status);
    }
}