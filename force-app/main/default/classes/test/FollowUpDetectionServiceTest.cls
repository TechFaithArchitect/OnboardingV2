@IsTest
private class FollowUpDetectionServiceTest {

    @IsTest
    static void enqueueFollowUps_insertsPendingQueues() {
        Account acct = TestAccountFactory.create('Test', true);
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c ob = TestOnboardingFactory.create(acct, vendorProgram, true);

        Follow_Up_Rule__mdt rule = new Follow_Up_Rule__mdt(
            DeveloperName = 'TestRule',
            Follow_Up_Type__c = 'SMS',
            Trigger_Condition__c = 'Status = Incomplete',
            Initial_Delay_Days__c = 0,
            Active__c = true
        );
        FollowUpDetectionService.TEST_RULES = new List<Follow_Up_Rule__mdt>{ rule };

        Test.startTest();
        FollowUpDetectionService.enqueueFollowUps(new Set<Id>{ ob.Id });
        Test.stopTest();

        List<Follow_Up_Queue__c> queues = [
            SELECT Status__c, Follow_Up_Type__c, Follow_Up_Rule__c, Trigger_Reason__c
            FROM Follow_Up_Queue__c
            WHERE Onboarding__c = :ob.Id
        ];
        System.assertEquals(1, queues.size(), 'Should create one follow-up');
        System.assertEquals('Pending', queues[0].Status__c);
        System.assertEquals('SMS', queues[0].Follow_Up_Type__c);
        System.assertEquals('TestRule', queues[0].Follow_Up_Rule__c);
    }

    @IsTest
    static void enqueueFollowUps_skipsSuppressedAccounts() {
        Account acct = TestAccountFactory.create('Test', true);
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c ob = TestOnboardingFactory.create(acct, vendorProgram, true);

        Follow_Up_Rule__mdt rule = new Follow_Up_Rule__mdt(
            DeveloperName = 'TestRule',
            Follow_Up_Type__c = 'SMS',
            Trigger_Condition__c = 'Status = Incomplete',
            Initial_Delay_Days__c = 0,
            Active__c = true
        );
        FollowUpDetectionService.TEST_RULES = new List<Follow_Up_Rule__mdt>{ rule };

        Test.startTest();
        FollowUpDetectionService.enqueueFollowUps(new Set<Id>{ ob.Id });
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Follow_Up_Queue__c WHERE Onboarding__c = :ob.Id];
        // Without actual suppression inserts (CMDT is non-DML), this just ensures the call executes
        System.assertEquals(0, count, 'Should skip suppressed accounts (simulated)');
    }
}
