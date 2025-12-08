@isTest
public class InstallationTPVTabControllerTest {
    private static Profile p = TestHelper.getGeneralProfile();
    private static User u = new User(
        Alias = 'standt',
        Email = 'standarduser@testorg.com',
        EmailEncodingKey = 'UTF-8',
        FirstName = 'Test',
        LastName = 'Testing',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'unittestinguser@testorg.com',
        POE_FraudObservation__c = false
    );

    @TestSetup
    static void makeData() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            POE_Clicker_Origin__c = 'phonesales',
            StageName = 'Contact',
            CloseDate = Date.today(),
            POE_TPV_Verified__c = false
        );
        insert opp;

        Account acc = new Account(Name = 'Test', POE_Require_TPV__c = true);
        insert acc;

        Contact con = new Contact(
            LastName = 'Test_Contact',
            AccountId = acc.Id,
            Email = 'testCommunityUsermig123@test.com',
            Title = 'Journalist',
            POE_Enable_Trial_Period__c = false
        );
        insert con;
    }

    @isTest
    static void getTPVSettings() {
        String oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        u.ContactId = con.Id;

        System.runAs(u) {
            Test.startTest();
            InstallationTPVTabController.ResponseWrapper response = InstallationTPVTabController.getTPVSettings(
                new Map<String, Object>{ 'ContextId' => oppId }
            );
            Test.stopTest();

            String tpvText = (String) response.result.get('TPVText');
            System.assertEquals('Yes', tpvText, 'The TPVText field of the result is not the expected value.');
        }
    }

    @isTest
    static void updateOrderTest() {
        Order ord = new Order(
            AccountId = [SELECT Id FROM Account LIMIT 1]
            .Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        Date baseDate = Date.today().addDays(1);
        String dateStr = baseDate.year() + '-' + baseDate.month() + '-' + baseDate.day();
        Test.startTest();
        InstallationTPVTabController.updateOrder(
            new Map<String, Object>{ 'id' => ord.Id, 'installationDate' => dateStr }
        );
        Test.stopTest();

        Order updatedOrd = [SELECT Id, POE_InstallationDate__c FROM Order WHERE Id = :ord.Id];
        Assert.areEqual(
            Date.valueOf(dateStr),
            updatedOrd.POE_InstallationDate__c,
            'The POE_InstallationDate__c field was not updated.'
        );
    }

    @isTest
    static void convertDatesTest() {
        Test.startTest();
        InstallationTPVTabController.ResponseWrapper response = InstallationTPVTabController.convertDatesTimeZone(
            new Map<String, Object>{
                'timeZone' => 'America/Chicago',
                'data' => '[{\"scheduleId\":8041221,\"date\":\"2024-05-14\",\"startTime\":\"18:00\",\"endTime\":\"22:00\",\"dayOfWeek\":\"Tue\",\"appointmentCode\":\"4\",\"day\":\"2024-05-14\"},{\"scheduleId\":7130361,\"date\":\"2024-05-15\",\"startTime\":\"13:00\",\"endTime\":\"17:00\",\"dayOfWeek\":\"Wed\",\"appointmentCode\":\"4\",\"day\":\"2024-05-15\"}]'
            }
        );
        Test.stopTest();

        System.assertEquals(false, response.result.get('slot') == null, 'Slots were not transformed');
    }

    @isTest
    static void getSelfInstallFlagTest() {
        // Create test account with Self_Install_Allowed__c set to true
        Account testAccount = new Account(Name = 'Test Self Install Account', Self_Install_Allowed__c = true);
        insert testAccount;

        // Create test contact associated with the account
        Contact testContact = new Contact(
            LastName = 'Test Self Install Contact',
            AccountId = testAccount.Id,
            Email = 'testselfinstall@testorg.com'
        );
        insert testContact;

        // Create test user associated with the contact
        User testUser = new User(
            Alias = 'test',
            Email = 'testselfinstall@testorg.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'SelfInstall',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testselfinstall@testorg.com',
            ContactId = testContact.Id
        );
        insert testUser;

        Test.startTest();
        System.runAs(testUser) {
            Boolean result = InstallationTPVTabController.getSelfInstallFlag();
            System.assertEquals(
                true,
                result,
                'getSelfInstallFlag should return true when Self_Install_Allowed__c is true'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void getSelfInstallFlagFalseTest() {
        // Create test account with Self_Install_Allowed__c set to false
        Account testAccount = new Account(Name = 'Test No Self Install Account', Self_Install_Allowed__c = false);
        insert testAccount;

        // Create test contact associated with the account
        Contact testContact = new Contact(
            LastName = 'Test No Self Install Contact',
            AccountId = testAccount.Id,
            Email = 'testnoselfinstall@testorg.com'
        );
        insert testContact;

        // Create test user associated with the contact
        User testUser = new User(
            Alias = 'test2',
            Email = 'testnoselfinstall@testorg.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'NoSelfInstall',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testnoselfinstall@testorg.com',
            ContactId = testContact.Id
        );
        insert testUser;

        Test.startTest();
        System.runAs(testUser) {
            Boolean result = InstallationTPVTabController.getSelfInstallFlag();
            System.assertEquals(
                false,
                result,
                'getSelfInstallFlag should return false when Self_Install_Allowed__c is false'
            );
        }
        Test.stopTest();
    }
}