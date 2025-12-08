public with sharing class OnboardingMigrationBatch implements Database.Batchable<SObject>, Database.Stateful {

    Set<String> excludedAccounts = new Set<String>{'NIMS Dummy Account', 'KB Test Acct', 'PV Test Account'};
    Id vendorId;
    Map<String, Territory_Assignments__c> taMap;
    Map<Id, Id> customizationToTemplateMap;

    public OnboardingMigrationBatch(
        Id testVendorId,
        Map<String, Territory_Assignments__c> testTaMap,
        Map<Id, Id> testCustomizationToTemplateMap
    ) {
        this.vendorId = testVendorId;
        this.taMap = testTaMap;
        this.customizationToTemplateMap = testCustomizationToTemplateMap;
    }

    public OnboardingMigrationBatch() {
        preloadData();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, AccountId, Opportunity_to_Contract__c, Agreement__c, Owner.Name, Application_Status__c,
                   RecordType.Name, Account.Name, Principal_Owner__c, Notes__c, Status, Retailer_Type__c,
                   Background_Check__c, Business_License__c, Credit_Check__c, Credit_Rating__c, Terms__c, ACH__c,
                   W9__c, Drivers_License__c, Training__c, AX_Setup__c, Contract_Type__c, CreatedDate
            FROM Contract
            WHERE RecordType.Name IN ('NDA', 'New Dealer Application (DOM)', 'Frontier')
              AND Application_Status__c IN ('New', 'Paperwork Sent', 'Pending Sales', 'Pending Initial Review', 'In Process', 'Setup Complete')
              AND Contract_Type__c != NULL
              AND Account.Name != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Contract> contracts = (List<Contract>) scope;
        Set<Id> acctIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        List<Contract> filtered = new List<Contract>();

        for (Contract c : contracts) {
            if (c.Account != null && !excludedAccounts.contains(c.Account.Name)) {
                filtered.add(c);
                acctIds.add(c.AccountId);
                contractIds.add(c.Id);
            }
        }

        if (filtered.isEmpty()) return;

        filtered.sort(new ContractRecordTypeNameComparator());

        Map<Id, Onboarding__c> ndaOnboardingByAccount = new Map<Id, Onboarding__c>(
            [SELECT Id, Account__c,
                Background_Check__c, Business_License__c, Drivers_License__c, Clearing_House__c,
                Credit_Check__c, Labor_Form__c, Compliance__c, Net_Terms__c,
                Personal_Guarantee__c, Chuzo_Agreement__c, ERP_Setup__c
             FROM Onboarding__c
             WHERE Contract__r.RecordType.Name = 'NDA']
        );

        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Name, Division__c, Territory__c, Region__c FROM Account WHERE Id IN :acctIds]
        );

        Set<Id> skipContracts = new Set<Id>();
        for (Onboarding__c ob : [SELECT Contract__c FROM Onboarding__c WHERE Contract__c IN :contractIds]) {
            skipContracts.add(ob.Contract__c);
        }


        Map<Id, echosign_dev1__SIGN_Agreement__c> agreementMap = new Map<Id, echosign_dev1__SIGN_Agreement__c>();
        for (echosign_dev1__SIGN_Agreement__c ag : [
            SELECT Id, echosign_dev1__Status__c, echosign_dev1__Contract__c
            FROM echosign_dev1__SIGN_Agreement__c
            WHERE echosign_dev1__Contract__c IN :contractIds
        ]) {
            agreementMap.put(ag.echosign_dev1__Contract__c, ag);
        }


        OnboardingHelper.processContracts(
            filtered,
            accountMap,
            skipContracts,
            agreementMap,
            vendorId,
            taMap,
            customizationToTemplateMap,
            ndaOnboardingByAccount
        );
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: send notification or log summary
    }

    private void preloadData() {
        if (vendorId != null && taMap != null && !taMap.isEmpty()) return;

        vendorId = [SELECT Id FROM Vendor__c WHERE Name = 'PerfectVision' LIMIT 1].Id;

        taMap = new Map<String, Territory_Assignments__c>();
        for (Territory_Assignments__c ta : [
            SELECT Id, Division__c, Territory__c, Region__c, Base_App_OB_Rep__c FROM Territory_Assignments__c
        ]) {
            String key = ta.Division__c + '|' + ta.Territory__c + '|' + ta.Region__c;
            taMap.put(key, ta);
        }

        customizationToTemplateMap = new Map<Id, Id>();

        List<Vendor_Customization__c> vcs = [
            SELECT Id, Action_Plan_Template__c
            FROM Vendor_Customization__c
            WHERE Vendor__r.Name = 'PerfectVision'
        ];

        for (Vendor_Customization__c vc : vcs) {
            customizationToTemplateMap.put(vc.Id, vc.Action_Plan_Template__c);
        }

    }
}