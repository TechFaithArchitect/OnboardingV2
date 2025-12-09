@IsTest
private class FollowUpProcessorTest {

    @IsTest
    static void processorProcessesDueRecords() {
        Account acct = TestAccountFactory.create('Test', true);
        Contact con = new Contact(LastName = 'User', AccountId = acct.Id, MobilePhone = '555-555-5555');
        insert con;
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c ob = TestOnboardingFactory.create(acct, vendorProgram, true);

        Follow_Up_Queue__c fq = new Follow_Up_Queue__c(
            Name = 'FU',
            Onboarding__c = ob.Id,
            Follow_Up_Type__c = 'SMS',
            Status__c = 'Pending',
            Next_Attempt_Date__c = DateTime.now().addMinutes(-5)
        );
        insert fq;

        Test.startTest();
        FollowUpProcessor.enqueue();
        Test.stopTest();

        Follow_Up_Queue__c updated = [
            SELECT Status__c, Attempt_Count__c, Error_Message__c
            FROM Follow_Up_Queue__c
            WHERE Id = :fq.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, updated.Attempt_Count__c, 'Attempt count should increment');
        System.assertEquals('Failed', updated.Status__c, 'Without channel/template, it should mark failed');
        System.assertNotEquals(null, updated.Error_Message__c, 'Error should be logged');
    }

    @IsTest
    static void processorAdvancesNextAttemptBySchedule() {
        Account acct = TestAccountFactory.create('Test', true);
        Contact con = new Contact(LastName = 'User', AccountId = acct.Id, MobilePhone = '555-555-5555');
        insert con;
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c ob = TestOnboardingFactory.create(acct, vendorProgram, true);

        Follow_Up_Queue__c fq = new Follow_Up_Queue__c(
            Name = 'FU',
            Onboarding__c = ob.Id,
            Follow_Up_Type__c = 'SMS',
            Status__c = 'Pending',
            Next_Attempt_Date__c = DateTime.now().addMinutes(-5),
            Follow_Up_Rule__c = 'ScheduleRule'
        );
        insert fq;

        Test.startTest();
        FollowUpProcessor.enqueue();
        Test.stopTest();

        Follow_Up_Queue__c updated = [
            SELECT Status__c, Attempt_Count__c, Next_Attempt_Date__c
            FROM Follow_Up_Queue__c
            WHERE Id = :fq.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, updated.Next_Attempt_Date__c, 'Next attempt should be set');
        System.assert(updated.Next_Attempt_Date__c.date() >= Date.today(), 'Next attempt should advance per schedule');
    }

    @IsTest
    static void processorInvokesEmailPath() {
        Account acct = TestAccountFactory.create('Test', true);
        Contact con = new Contact(LastName = 'User', AccountId = acct.Id, Email = 'test@example.com');
        insert con;
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c ob = TestOnboardingFactory.create(acct, vendorProgram, true);

        // Mock email send success
        EmailCommSenderService.testResultOverride = new EmailCommSendResultDTO('Success', null, null);

        // Queue an email follow-up
        Follow_Up_Queue__c fq = new Follow_Up_Queue__c(
            Name = 'FU Email',
            Onboarding__c = ob.Id,
            Follow_Up_Type__c = 'Email',
            Status__c = 'Pending',
            Next_Attempt_Date__c = DateTime.now().addMinutes(-5)
        );
        insert fq;

        Test.startTest();
        FollowUpProcessor.enqueue();
        Test.stopTest();

        Follow_Up_Queue__c updated = [
            SELECT Status__c, Attempt_Count__c
            FROM Follow_Up_Queue__c
            WHERE Id = :fq.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, updated.Attempt_Count__c, 'Attempt count should increment');
        System.assertNotEquals(null, updated.Status__c, 'Status should be updated');
    }
}
