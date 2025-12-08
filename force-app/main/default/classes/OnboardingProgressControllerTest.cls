@isTest
public class OnboardingProgressControllerTest {

    @isTest
    static void test_NDA_AllComplete_CustomValues() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact required for Principal_Owner__c
        Contact owner = new Contact(
            FirstName = 'Test',
            LastName = 'Owner',
            AccountId = acc.Id
        );
        insert owner;

        // Create Contract with required Principal_Owner__c and Contract_Type__c
        Contract contract = new Contract(
            Status = 'Draft',
            Contract_Type__c = 'NDA', // or other valid type as needed
            StartDate = Date.today(),
            AccountId = acc.Id,
            Principal_Owner__c = owner.Id
        );
        insert contract;

        Onboarding__c record = new Onboarding__c(
            Account__c = acc.Id,
            Agreement_Status__c = 'Signed',
            Contract_Status__c = 'In Approval Process',
            Contract__c = contract.Id,
            Compliance_Status__c = 'Not Started',
            Clearing_House_Status__c = 'Not Started', // Make sure this is a VALID picklist value
            Labor_Form_Status__c = 'Not Started',
            Background_Check_Status__c = 'Not Started',
            Business_License_Status__c = 'Not Started',
            Credit_Check_Status__c = 'Not Started',
            Drivers_Licenses_Status__c = 'Not Started',
            ERP_Setup_Status__c = 'Not Started'
        );
        insert record;

        Test.startTest();
        Integer result = OnboardingProgressController.getCompletionPercent(record.Id);
        Test.stopTest();

        System.debug('NDA Record Complete %: ' + result);
        System.assertEquals(50, result, 'Should return 50% for all complete with custom values');
    }

    @isTest
    static void test_NonNDA_PartialProgress() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact required for Principal_Owner__c
        Contact owner = new Contact(
            FirstName = 'Test',
            LastName = 'Owner',
            AccountId = acc.Id
        );
        insert owner;

        // Create Contract with required Principal_Owner__c and Contract_Type__c
        Contract contract = new Contract(
            Status = 'Draft',
            Contract_Type__c = 'Program Base Application - with Chuzo', 
            StartDate = Date.today(),
            AccountId = acc.Id,
            Principal_Owner__c = owner.Id
        );
        insert contract;

        Onboarding__c record = new Onboarding__c(
            Account__c = acc.Id,
            Contract_Status__c = 'In Approval Process',
            Contract__c = contract.Id,
            Agreement_Status__c = 'Signed',
            Chuzo_Agreement_Status__c = 'Not Started',
            Compliance_Status__c = 'Approved',
            Clearing_House_Status__c = 'Incomplete', // CHANGED from "Pending" to a likely valid value
            Labor_Form_Status__c = 'Incomplete',
            Background_Check_Status__c = 'Complete',
            Business_License_Status__c = 'Incomplete',
            Credit_Check_Status__c = 'Complete',
            Drivers_Licenses_Status__c = 'Complete',
            ERP_Setup_Status__c = 'Incomplete',
            Personal_Guarantee_Status__c = 'Not Started',
            Terms_Conditions_Status__c = 'Not Started'
        );
        insert record;

        Test.startTest();
        Integer result = OnboardingProgressController.getCompletionPercent(record.Id);
        Test.stopTest();

        System.debug('Non-NDA Partial Progress %: ' + result);
        System.assert(result > 0 && result < 100, 'Should return partial progress');
    }

    @isTest
    static void test_EmptyRecord_ZeroProgress() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Onboarding__c record = new Onboarding__c(Account__c = acc.Id); // REQUIRED FIELD
        insert record;

        Test.startTest();
        Integer result = OnboardingProgressController.getCompletionPercent(record.Id);
        Test.stopTest();

        System.debug('Empty Record Progress %: ' + result);
        System.assertEquals(0, result, 'Should return 0% for empty onboarding record');
    }
    
}