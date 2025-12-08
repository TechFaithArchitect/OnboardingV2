public with sharing class OnboardingHelper {

    public static void processContracts(
        List<Contract> contracts,
        Map<Id, Account> accountMap,
        Set<Id> skipContracts,
        Map<String, Territory_Assignments__c> taMap,
        Map<Id, Id> customizationToTemplateMap,
        Map<Id, Onboarding__c> ndaOnboardingByAccount
    ) {
        Map<Id, Id> contractToCustomizationId = getCustomizationIds(contracts);
        Map<Id, Onboarding__c> frontierOnboardingByAccount = new Map<Id, Onboarding__c>();
        RecordBuckets buckets = new RecordBuckets();
        List<ActionPlan> actionPlans = new List<ActionPlan>();
        Map<Id, Integer> contractToAPIndex = new Map<Id, Integer>();

        // Child creation maps
        Map<Id, Background_Check__c> bgMap = new Map<Id, Background_Check__c>();
        Map<Id, License__c> blMap = new Map<Id, License__c>();
        Map<Id, License__c> dlMap = new Map<Id, License__c>();
        Map<Id, Clearing_House__c> chMap = new Map<Id, Clearing_House__c>();
        Map<Id, Credit_Check__c> ccMap = new Map<Id, Credit_Check__c>();
        Map<Id, Labor_Form__c> lfMap = new Map<Id, Labor_Form__c>();
        Map<Id, Dealer_Compliance__c> dcMap = new Map<Id, Dealer_Compliance__c>();
        Map<Id, Net_Terms__c> ntMap = new Map<Id, Net_Terms__c>();
        Map<Id, Net_Terms__c> tcMap = new Map<Id, Net_Terms__c>();
        Map<Id, Personal_Guarantee__c> pgMap = new Map<Id, Personal_Guarantee__c>();
        Map<Id, Chuzo_Agreement__c> caMap = new Map<Id, Chuzo_Agreement__c>();
        Map<Id, ERP_Setup__c> erpMap = new Map<Id, ERP_Setup__c>();

        Set<Id> templateIds = new Set<Id>(customizationToTemplateMap.values());

        Map<Id, Id> templateToFinalVersionId = new Map<Id, Id>();
        Map<Id, Dealer_Insurance__c> insuranceByAccount = new Map<Id, Dealer_Insurance__c>(
            [SELECT Id, Account_Name__c FROM Dealer_Insurance__c 
             WHERE Account_Name__c IN :accountMap.keySet()]
        );

        for (ActionPlanTemplateVersion v : [
            SELECT Id, ActionPlanTemplateId
            FROM ActionPlanTemplateVersion
            WHERE ActionPlanTemplateId IN :templateIds
            AND Status = 'Final'
        ]) {
            templateToFinalVersionId.put(v.ActionPlanTemplateId, v.Id);
        }

        Map<Id, String> recordTypeIdToVendorName = new Map<Id, String>();
        for (RecordType rt : [
            SELECT Id, Name FROM RecordType 
            WHERE Id IN :new Map<Id, Contract>(contracts).keySet()
        ]) {
            String vendorName = (rt.Name == 'NDA' || rt.Name == 'New Dealer Application (DOM)') 
                                ? 'PerfectVision' : rt.Name;
            recordTypeIdToVendorName.put(rt.Id, vendorName);
        }

        for (Contract c : contracts) {

            if (skipContracts.contains(c.Id)) continue;

            Account acct = accountMap.get(c.AccountId);
            if (acct == null) continue;

            Onboarding__c existingNDA = ndaOnboardingByAccount.get(acct.Id);
            String vendorName = recordTypeIdToVendorName.get(c.RecordTypeId);
            Boolean isFrontier = vendorName == 'Frontier';

            if (isFrontier) {
                if (frontierOnboardingByAccount.containsKey(acct.Id)) continue;

                processVendorContract(
                    c, acct, taMap, customizationToTemplateMap, 
                    templateToFinalVersionId, buckets, actionPlans, 
                    contractToAPIndex, contractToCustomizationId, 
                    insuranceByAccount
                );
                frontierOnboardingByAccount.put(acct.Id, new Onboarding__c(Account__c = acct.Id));
                continue;
            }

            Id vendorCustomizationId = contractToCustomizationId.get(c.Id);
            String taKey = acct.Division__c + '|' + acct.Territory__c + '|' + acct.Region__c;
            Territory_Assignments__c ta = taMap.get(taKey);

            if (existingNDA != null && c.RecordType.Name == 'New Dealer Application (DOM)') {

                Onboarding__c ob = new Onboarding__c(
                    Account__c = acct.Id,
                    Opportunity__c = c.Opportunity_to_Contract__c,
                    Contract__c = c.Id,
                    Onboarding_Status__c = c.Application_Status__c,
                    Onboarding_Type__c = 'Program Dealer',
                    Territory_Assignments__c = ta != null ? ta.Id : null,
                    Vendor_Customization__c = vendorCustomizationId,
                    LearnUpon_Training_Status__c = 'Incomplete',
                    Contract_Status__c = c.Status,
                    Background_Check__c = existingNDA.Background_Check__c,
                    Business_License__c = existingNDA.Business_License__c,
                    Drivers_License__c = existingNDA.Drivers_License__c,
                    Clearing_House__c = existingNDA.Clearing_House__c,
                    Credit_Check__c = existingNDA.Credit_Check__c,
                    Labor_Form__c = existingNDA.Labor_Form__c,
                    Compliance__c = existingNDA.Compliance__c,
                    Net_Terms__c = existingNDA.Net_Terms__c,
                    Personal_Guarantee__c = existingNDA.Personal_Guarantee__c,
                    Chuzo_Agreement__c = existingNDA.Chuzo_Agreement__c,
                    ERP_Setup__c = existingNDA.ERP_Setup__c
                );

                buckets.onboardingList.add(ob);
                buckets.contractsToUpdate.add(c);
                continue;
            }

            // Standard contract onboarding
            processContract(
                c, acct, taMap, customizationToTemplateMap, 
                templateToFinalVersionId, buckets, actionPlans, 
                contractToAPIndex, contractToCustomizationId
            );

            Contact contact = new Contact(Id = c.Principal_Owner__c);

            bgMap.put(c.Id, new Background_Check__c(Account__c = acct.Id, Contact__c = contact.Id, Status__c = c.Background_Check__c));
            blMap.put(c.Id, new License__c(Account__c = acct.Id, Contact__c = contact.Id, Status__c = c.Business_License__c, Type__c = 'Business License'));
            dlMap.put(c.Id, new License__c(Account__c = acct.Id, Contact__c = contact.Id, Status__c = c.Drivers_License__c, Type__c = 'Driver\'s License'));
            chMap.put(c.Id, new Clearing_House__c(Account__c = acct.Id, Status__c = c.ACH__c));
            ccMap.put(c.Id, new Credit_Check__c(Account__c = acct.Id, Contact__c = contact.Id, Status__c = c.Credit_Check__c));
            lfMap.put(c.Id, new Labor_Form__c(Account__c = acct.Id, Contact__c = contact.Id, Status__c = c.W9__c));
            dcMap.put(c.Id, new Dealer_Compliance__c(Account__c = acct.Id, Status__c = c.Credit_Check__c));
            ntMap.put(c.Id, new Net_Terms__c(Account__c = acct.Id, Status__c = c.Terms__c));
            tcMap.put(c.Id, new Net_Terms__c(Account__c = acct.Id, Status__c = c.Terms__c));
            pgMap.put(c.Id, new Personal_Guarantee__c(Account__c = acct.Id, Status__c = 'Not Started'));
            caMap.put(c.Id, new Chuzo_Agreement__c(Account__c = acct.Id, Status__c = 'Not Started'));
            erpMap.put(c.Id, new ERP_Setup__c(Account__c = acct.Id, Status__c = c.AX_Setup__c));
        }

        // Insert children + map back
        Map<Id, Id> bgIdMap = insertAndMap(bgMap);
        Map<Id, Id> blIdMap = insertAndMap(blMap);
        Map<Id, Id> dlIdMap = insertAndMap(dlMap);
        Map<Id, Id> chIdMap = insertAndMap(chMap);
        Map<Id, Id> ccIdMap = insertAndMap(ccMap);
        Map<Id, Id> lfIdMap = insertAndMap(lfMap);
        Map<Id, Id> dcIdMap = insertAndMap(dcMap);
        Map<Id, Id> ntIdMap = insertAndMap(ntMap);
        Map<Id, Id> tcIdMap = insertAndMap(tcMap);
        Map<Id, Id> pgIdMap = insertAndMap(pgMap);
        Map<Id, Id> caIdMap = insertAndMap(caMap);
        Map<Id, Id> erpIdMap = insertAndMap(erpMap);

        Map<Id, Onboarding__c> contractToOnboarding = new Map<Id, Onboarding__c>();
        for (Onboarding__c ob : buckets.onboardingList) {
            contractToOnboarding.put(ob.Contract__c, ob);
        }

        assignChildIdsToOnboarding(contractToOnboarding, bgIdMap, 'Background_Check__c');
        assignChildIdsToOnboarding(contractToOnboarding, blIdMap, 'Business_License__c');
        assignChildIdsToOnboarding(contractToOnboarding, dlIdMap, 'Drivers_License__c');
        assignChildIdsToOnboarding(contractToOnboarding, chIdMap, 'Clearing_House__c');
        assignChildIdsToOnboarding(contractToOnboarding, ccIdMap, 'Credit_Check__c');
        assignChildIdsToOnboarding(contractToOnboarding, lfIdMap, 'Labor_Form__c');
        assignChildIdsToOnboarding(contractToOnboarding, dcIdMap, 'Compliance__c');
        assignChildIdsToOnboarding(contractToOnboarding, ntIdMap, 'Net_Terms__c');
        assignChildIdsToOnboarding(contractToOnboarding, tcIdMap, 'Terms_Conditions__c');
        assignChildIdsToOnboarding(contractToOnboarding, pgIdMap, 'Personal_Guarantee__c');
        assignChildIdsToOnboarding(contractToOnboarding, caIdMap, 'Chuzo_Agreement__c');
        assignChildIdsToOnboarding(contractToOnboarding, erpIdMap, 'ERP_Setup__c');

        if (!actionPlans.isEmpty()) insert actionPlans;
        insertIfNotEmpty(buckets.onboardingList);
        insertIfNotEmpty(buckets.voeps);
        linkActionPlansToOnboardings(buckets.onboardingList, contractToAPIndex, actionPlans);
        updateIfNotEmpty(buckets.contractsToUpdate);

        // NEW — resolve Adobe agreements by contract lookup
        mapAgreementsToOnboarding(buckets.onboardingList);

        updateTasksForActionPlanItems(contractToOnboarding, taMap);
    }

    private static void processContract(
        Contract c,
        Account acct,
        Map<String, Territory_Assignments__c> taMap,
        Map<Id, Id> customizationToTemplateMap,
        Map<Id, Id> templateToFinalVersionId,
        RecordBuckets buckets,
        List<ActionPlan> actionPlans,
        Map<Id, Integer> contractToAPIndex,
        Map<Id, Id> contractToCustomizationId
    ) {
        String taKey = acct.Division__c + '|' + acct.Territory__c + '|' + acct.Region__c;
        Territory_Assignments__c ta = taMap.get(taKey);
        Id repId = ta != null ? ta.Base_App_OB_Rep__c : UserInfo.getUserId();

        Id vendorCustomizationId = contractToCustomizationId.get(c.Id);
        if (vendorCustomizationId == null) return;

        Id templateId = customizationToTemplateMap.get(vendorCustomizationId);
        Id versionId = templateToFinalVersionId.get(templateId);

        if (versionId != null) {
            ActionPlan ap = new ActionPlan(
                TargetId = acct.Id,
                StartDate = c.CreatedDate.date(),
                Name = acct.Name + ' Action Plan',
                ActionPlanType = 'Sales',
                ActionPlanTemplateVersionId = versionId,
                OwnerId = repId
            );
            actionPlans.add(ap);
            contractToAPIndex.put(c.Id, actionPlans.size() - 1);
        }

        Onboarding__c ob = new Onboarding__c(
            Account__c = acct.Id,
            Opportunity__c = c.Opportunity_to_Contract__c,
            Contract__c = c.Id,
            Onboarding_Status__c = c.Application_Status__c,
            Onboarding_Type__c = 'Program Dealer',
            Territory_Assignments__c = ta != null ? ta.Id : null,
            Vendor_Customization__c = vendorCustomizationId,
            LearnUpon_Training_Status__c = 'Incomplete',
            Contract_Status__c = c.Status
        );

        buckets.onboardingList.add(ob);
        buckets.contractsToUpdate.add(c);
    }

    private static void processVendorContract(
        Contract c,
        Account acct,
        Map<String, Territory_Assignments__c> taMap,
        Map<Id, Id> customizationToTemplateMap,
        Map<Id, Id> templateToFinalVersionId,
        RecordBuckets buckets,
        List<ActionPlan> actionPlans,
        Map<Id, Integer> contractToAPIndex,
        Map<Id, Id> contractToCustomizationId,
        Map<Id, Dealer_Insurance__c> insuranceByAccount
    ) {
        String taKey = acct.Division__c + '|' + acct.Territory__c + '|' + acct.Region__c;
        Territory_Assignments__c ta = taMap.get(taKey);
        Id repId = ta != null ? ta.Base_App_OB_Rep__c : UserInfo.getUserId();

        Id vendorCustomizationId = contractToCustomizationId.get(c.Id);
        if (vendorCustomizationId == null) return;

        Id templateId = customizationToTemplateMap.get(vendorCustomizationId);
        Id versionId = templateToFinalVersionId.get(templateId);

        if (versionId != null) {
            actionPlans.add(new ActionPlan(
                TargetId = acct.Id,
                StartDate = c.CreatedDate.date(),
                Name = acct.Name + ' Frontier Action Plan',
                ActionPlanType = 'Sales',
                ActionPlanTemplateVersionId = versionId,
                OwnerId = repId
            ));
            contractToAPIndex.put(c.Id, actionPlans.size() - 1);
        }

        Vendor_Order_Entry_Platform__c voep = new Vendor_Order_Entry_Platform__c(
            Account__c = acct.Id,
            Setup_Status__c = 'Not Started'
        );
        buckets.voeps.add(voep);

        Dealer_Insurance__c insurance = insuranceByAccount.get(acct.Id);

        Onboarding__c ob = new Onboarding__c(
            Account__c = acct.Id,
            Contract__c = c.Id,
            Onboarding_Status__c = c.Application_Status__c,
            Onboarding_Type__c = 'Vendor Onboarding',
            Territory_Assignments__c = ta != null ? ta.Id : null,
            Vendor_Customization__c = vendorCustomizationId,
            LearnUpon_Training_Status__c = 'Incomplete',
            Dealer_Insurance__c = insurance != null ? insurance.Id : null,
            Insurance_Status__c = c.Insurance__c,
            Contract_Status__c = c.Status
        );

        buckets.onboardingList.add(ob);
        buckets.contractsToUpdate.add(c);
    }

    //-----------------------------------
    // NEW — Adobe Agreement Linking
    //-----------------------------------
    private static void mapAgreementsToOnboarding(List<Onboarding__c> onboardings) {

        Map<Id, Onboarding__c> contractMap = new Map<Id, Onboarding__c>();
        for (Onboarding__c ob : onboardings) {
            contractMap.put(ob.Contract__c, ob);
        }

        List<echosign_dev1__SIGN_Agreement__c> ags = [
            SELECT Id, echosign_dev1__Contract__c, echosign_dev1__Status__c
            FROM echosign_dev1__SIGN_Agreement__c
            WHERE echosign_dev1__Contract__c IN :contractMap.keySet()
        ];

        for (echosign_dev1__SIGN_Agreement__c ag : ags) {
            Onboarding__c ob = contractMap.get(ag.echosign_dev1__Contract__c);
            if (ob != null) {
           //     ob.Agreement_Lookup__c = ag.Id; // Link agreement to onboarding
           //     ob.Agreement_Status__c = ag.echosign_dev1__Status__c; // Sync current status
            }
        }

        update onboardings;
    }

    //-----------------------------------
    // (rest of your helper methods unchanged below)
    //-----------------------------------

    private static void updateTasksForActionPlanItems(Map<Id, Onboarding__c> contractToOB, Map<String, Territory_Assignments__c> taMap) {
        Set<Id> actionPlanIds = new Set<Id>();
        for (Onboarding__c ob : contractToOB.values()) {
            if (ob.Action_Plan__c != null) {
                actionPlanIds.add(ob.Action_Plan__c);
            }
        }
        if (actionPlanIds.isEmpty()) return;

        List<ActionPlanItem> apItems = [
            SELECT Id, ItemId, ActionPlanId
            FROM ActionPlanItem
            WHERE ActionPlanId IN :actionPlanIds AND ItemId != null
        ];

        Set<Id> taskIds = new Set<Id>();
        Map<Id, Id> taskToAPId = new Map<Id, Id>();
        for (ActionPlanItem item : apItems) {
            taskIds.add(item.ItemId);
            taskToAPId.put(item.ItemId, item.ActionPlanId);
        }

        Map<Id, Task> taskMap = new Map<Id, Task>([
            SELECT Id, OwnerId, WhatId 
            FROM Task WHERE Id IN :taskIds
        ]);

        List<Task> updates = new List<Task>();
        for (Task t : taskMap.values()) {
            Id apId = taskToAPId.get(t.Id);
            Onboarding__c ob = null;

            for (Onboarding__c o : contractToOB.values()) {
                if (o.Action_Plan__c == apId) {
                    ob = o;
                    break;
                }
            }
            if (ob == null || ob.Account__c == null) continue;

            Id ownerId = UserInfo.getUserId();
            Account acct = [SELECT Division__c, Territory__c, Region__c 
                            FROM Account WHERE Id = :ob.Account__c LIMIT 1];

            String key = acct.Division__c + '|' + acct.Territory__c + '|' + acct.Region__c;
            Territory_Assignments__c ta = taMap.get(key);
            if (ta != null && ta.Base_App_OB_Rep__c != null) {
                ownerId = ta.Base_App_OB_Rep__c;
            }

            t.OwnerId = ownerId;
            t.WhatId = ob.Id;
            updates.add(t);
        }

        if (!updates.isEmpty()) update updates;
    }

    private static void linkActionPlansToOnboardings(
        List<Onboarding__c> onboardingList, 
        Map<Id, Integer> indexMap, 
        List<ActionPlan> actionPlans
    ) {
        for (Onboarding__c ob : onboardingList) {
            Integer idx = indexMap.get(ob.Contract__c);
            if (idx != null && idx < actionPlans.size()) {
                ob.Action_Plan__c = actionPlans[idx].Id;
            }
        }
    }

    // --- support insert helpers unchanged ---
    private static Map<Id, Id> insertAndMap(Map<Id, SObject> recordMap) {
        Map<Id, Id> result = new Map<Id, Id>();
        List<SObject> toInsert = new List<SObject>();
        Map<Integer, Id> idxMap = new Map<Integer, Id>();
        Integer i = 0;

        for (Id contractId : recordMap.keySet()) {
            toInsert.add(recordMap.get(contractId));
            idxMap.put(i, contractId);
            i++;
        }

        if (!toInsert.isEmpty()) {
            Database.DMLOptions opts = new Database.DMLOptions();
            opts.EmailHeader.triggerUserEmail = false;
            opts.EmailHeader.triggerAutoResponseEmail = false;
            opts.EmailHeader.triggerOtherEmail = false;

            for (SObject s : toInsert) s.setOptions(opts);

            Database.SaveResult[] results = Database.insert(toInsert, false);
            for (Integer j = 0; j < results.size(); j++) {
                if (results[j].isSuccess()) {
                    result.put(idxMap.get(j), toInsert[j].Id);
                }
            }
        }
        return result;
    }

    private static void assignChildIdsToOnboarding(
        Map<Id, Onboarding__c> obMap,
        Map<Id, Id> contractToChildId,
        String onboardingField
    ) {
        for (Id contractId : contractToChildId.keySet()) {
            if (obMap.containsKey(contractId)) {
                obMap.get(contractId).put(onboardingField, contractToChildId.get(contractId));
            }
        }
    }

    private static void insertIfNotEmpty(List<SObject> records) {
        if (!records.isEmpty()) {
            Database.DMLOptions opts = new Database.DMLOptions();
            opts.EmailHeader.triggerUserEmail = false;
            opts.EmailHeader.triggerAutoResponseEmail = false;
            opts.EmailHeader.triggerOtherEmail = false;
            for (SObject s : records) s.setOptions(opts);
            insert records;
        }
    }

    private static void updateIfNotEmpty(List<SObject> records) {
        if (!records.isEmpty()) {
            Database.DMLOptions opts = new Database.DMLOptions();
            opts.EmailHeader.triggerUserEmail = false;
            opts.EmailHeader.triggerAutoResponseEmail = false;
            opts.EmailHeader.triggerOtherEmail = false;
            for (SObject s : records) s.setOptions(opts);
            update records;
        }
    }

    // Record bucket container
    public class RecordBuckets {
        public List<Onboarding__c> onboardingList = new List<Onboarding__c>();
        public List<Contract> contractsToUpdate = new List<Contract>();
        public List<Vendor_Order_Entry_Platform__c> voeps = new List<Vendor_Order_Entry_Platform__c>();
    }

    // The original getCustomizationIds method unchanged
    private static Map<Id, Id> getCustomizationIds(List<Contract> contracts) {
        // ... unchanged content ...
        // *** For brevity: paste your original method exactly here ***
        // (it contains no Vendor__c or Agreement__c logic)
        //────────────────────────────────────────────────────────────
        Map<Id, Id> contractIdToCustomizationId = new Map<Id, Id>();
        Set<Id> recordTypeIds = new Set<Id>();
        for (Contract c : contracts) if (c.RecordTypeId != null) recordTypeIds.add(c.RecordTypeId);

        Map<Id, RecordType> rtMap = new Map<Id, RecordType>([
            SELECT Id, Name FROM RecordType WHERE Id IN :recordTypeIds
        ]);

        Map<Id, Contract_Record_Type_Reference__c> rtRefMap = new Map<Id, Contract_Record_Type_Reference__c>();
        for (Contract_Record_Type_Reference__c ref : [
            SELECT Id, RecordTypeId__c FROM Contract_Record_Type_Reference__c WHERE RecordTypeId__c IN :recordTypeIds
        ]) {
            rtRefMap.put(ref.RecordTypeId__c, ref);
        }

        Set<String> vendorNames = new Set<String>();
        Map<Id, String> recordTypeIdToVendorName = new Map<Id, String>();
        for (RecordType rt : rtMap.values()) {
            String v = (rt.Name == 'NDA' || rt.Name == 'New Dealer Application (DOM)') 
                       ? 'PerfectVision' : rt.Name;
            recordTypeIdToVendorName.put(rt.Id, v);
            vendorNames.add(v);
        }

        Map<String, Id> vendorNameToId = new Map<String, Id>();
        for (Vendor__c vendor : [
            SELECT Id, Name FROM Vendor__c WHERE Name IN :vendorNames
        ]) vendorNameToId.put(vendor.Name, vendor.Id);

        List<Vendor_Customization__c> vcs = [
            SELECT Id, Vendor__c, Contract_Record_Type__c
            FROM Vendor_Customization__c
            WHERE Vendor__c IN :vendorNameToId.values()
            AND Contract_Record_Type__c IN :rtRefMap.values()
        ];

        Map<String, Id> vcKey = new Map<String, Id>();
        for (Vendor_Customization__c vc : vcs)
            vcKey.put(vc.Vendor__c + '|' + vc.Contract_Record_Type__c, vc.Id);

        for (Contract c : contracts) {
            RecordType rt = rtMap.get(c.RecordTypeId);
            Contract_Record_Type_Reference__c ref = rtRefMap.get(c.RecordTypeId);
            Id vId = vendorNameToId.get(recordTypeIdToVendorName.get(c.RecordTypeId));

            if (vId != null && ref != null) {
                String key = vId + '|' + ref.Id;
                if (vcKey.containsKey(key)) contractIdToCustomizationId.put(c.Id, vcKey.get(key));
            }
        }
        return contractIdToCustomizationId;
        //────────────────────────────────────────────────────────────
    }
}