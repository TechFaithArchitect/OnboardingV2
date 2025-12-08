@isTest
private class OnboardingMigrationBatchTest {

    @isTest
    static void testBatchExecution() {
        // Valid Account
        Account acct = new Account(Name = 'Test Dealer', Division__c = 'DOM', Territory__c = 'NYJ', Region__c = 'ESR');
        insert acct;

        // Excluded Account
        Account excludedAcct = new Account(Name = 'PV Test Account', Division__c = 'DOM', Territory__c = 'NYJ', Region__c = 'ESR');
        insert excludedAcct;

        // Shared Contact
        Contact contact = new Contact(LastName = 'Test Person', AccountId = acct.Id);
        insert contact;

        insert new Territory_Assignments__c(
            Division__c = acct.Division__c,
            Territory__c = acct.Territory__c,
            Region__c = acct.Region__c,
            Base_App_OB_Rep__c = UserInfo.getUserId()
        );

        Vendor__c vendor = new Vendor__c(Name = 'PerfectVision');
        insert vendor;

        // Action Plan Template
        ActionPlanTemplate apt = new ActionPlanTemplate(
            Name = 'Onboarding Template',
            ActionPlanType = 'Sales',
            TargetEntityType = 'Account'
        );
        insert apt;

        ActionPlanTemplateVersion ver = [
            SELECT Id, ActionPlanTemplateId
            FROM ActionPlanTemplateVersion
            WHERE ActionPlanTemplateId = :apt.Id
            LIMIT 1
        ];

        // NDA Record Type (used in both Contract and Vendor_Customization)
        Id ndaRTId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('NDA').getRecordTypeId();

        Contract_Record_Type_Reference__c contractTypeRef = new Contract_Record_Type_Reference__c(
            Name = 'NDA',
            RecordTypeId__c = ndaRTId
        );
        insert contractTypeRef;


        // Vendor Customization
        Vendor_Customization__c vc = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Action_Plan_Template__c = apt.Id,
            Contract_Record_Type__c = contractTypeRef.Id
        );
        insert vc;

        // Contract for valid account
        Contract goodCon = new Contract(
            RecordTypeId = ndaRTId,
            AccountId = acct.Id,
            Application_Status__c = 'In Process',
            Contract_Type__c = 'NDA',
            Status = 'Draft',
            Principal_Owner__c = contact.Id,
            Temp_Only_Run_Via_New_Flows__c = true
        );
        insert goodCon;

        // Contract for excluded account
        Contract excludedCon = new Contract(
            RecordTypeId = ndaRTId,
            AccountId = excludedAcct.Id,
            Application_Status__c = 'In Process',
            Contract_Type__c = 'NDA',
            Status = 'Draft',
            Principal_Owner__c = contact.Id,
            Temp_Only_Run_Via_New_Flows__c = true
        );
        insert excludedCon;

        // Agreement
        insert new echosign_dev1__SIGN_Agreement__c(
            echosign_dev1__Contract__c = goodCon.Id,
            echosign_dev1__Status__c = 'Signed'
        );

        // Build maps
        String taKey = acct.Division__c + '|' + acct.Territory__c + '|' + acct.Region__c;
        Map<String, Territory_Assignments__c> taMap = new Map<String, Territory_Assignments__c>{
            taKey => [SELECT Id, Division__c, Territory__c, Region__c, Base_App_OB_Rep__c FROM Territory_Assignments__c LIMIT 1]
        };

        Map<Id, Id> customizationToTemplateMap = new Map<Id, Id>{ vc.Id => apt.Id };

        Test.startTest();
        OnboardingMigrationBatch batch = new OnboardingMigrationBatch(
            vendor.Id,
            taMap,
            customizationToTemplateMap
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert onboarding created for good contract
        System.assertEquals(1, [
            SELECT COUNT() FROM Onboarding__c WHERE Contract__c = :goodCon.Id
        ], 'Onboarding should be created for good contract');

        // Assert no onboarding created for excluded contract
        System.assertEquals(0, [
            SELECT COUNT() FROM Onboarding__c WHERE Contract__c = :excludedCon.Id
        ], 'No onboarding should be created for excluded account');
    }
}