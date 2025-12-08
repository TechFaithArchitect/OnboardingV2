@isTest
private class OnboardingHelperTest {

    @isTest
    static void testProcessContracts_withNDAAndDOM() {
        // Create Account
        Account acct = new Account(Name = 'Test Account', Division__c = 'DOM', Territory__c = 'TXN', Region__c = 'CENTRAL');
        insert acct;

        // Create Territory Assignment
        insert new Territory_Assignments__c(
            Division__c = acct.Division__c,
            Territory__c = acct.Territory__c,
            Region__c = acct.Region__c,
            Base_App_OB_Rep__c = UserInfo.getUserId()
        );

        // Create Vendor that matches NDA RecordType.Name
        Vendor__c vendor = new Vendor__c(Name = 'PerfectVision');
        insert vendor;

        // Create Record Types
        RecordType ndaRT = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Contract' AND Name = 'NDA' LIMIT 1];
        RecordType domRT = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Contract' AND Name = 'New Dealer Application (DOM)' LIMIT 1];

        // Create Contract_Record_Type_Reference__c for both RecordTypes
        insert new List<Contract_Record_Type_Reference__c>{
            new Contract_Record_Type_Reference__c(
                Name = ndaRT.Name,
                Developer_Name__c = ndaRT.DeveloperName,
                RecordTypeId__c = ndaRT.Id
            ),
            new Contract_Record_Type_Reference__c(
                Name = domRT.Name,
                Developer_Name__c = domRT.DeveloperName,
                RecordTypeId__c = domRT.Id
            )
        };

        Map<Id, Contract_Record_Type_Reference__c> refMap = new Map<Id, Contract_Record_Type_Reference__c>(
            [SELECT Id, RecordTypeId__c FROM Contract_Record_Type_Reference__c]
        );

        // Create Action Plan Template (auto creates Version)
        ActionPlanTemplate apt = new ActionPlanTemplate(
            Name = 'Onboarding Template', 
            ActionPlanType = 'Sales',
            TargetEntityType = 'Account'
        );

        insert apt;

        ActionPlanTemplateVersion ver = [
            SELECT Id, ActionPlanTemplateId 
            FROM ActionPlanTemplateVersion 
            WHERE ActionPlanTemplateId = :apt.Id LIMIT 1
        ];

        // Create Vendor_Customization__c for both NDA and DOM
        List<Vendor_Customization__c> vcs = new List<Vendor_Customization__c>();
        for (Contract_Record_Type_Reference__c ref : [SELECT Id, RecordTypeId__c FROM Contract_Record_Type_Reference__c]) {
            Vendor_Customization__c vc = new Vendor_Customization__c(
                Vendor__c = vendor.Id,
                Contract_Record_Type__c = ref.Id,
                Action_Plan_Template__c = apt.Id
            );
            vcs.add(vc);
        }
        insert vcs;

        // Create Contact
        Contact contact = new Contact(LastName = 'Test Contact', AccountId = acct.Id);
        insert contact;

        // Create NDA Contract
        Contract nda = new Contract(
            RecordTypeId = ndaRT.Id,
            AccountId = acct.Id,
            Principal_Owner__c = contact.Id,
            Application_Status__c = 'In Process',
            Contract_Type__c = 'NDA',
            Status = 'Draft',
            Retailer_Type__c = 'New customer with Chuzo',
            Temp_Only_Run_Via_New_Flows__c = true
        );
        insert nda;

        // Create DOM Contract
        Contract dom = new Contract(
            RecordTypeId = domRT.Id,
            AccountId = acct.Id,
            Principal_Owner__c = contact.Id,
            Application_Status__c = 'In Process',
            Contract_Type__c = 'Program Base Application - with Chuzo',
            Status = 'Draft',
            Retailer_Type__c = 'New customer with Chuzo',
            Temp_Only_Run_Via_New_Flows__c = true
        );
        insert dom;

        // Create Adobe Agreement
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c(
            echosign_dev1__Contract__c = nda.Id,
            echosign_dev1__Status__c = 'Signed'
        );
        insert agreement;

        // Prepare inputs
        Map<Id, Account> accountMap = new Map<Id, Account>{ acct.Id => acct };
        Set<Id> skipContracts = new Set<Id>();
        Map<Id, echosign_dev1__SIGN_Agreement__c> agreementMap = new Map<Id, echosign_dev1__SIGN_Agreement__c>{ nda.Id => agreement };
        Map<Id, Onboarding__c> ndaMap = new Map<Id, Onboarding__c>();
        Map<String, Territory_Assignments__c> taMap = new Map<String, Territory_Assignments__c>{
            acct.Division__c + '|' + acct.Territory__c + '|' + acct.Region__c =>
            [SELECT Id, Base_App_OB_Rep__c FROM Territory_Assignments__c LIMIT 1]
        };

        // Template/Version maps
        Map<Id, Id> customizationToTemplateMap = new Map<Id, Id>();
        for (Vendor_Customization__c vc : vcs) {
            customizationToTemplateMap.put(vc.Id, apt.Id);
        }

        // Run logic
        Test.startTest();
        OnboardingHelper.processContracts(
            new List<Contract>{ nda, dom },
            accountMap,
            skipContracts,
            agreementMap,
            vendor.Id,
            taMap,
            customizationToTemplateMap,
            ndaMap
        );
        Test.stopTest();

        // Verify result
        List<Onboarding__c> obs = [SELECT Id, Contract__c, Account__c, Onboarding_Status__c, Agreement_Status__c FROM Onboarding__c WHERE Account__c = :acct.Id];
        System.assertEquals(2, obs.size(), 'Should have Onboarding for both NDA and DOM');
    }
}