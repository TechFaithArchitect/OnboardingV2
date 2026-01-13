@isTest
private class OnboardingAppECCControllerTest {

    @isTest
    static void testGetRequiredCredentials() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType('Type A', 1, customization, true, true);
        Required_Credential__c rc = TestCredentialFactory.createRequiredCredential(type1, customization, true, true);
        
        // Act
        Test.startTest();
        List<Required_Credential__c> result = OnboardingAppECCController.getRequiredCredentials(customization.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return required credentials');
    }

    @isTest
    static void testGetAvailableCredentialTypes() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType('Type A', 1, customization, true, true);
        
        // Act
        Test.startTest();
        List<External_Contact_Credential_Type__c> result = OnboardingAppECCController.getAvailableCredentialTypes();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return credential types');
    }

    @isTest
    static void testCreateCredentialType() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        
        // Act
        Test.startTest();
        External_Contact_Credential_Type__c result = OnboardingAppECCController.createCredentialType(
            'Test Type', 10, customization.Id, true);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.Id, 'Should have an ID');
    }

    @isTest
    static void testLinkCredentialTypeToRequiredCredential() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType('Type A', 1, customization, true, true);
        Required_Credential__c rc = TestCredentialFactory.createRequiredCredential(type1, customization, true, true);
        
        // Act
        Test.startTest();
        OnboardingAppECCController.linkCredentialTypeToRequiredCredential(rc.Id, type1.Id);
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Link should complete successfully');
    }
}