@isTest
private class OnboardingBlockingDetectionServiceTest {

    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test vendor
        Vendor__c testVendor = new Vendor__c(Name = 'Test Vendor', Active__c = true);
        insert testVendor;

        // Create test vendor program
        Vendor_Customization__c testProgram = new Vendor_Customization__c(
            Vendor__c = testVendor.Id,
            Active__c = true,
            Status__c = 'Active'
        );
        insert testProgram;

        // Create test onboarding
        Onboarding__c ob = new Onboarding__c(
            Account__c = testAccount.Id,
            Vendor_Customization__c = testProgram.Id,
            Onboarding_Status__c = 'In Process'
        );
        insert ob;
    }

    @isTest
    static void testGetBlockedOnboardingIds() {
        List<Onboarding__c> onboardings = [SELECT Id FROM Onboarding__c LIMIT 1];
        
        if (onboardings.isEmpty()) {
            return;
        }
        
        List<Id> onboardingIds = new List<Id>{ onboardings[0].Id };
        
        Test.startTest();
        Set<Id> blockedIds = OnboardingBlockingDetectionService.getBlockedOnboardingIds(onboardingIds);
        Test.stopTest();
        
        System.assertNotEquals(null, blockedIds, 'Blocked IDs should not be null');
        // May be empty if no blocking conditions exist
    }

    @isTest
    static void testGetBlockingReasons() {
        List<Onboarding__c> onboardings = [SELECT Id FROM Onboarding__c LIMIT 1];
        
        if (onboardings.isEmpty()) {
            return;
        }
        
        Test.startTest();
        List<String> reasons = OnboardingBlockingDetectionService.getBlockingReasons(onboardings[0].Id);
        Test.stopTest();
        
        System.assertNotEquals(null, reasons, 'Reasons should not be null');
    }

    @isTest
    static void testIsAtRisk() {
        List<Onboarding__c> onboardings = [SELECT Id, CreatedDate FROM Onboarding__c LIMIT 1];
        
        if (onboardings.isEmpty()) {
            return;
        }
        
        Test.startTest();
        Boolean atRisk = OnboardingBlockingDetectionService.isAtRisk(onboardings[0].Id, 7);
        Test.stopTest();
        
        System.assertNotEquals(null, atRisk, 'At risk flag should not be null');
    }

    @isTest
    static void testIsAtRiskWithNullThreshold() {
        List<Onboarding__c> onboardings = [SELECT Id FROM Onboarding__c LIMIT 1];
        
        if (onboardings.isEmpty()) {
            return;
        }
        
        Test.startTest();
        Boolean atRisk = OnboardingBlockingDetectionService.isAtRisk(onboardings[0].Id, null);
        Test.stopTest();
        
        System.assertNotEquals(null, atRisk, 'At risk flag should not be null');
    }

    @isTest
    static void testGetBlockingInfoBulk() {
        List<Onboarding__c> onboardings = [SELECT Id FROM Onboarding__c];
        
        if (onboardings.isEmpty()) {
            return;
        }
        
        List<Id> onboardingIds = new List<Id>();
        for (Onboarding__c ob : onboardings) {
            onboardingIds.add(ob.Id);
        }
        
        Test.startTest();
        Map<Id, OnboardingBlockingDetectionService.BlockingInfo> blockingInfo = 
            OnboardingBlockingDetectionService.getBlockingInfoBulk(onboardingIds);
        Test.stopTest();
        
        System.assertNotEquals(null, blockingInfo, 'Blocking info should not be null');
        System.assertEquals(onboardingIds.size(), blockingInfo.size(), 'Should have info for all onboarding IDs');
    }

    @isTest
    static void testGetBlockedOnboardingIdsWithDeniedStatus() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Vendor_Customization__c testProgram = [SELECT Id FROM Vendor_Customization__c LIMIT 1];
        
        Onboarding__c deniedOb = new Onboarding__c(
            Account__c = testAccount.Id,
            Vendor_Customization__c = testProgram.Id,
            Onboarding_Status__c = 'Denied'
        );
        insert deniedOb;
        
        Test.startTest();
        Set<Id> blockedIds = OnboardingBlockingDetectionService.getBlockedOnboardingIds(
            new List<Id>{ deniedOb.Id }
        );
        Test.stopTest();
        
        System.assert(blockedIds.contains(deniedOb.Id), 'Should identify denied onboarding as blocked');
    }

    @isTest
    static void testGetBlockingReasonsWithNullId() {
        Test.startTest();
        List<String> reasons = OnboardingBlockingDetectionService.getBlockingReasons(null);
        Test.stopTest();
        
        System.assertNotEquals(null, reasons, 'Reasons should not be null');
        System.assertEquals(0, reasons.size(), 'Should return empty list for null ID');
    }

    @isTest
    static void testIsAtRiskWithNullId() {
        Test.startTest();
        Boolean atRisk = OnboardingBlockingDetectionService.isAtRisk(null, 7);
        Test.stopTest();
        
        System.assertEquals(false, atRisk, 'Should return false for null ID');
    }
}