@isTest
private class OnboardingExpirationEvaluatorTest {
/*
    private static String getLabel(String apiName) {
        return Schema.getGlobalDescribe().get(apiName).getDescribe().getLabel();
        }

    @isTest
    static void testFullOnboardingExpirationFlow() {
        Integer thresholdDays = 71;
      
        // Step 1: Setup Account and Contact
        Account acc = new Account(Name = 'Expiration Test Account');
        insert acc;

        Contact c = new Contact(FirstName = 'Test', LastName = 'User', AccountId = acc.Id);
        insert c;

        // Step 2: Create and insert related records (one-by-one to avoid 10-object DML limit)
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c(
            Name = 'Agreement', echosign_dev1__Status__c = 'Signed'
        ); insert agreement;

        Clearing_House__c ch = new Clearing_House__c(Status__c = 'Accounting Approved', Account__c = acc.Id);
        insert ch;

        Dealer_Compliance__c compliance = new Dealer_Compliance__c(Status__c = 'Not Started', Account__c = acc.Id);
        insert compliance;

        Credit_Check__c credit = new Credit_Check__c(Status__c = 'Incomplete', Account__c = acc.Id, Contact__c = c.Id);
        insert credit;

        License__c license = new License__c(Status__c = 'Incomplete', Account__c = acc.Id, Contact__c = c.Id);
        insert license;

        ERP_Setup__c erp = new ERP_Setup__c(Status__c = 'Incomplete', Account__c = acc.Id);
        insert erp;

        Dealer_Insurance__c insurance = new Dealer_Insurance__c(
            Commercial_General_Liability_Status__c = 'Active', Account_Name__c = acc.Id
        ); insert insurance;

        Labor_Form__c labor = new Labor_Form__c(Status__c = 'Incomplete', Account__c = acc.Id, Contact__c = c.Id);
        insert labor;

        Background_Check__c background = new Background_Check__c(Status__c = 'Incomplete', Account__c = acc.Id, Contact__c = c.Id);
        insert background;

        LearnUponP__LearnUponContactEnrollment__c learn = new LearnUponP__LearnUponContactEnrollment__c(
            LearnUponP__Status__c = 'Completed', LearnUponP__SFContact__c = c.Id
        ); insert learn;

        Net_Terms__c net = new Net_Terms__c(Status__c = 'Not Started', Account__c = acc.Id);
        insert net;

        Vendor_Order_Entry_Platform__c vop = new Vendor_Order_Entry_Platform__c(
            Setup_Status__c = 'Incomplete', Account__c = acc.Id
        ); insert vop;

        // Step 3: Create onboarding record linking everything
        Onboarding__c ob = new Onboarding__c(
            Account__c = acc.Id,
            Agreement__c = agreement.Id,
            Clearing_House__c = ch.Id,
            Compliance__c = compliance.Id,
            Credit_Check__c = credit.Id,
            Drivers_License__c = license.Id,
            ERP_Setup__c = erp.Id,
            Dealer_Insurance__c = insurance.Id,
            Labor_Form__c = labor.Id,
            Background_Check__c = background.Id,
            LearnUponContactEnrollment__c = learn.Id,
            Net_Terms__c = net.Id,
            Vendor_Order_Entry_Platform__c = vop.Id,
            Onboarding_Status__c = 'New'
        ); insert ob;

        // Step 4: Backdate Status Changes to simulate aging
        List<Onboarding_Status_Change__c> changes = [
            SELECT Id, Change_Date__c
            FROM Onboarding_Status_Change__c
            WHERE Onboarding__c = :ob.Id
        ];

        for (Onboarding_Status_Change__c change : changes) {
            change.Change_Date__c = System.now().addDays(-thresholdDays); // simulate stale
        }
        update changes;

        // Step 5: Create full config list for all tracked objects
        List<Onboarding_Status_Tracking_Config__mdt> configs = new List<Onboarding_Status_Tracking_Config__mdt>{
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'Dealer_Compliance__c',
                Field__c = 'Status__c',
                Lookup_To_Onboarding__c = 'Compliance__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'Credit_Check__c',
                Field__c = 'Status__c',
                Lookup_To_Onboarding__c = 'Credit_Check__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'License__c',
                Field__c = 'Status__c',
                Lookup_To_Onboarding__c = 'Drivers_License__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'ERP_Setup__c',
                Field__c = 'Status__c',
                Lookup_To_Onboarding__c = 'ERP_Setup__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'Dealer_Insurance__c',
                Field__c = 'Commercial_General_Liability_Status__c',
                Lookup_To_Onboarding__c = 'Dealer_Insurance__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'Labor_Form__c',
                Field__c = 'Status__c',
                Lookup_To_Onboarding__c = 'Labor_Form__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'Background_Check__c',
                Field__c = 'Status__c',
                Lookup_To_Onboarding__c = 'Background_Check__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'LearnUponP__LearnUponContactEnrollment__c',
                Field__c = 'LearnUponP__Status__c',
                Lookup_To_Onboarding__c = 'LearnUponContactEnrollment__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'Net_Terms__c',
                Field__c = 'Status__c',
                Lookup_To_Onboarding__c = 'Net_Terms__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'Vendor_Order_Entry_Platform__c',
                Field__c = 'Setup_Status__c',
                Lookup_To_Onboarding__c = 'Vendor_Order_Entry_Platform__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'echosign_dev1__SIGN_Agreement__c',
                Field__c = 'echosign_dev1__Status__c',
                Lookup_To_Onboarding__c = 'Agreement__c',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            ),
            new Onboarding_Status_Tracking_Config__mdt(
                Object__c = 'Onboarding__c',
                Field__c = 'Onboarding_Status__c',
                Lookup_To_Onboarding__c = 'Id',
                Expire_Threshold_Days__c = thresholdDays,
                Expire_On_Inactivity__c = true,
                IsActive__c = true
            )
        };

        // Step 6: Run expiration evaluator with tracking bypassed
        OnboardingExpirationEvaluator.bypassTracking = true;
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'developers@perfect-vision.com%' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            // call your evaluator here
            OnboardingExpirationEvaluator.runExpirationJobWithConfigs(configs);
            Test.stopTest();
        }

        // Step 7: Verify onboarding was marked as expired
        ob = [SELECT Onboarding_Status__c FROM Onboarding__c WHERE Id = :ob.Id];
        System.assertEquals('Expired', ob.Onboarding_Status__c, 'Onboarding should be expired due to inactivity');
        OnboardingExpirationEvaluator.bypassTracking = false;
    }
    */
}