@isTest
private class OnboardingAppECCServiceTest {

    @isTest
    static void testPassThroughMethods() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType('Type A', 1, customization, true, true);
        Required_Credential__c rc = TestCredentialFactory.createRequiredCredential(type1, customization, true, true);

        // Act - just call the service methods for coverage
        OnboardingAppECCService.getRequiredCredentials(customization.Id);
        OnboardingAppECCService.getAvailableCredentialTypes();
        OnboardingAppECCService.createCredentialType('Type B', 2, customization.Id, true);
        OnboardingAppECCService.linkCredentialTypeToRequiredCredential(rc.Id, type1.Id);
    }
}