public class OnboardingTaskAutomationJob {
    public static void run() {
        System.debug('▶▶ STARTING OnboardingTaskAutomationJob');

        // Load CMDT into a Map keyed by 'Object.Field'
        Map<String, Onboarding_Automation_Config__mdt> configByObjectField = new Map<String, Onboarding_Automation_Config__mdt>();
        for (Onboarding_Automation_Config__mdt cfg : [
            SELECT Source_Object__c, Field_Name__c, Onboarding_Lookup__c,
                   Stale_Days__c, Close_Days__c, Stale_Subject_Label__c, Close_Subject_Label__c,
                   Stale_Description_Label__c, Close_Description_Label__c
            FROM Onboarding_Automation_Config__mdt WHERE Is_Active__c = true
        ]) {
            System.debug('🧪 CMDT Record – Source_Object__c: ' + cfg.Source_Object__c);
            System.debug('🧪 CMDT Record – Field_Name__c: ' + cfg.Field_Name__c);
            String key = cfg.Source_Object__c + '.' + cfg.Field_Name__c;
            configByObjectField.put(key, cfg);
            System.debug('📌 CMDT Loaded: ' + key);
        }

        // Pull recent changes
        DateTime since = System.now().addDays(-10);
        System.debug('📆 Pulling changes since: ' + since);
        List<Onboarding_Status_Change__c> changes = [
            SELECT Id, Onboarding__c, Source_Object__c, Field_Name__c, Change_Date__c, New_Value__c
            FROM Onboarding_Status_Change__c
            WHERE Change_Date__c >= :since
        ];
        System.debug('📄 Changes found: ' + changes.size());

        // Get Onboarding records tied to changes
        Set<Id> onboardingIds = new Set<Id>();
        for (Onboarding_Status_Change__c change : changes) {
            if (change.Onboarding__c != null) {
                onboardingIds.add(change.Onboarding__c);
            }
        }

        Set<String> terminalStatuses = new Set<String>{'Setup Complete', 'Denied', 'Cancelled', 'Expired'};

        Map<Id, Onboarding__c> onboardingMap = new Map<Id, Onboarding__c>(
            [SELECT Id, Action_Plan__c, Territory_Assignments__r.Recruiter__c
             FROM Onboarding__c
             WHERE Id IN :onboardingIds]
        );

        List<Task> tasksToInsert = new List<Task>();
        Map<Integer, ActionPlanItem> taskIndexToItemMap = new Map<Integer, ActionPlanItem>();

        Integer idx = 0;
        for (Onboarding_Status_Change__c change : changes) {
            System.debug('🔄 Processing change: ' + change.Id);
            String key = change.Source_Object__c + '.' + change.Field_Name__c;
            System.debug('🔑 Constructed key: ' + key);

             // ❗ Skip if the new value is a terminal status
            if (terminalStatuses.contains(change.New_Value__c)) {
                System.debug('⛔ Skipping – Terminal status: ' + change.New_Value__c);
                continue;
            }

            if (!configByObjectField.containsKey(key)) {
                System.debug('⛔ Skipping – config not found for key: ' + key);
                continue;
            }

            Onboarding_Automation_Config__mdt config = configByObjectField.get(key);

            if (!onboardingMap.containsKey(change.Onboarding__c)) {
                System.debug('⛔ Skipping – Onboarding record not found: ' + change.Onboarding__c);
                continue;
            }

            Onboarding__c ob = onboardingMap.get(change.Onboarding__c);

            if (ob.Action_Plan__c == null) {
                System.debug('⛔ Skipping – Action_Plan__c is null');
                continue;
            }
            if (ob.Territory_Assignments__r == null || ob.Territory_Assignments__r.Recruiter__c == null) {
                System.debug('⛔ Skipping – Recruiter is null');
                continue;
            }

            Integer daysOld = change.Change_Date__c.date().daysBetween(DateTime.now().date());
            Boolean isStale = daysOld >= config.Stale_Days__c && daysOld < config.Stale_Days__c + 1;
            Boolean toBeClosed = daysOld >= config.Close_Days__c && daysOld < config.Close_Days__c + 1;
            System.debug('📊 daysOld = ' + daysOld + ' | Stale: ' + isStale + ' | Close: ' + toBeClosed);

            if (!isStale && !toBeClosed) {
                System.debug('⛔ Skipping – Doesn’t meet stale/close day criteria');
                continue;
            }

            String subjectLabelKey = toBeClosed ? config.Close_Subject_Label__c : config.Stale_Subject_Label__c;
            String descLabelKey = toBeClosed ? config.Close_Description_Label__c : config.Stale_Description_Label__c;

            String subject = OnboardingLabelsUtility.getLabel(subjectLabelKey);
            String descriptionText = OnboardingLabelsUtility.getLabel(descLabelKey);

            Task t = new Task(
                Subject = subject,
                Description = descriptionText,
                Status = 'Not Started',
                Priority = 'High',
                ActivityDate = Date.today().addDays(2),
                WhatId = ob.Id,
                OwnerId = ob.Territory_Assignments__r.Recruiter__c
            );

            ActionPlanItem apli = new ActionPlanItem(
                ActionPlanId = ob.Action_Plan__c,
                ItemState = 'InProgress',
                Name = subject
            );

            tasksToInsert.add(t);
            taskIndexToItemMap.put(idx, apli);
            idx++;
        }

        if (!tasksToInsert.isEmpty()) {
            try {
                insert tasksToInsert;
                System.debug('✅ Inserted Tasks: ' + tasksToInsert.size());
            } catch (DmlException e) {
                System.debug('❌ Failed to insert Tasks: ' + e.getMessage());
                return;
            }

            List<ActionPlanItem> itemsToInsert = new List<ActionPlanItem>();
            for (Integer i = 0; i < tasksToInsert.size(); i++) {
                Task t = tasksToInsert[i];
                ActionPlanItem apli = taskIndexToItemMap.get(i);
                if (apli != null) {
                    apli.ItemId = t.Id;
                    apli.Name = t.Subject;
                    itemsToInsert.add(apli);
                }
            }

            try {
                insert itemsToInsert;
                System.debug('✅ Inserted ActionPlanItems: ' + itemsToInsert.size());
            } catch (DmlException e) {
                System.debug('❌ Failed to insert ActionPlanItems: ' + e.getMessage());
            }
        } else {
            System.debug('⚠️ No tasks generated.');
        }

        System.debug('🏁 FINISHED OnboardingTaskAutomationJob');
    }
}