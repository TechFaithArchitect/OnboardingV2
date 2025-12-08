@isTest
private class OnboardingRepositoryTest {

    @isTest
    static void testUpdateOnboardings() {
        TestDataFactoryWrapper.AccountContactWrapper acctWrapper = TestDataFactory.createAccountContact(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c(
            Name = 'Test Agreement',
            echosign_dev1__Status__c = 'Signed'
        );
        insert agreement;
        
        Onboarding__c onboarding = TestDataFactory.createOnboarding(acctWrapper.account, customization, true);
        onboarding.Agreement__c = agreement.Id;
        update onboarding;

        onboarding.Onboarding_Status__c = 'In Process';

        Test.startTest();
        OnboardingRepository.updateOnboardings(new List<Onboarding__c>{ onboarding });
        Test.stopTest();

        // Assert
        Onboarding__c updated = [SELECT Id, Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals('In Process', updated.Onboarding_Status__c, 'Status should be updated');
    }

    @isTest
    static void testUpdateOnboardings_NullInput() {
        Test.startTest();
        OnboardingRepository.updateOnboardings(null); // Should not throw exception
        Test.stopTest();
        System.assert(true, 'Method should not fail with null input');
    }

    @isTest
    static void testUpdateOnboardings_EmptyInput() {
        Test.startTest();
        OnboardingRepository.updateOnboardings(new List<Onboarding__c>()); // Should not throw exception
        Test.stopTest();
        System.assert(true, 'Method should not fail with empty list');
    }
}