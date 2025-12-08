@IsTest
private class OnboardingStatusTrackerHandlerTest {


    // --- helpers -------------------------------------------------------------

    private static String getLabel(String apiName) {
        return Schema.getGlobalDescribe().get(apiName).getDescribe().getLabel();
    }

    // Build an in-memory CMDT row (no DML)
    private static Onboarding_Status_Tracking_Config__mdt makeCfg(String obj, String field, String lookup) {
        Onboarding_Status_Tracking_Config__mdt config = new Onboarding_Status_Tracking_Config__mdt();
        config.Object__c = obj;
        config.Field__c  = field;
        config.Lookup_To_Onboarding__c = lookup;
        config.IsActive__c = true;
        return config;
    }

    // Inject rows into the handler (uses @TestVisible hook)
    private static void injectConfigs(List<Onboarding_Status_Tracking_Config__mdt> rows) {
        Map<String, List<Onboarding_Status_Tracking_Config__mdt>> configsByObject = new Map<String, List<Onboarding_Status_Tracking_Config__mdt>>();
        for (Onboarding_Status_Tracking_Config__mdt row : rows) {
            if (!configsByObject.containsKey(row.Object__c)) {
                configsByObject.put(row.Object__c, new List<Onboarding_Status_Tracking_Config__mdt>());
            }
            configsByObject.get(row.Object__c).add(row);
        }
        OnboardingStatusTrackerHandler.setTestConfigs(configsByObject);
    }

    // --- tests ---------------------------------------------------------------

    @IsTest
    static void testAgreementStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('echosign_dev1__SIGN_Agreement__c', 'echosign_dev1__Status__c', 'Agreement__c')
        });

        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c(
            Name = 'Agreement Test',
            echosign_dev1__Status__c = 'Draft'
        );
        insert agreement;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Agreement__c = agreement.Id);
        insert onboarding;

        agreement.echosign_dev1__Status__c = 'Signed';
        update agreement;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('echosign_dev1__SIGN_Agreement__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Agreement trigger should have created one status change record.');
    }

    @IsTest
    static void testClearingHouseTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Clearing_House__c', 'Status__c', 'Clearing_House__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Clearing_House__c clearingHouse = new Clearing_House__c(Status__c = 'Not Started', Account__c = account.Id);
        insert clearingHouse;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Clearing_House__c = clearingHouse.Id);
        insert onboarding;

        clearingHouse.Status__c = 'Accounting Approved';
        update clearingHouse;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Clearing_House__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'ClearingHouse trigger should have created one status change record.');
    }

    @IsTest
    static void testComplianceStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Dealer_Compliance__c', 'Status__c', 'Compliance__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Dealer_Compliance__c compliance = new Dealer_Compliance__c(Status__c = 'Not Started', Account__c = account.Id);
        insert compliance;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Compliance__c = compliance.Id);
        insert onboarding;

        compliance.Status__c = 'Approved';
        update compliance;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Dealer_Compliance__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Compliance trigger should have created one status change record.');
    }

    @IsTest
    static void testCreditCheckStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Credit_Check__c', 'Status__c', 'Credit_Check__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = account.Id);
        insert contact;

        Credit_Check__c credit = new Credit_Check__c(Status__c = 'Not Started', Contact__c = contact.Id, Account__c = account.Id);
        insert credit;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Credit_Check__c = credit.Id);
        insert onboarding;

        credit.Status__c = 'Waived';
        update credit;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Credit_Check__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Credit Check trigger should have created one status change record.');
    }

    @IsTest
    static void testDriversLicenseStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('License__c', 'Status__c', 'Drivers_License__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = account.Id);
        insert contact;

        License__c license = new License__c(Status__c = 'Not Started', Account__c = account.Id, Contact__c = contact.Id);
        insert license;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Drivers_License__c = license.Id);
        insert onboarding;

        license.Status__c = 'Complete';
        update license;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('License__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Drivers License trigger should have created one status change record.');
    }

    @IsTest
    static void testERPSetupStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('ERP_Setup__c', 'Status__c', 'ERP_Setup__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        ERP_Setup__c erpSetup = new ERP_Setup__c(Status__c = 'Not Started', Account__c = account.Id);
        insert erpSetup;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, ERP_Setup__c = erpSetup.Id);
        insert onboarding;

        erpSetup.Status__c = 'Complete';
        update erpSetup;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('ERP_Setup__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'ERP Setup trigger should have created one status change record.');
    }

    @IsTest
    static void testInsuranceStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Dealer_Insurance__c', 'Commercial_General_Liability_Status__c', 'Dealer_Insurance__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Dealer_Insurance__c dealerInsurance = new Dealer_Insurance__c(
            Commercial_General_Liability_Status__c = 'Expired',
            Account_Name__c = account.Id
        );
        insert dealerInsurance;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Dealer_Insurance__c = dealerInsurance.Id);
        insert onboarding;

        dealerInsurance.Commercial_General_Liability_Status__c = 'Active';
        update dealerInsurance;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Dealer_Insurance__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Insurance trigger should have created one status change record.');
    }

    @IsTest
    static void testLaborFormStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Labor_Form__c', 'Status__c', 'Labor_Form__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = account.Id);
        insert contact;

        Labor_Form__c laborForm = new Labor_Form__c(Status__c = 'Not Started', Account__c = account.Id, Contact__c = contact.Id);
        insert laborForm;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Labor_Form__c = laborForm.Id);
        insert onboarding;

        laborForm.Status__c = 'Approved Box 1';
        update laborForm;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Labor_Form__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Labor Form trigger should have created one status change record.');
    }

    @IsTest
    static void testBackgroundCheckStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Background_Check__c', 'Status__c', 'Background_Check__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = account.Id);
        insert contact;

        Background_Check__c backgroundCheck = new Background_Check__c(Status__c = 'Not Started', Account__c = account.Id, Contact__c = contact.Id);
        insert backgroundCheck;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Background_Check__c = backgroundCheck.Id);
        insert onboarding;

        backgroundCheck.Status__c = 'Complete';
        update backgroundCheck;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Background_Check__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Background Check trigger should have created one status change record.');
    }

    @IsTest
    static void testLearnUponContactEnrollmentStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('LearnUponP__LearnUponContactEnrollment__c', 'LearnUponP__Status__c', 'LearnUponContactEnrollment__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(FirstName = 'Test', LastName = 'User',  AccountId = account.Id);
        insert contact;

        LearnUponP__LearnUponContactEnrollment__c learnUponEnrollment =
            new LearnUponP__LearnUponContactEnrollment__c(
                LearnUponP__Status__c = 'Incomplete',
                LearnUponP__SFContact__c = contact.Id
            );
        insert learnUponEnrollment;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, LearnUponContactEnrollment__c = learnUponEnrollment.Id);
        insert onboarding;

        learnUponEnrollment.LearnUponP__Status__c = 'Complete';
        update learnUponEnrollment;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('LearnUponP__LearnUponContactEnrollment__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'LearnUpon trigger should have created one status change record.');
    }

    @IsTest
    static void testNetTermsStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Net_Terms__c', 'Status__c', 'Net_Terms__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Net_Terms__c netTerms = new Net_Terms__c(Status__c = 'Not Started', Account__c = account.Id);
        insert netTerms;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Net_Terms__c = netTerms.Id);
        insert onboarding;

        netTerms.Status__c = 'Complete';
        update netTerms;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Net_Terms__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Net Terms trigger should have created one status change record.');
    }

    @IsTest
    static void testVendorOrderEntryPlatformStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Vendor_Order_Entry_Platform__c', 'Setup_Status__c', 'Vendor_Order_Entry_Platform__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Vendor_Order_Entry_Platform__c vendorOrderEntryPlatform = new Vendor_Order_Entry_Platform__c(Setup_Status__c = 'Not Started', Account__c = account.Id);
        insert vendorOrderEntryPlatform;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Vendor_Order_Entry_Platform__c = vendorOrderEntryPlatform.Id);
        insert onboarding;

        vendorOrderEntryPlatform.Setup_Status__c = 'Complete';
        update vendorOrderEntryPlatform;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Vendor_Order_Entry_Platform__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Vendor Order Entry Platform trigger should have created one status change record.');
    }

    @IsTest
    static void testChuzoAgreementStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Chuzo_Agreement__c', 'Status__c', 'Chuzo_Agreement__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Chuzo_Agreement__c chuzoAgreement = new Chuzo_Agreement__c(Status__c = 'Not Started', Account__c = account.Id);
        insert chuzoAgreement;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Chuzo_Agreement__c = chuzoAgreement.Id);
        insert onboarding;

        chuzoAgreement.Status__c = 'Complete';
        update chuzoAgreement;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Chuzo_Agreement__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Chuzo Agreement trigger should have created one status change record.');
    }

    @IsTest
    static void testPersonalGuaranteeStatusTrigger() {
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Personal_Guarantee__c', 'Status__c', 'Personal_Guarantee__c')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Personal_Guarantee__c personalGuarantee = new Personal_Guarantee__c(Status__c = 'Not Started', Account__c = account.Id);
        insert personalGuarantee;

        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id, Personal_Guarantee__c = personalGuarantee.Id);
        insert onboarding;

        personalGuarantee.Status__c = 'Complete';
        update personalGuarantee;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Personal_Guarantee__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Personal Guarantee trigger should have created one status change record.');
    }

    @IsTest
    static void testOnboardingStatusTrigger() {
        // Self-tracking: lookup field is 'Id'
        injectConfigs(new List<Onboarding_Status_Tracking_Config__mdt>{
            makeCfg('Onboarding__c', 'Onboarding_Status__c', 'Id')
        });

        Account account = new Account(Name = 'Test Account');
        insert account;

        Onboarding__c onboarding = new Onboarding__c(
            Account__c = account.Id,
            Onboarding_Status__c = 'New'
        );
        insert onboarding;

        onboarding.Onboarding_Status__c = 'Expired';
        update onboarding;

        List<Onboarding_Status_Change__c> statusChanges = [
            SELECT Id FROM Onboarding_Status_Change__c
            WHERE Source_Object__c = :getLabel('Onboarding__c')
        ];
        System.assertEquals(1, statusChanges.size(), 'Onboarding trigger should have created one status change record.');
    }
    
}