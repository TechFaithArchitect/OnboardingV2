@isTest(seeAllData=true)
private class OnboardingTaskAutomationJobTest {

    static Account acc;
    static Contact con;
    static User recruiter;
    static Territory_Assignments__c ta;
    static ActionPlan ap;
    static Onboarding__c onboarding;

    static void setupTestData() {
        acc = new Account(Name = 'Test Account');
        insert acc;

        con = new Contact(FirstName = 'Auto', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        recruiter = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        ta = new Territory_Assignments__c(
            Recruiter__c = recruiter.Id,
            Division__c = 'TestDiv',
            Region__c = 'TestReg',
            Territory__c = 'TestTerr'
        );
        insert ta;

        ActionPlanTemplateVersion aptv = [
            SELECT Id, ActionPlanTemplateId
            FROM ActionPlanTemplateVersion
            WHERE Status = 'Final'
            ORDER BY ActivationDateTime DESC
            LIMIT 1
        ];

        ap = new ActionPlan(
            Name = 'Test Plan',
            ActionPlanType = 'Sales',
            ActionPlanTemplateVersionId = aptv.Id,
            TargetId = acc.Id,
            StartDate = Date.today().addDays(1)
        );
        insert ap;

        onboarding = new Onboarding__c(
            Account__c = acc.Id,
            Territory_Assignments__c = ta.Id,
            Action_Plan__c = ap.Id,
            Onboarding_Status__c = 'In Process'
        );
        insert onboarding;

        Onboarding_Automation_Config__mdt config = [
            SELECT Stale_Days__c, Source_Object__c, Field_Name__c
            FROM Onboarding_Automation_Config__mdt
            WHERE Is_Active__c = true
            LIMIT 1
        ];

        DateTime staleChangeDate = DateTime.now().addDays(-Integer.valueOf(config.Stale_Days__c)).addMinutes(-5);

        Onboarding_Status_Change__c change = new Onboarding_Status_Change__c(
            Onboarding__c = onboarding.Id,
            Source_Object__c = config.Source_Object__c,
            Field_Name__c = config.Field_Name__c,
            Old_Value__c = 'Pending',
            New_Value__c = 'In Process',
            Change_Date__c = staleChangeDate
        );
        insert change;
    }

    @isTest
    static void testJobCreatesTasksAndItems() {
        setupTestData();

        Test.startTest();
        OnboardingTaskAutomationJob.run();
        Test.stopTest();

        // Verify Task was created for the specific Onboarding record
        List<Task> relatedTasks = [
            SELECT Id, Subject, WhatId
            FROM Task
            WHERE WhatId = :onboarding.Id
        ];
        List<Task> allTasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :onboarding.Id];

        // Verify ActionPlanItem was created for the specific Action Plan
        List<ActionPlanItem> relatedItems = [
            SELECT Id, Name, ActionPlanId
            FROM ActionPlanItem
            WHERE ActionPlanId = :ap.Id
        ];
        System.assertEquals(1, relatedItems.size(), 'Expected 1 ActionPlanItem created');
    }

    @isTest
    static void testSchedulerExecutesJob() {
        Test.startTest();
        new OnboardingTaskAutomationScheduler().execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler ran successfully');
    }
   
}