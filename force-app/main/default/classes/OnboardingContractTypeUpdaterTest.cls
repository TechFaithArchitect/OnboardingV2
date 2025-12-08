@isTest
private class OnboardingContractTypeUpdaterTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Create Contact to use as Principal_Owner__c
        Contact contact = new Contact(LastName = 'Test Contact', AccountId = acct.Id);
        insert contact;

        // Get Record Types
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Contract']) {
            recordTypeMap.put(rt.Name, rt.Id);
        }

        // NDA Contract
        Contract nda = new Contract(
            AccountId = acct.Id,
            RecordTypeId = recordTypeMap.get('NDA'),
            Application_Status__c = 'Pending',
            Principal_Owner__c = contact.Id,
            Temp_Only_Run_Via_New_Flows__c = true
        );

        // DOM Contract - with Chuzo
        Contract withChuzo = new Contract(
            AccountId = acct.Id,
            RecordTypeId = recordTypeMap.get('New Dealer Application (DOM)'),
            Retailer_Type__c = 'New customer with Chuzo App',
            Application_Status__c = 'Pending',
            Principal_Owner__c = contact.Id,
            Temp_Only_Run_Via_New_Flows__c = true
        );

        // DOM Contract - without Chuzo
        Contract withoutChuzo = new Contract(
            AccountId = acct.Id,
            RecordTypeId = recordTypeMap.get('New Dealer Application (DOM)'),
            Retailer_Type__c = 'Other',
            Application_Status__c = 'Pending',
            Principal_Owner__c = contact.Id,
            Temp_Only_Run_Via_New_Flows__c = true
        );

        insert new List<Contract>{ nda, withChuzo, withoutChuzo };
    }

    @isTest
    static void testUpdaterSetsContractTypes() {
        Test.startTest();
        Database.executeBatch(new OnboardingContractTypeUpdater(), 50);
        Test.stopTest();

        List<Contract> updatedContracts = [
            SELECT RecordType.Name, Retailer_Type__c, Contract_Type__c
            FROM Contract
            WHERE Temp_Only_Run_Via_New_Flows__c = true
            ORDER BY RecordType.Name
        ];

        System.assertEquals(3, updatedContracts.size());
        System.assertEquals('NDA', updatedContracts[0].Contract_Type__c);
        System.assertEquals('Program Base Application - with Chuzo', updatedContracts[1].Contract_Type__c);
        System.assertEquals('Program Base Application - without Chuzo', updatedContracts[2].Contract_Type__c);
    }
}