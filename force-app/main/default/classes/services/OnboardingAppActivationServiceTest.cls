@isTest
public class OnboardingAppActivationServiceTest {
    
    @isTest
    static void testActivateRecord_noSiblings() {
        TestDataFactoryWrapper.VendorCustomizationWrapper vendorCustomizationWrapper = TestDataFactory.createDraftVendorCustomizationWrapper(true);
        Vendor_Customization__c vendorCustomization = vendorCustomizationWrapper.customization;
        Vendor__c vendor = vendorCustomizationWrapper.vendor;

        Test.startTest();
        OnboardingAppActivationService.activateRecord('Vendor_Customization__c', vendorCustomization.Id);
        Test.stopTest();

        Vendor_Customization__c updatedVendorCustomization = [SELECT Status__c, Active__c FROM Vendor_Customization__c WHERE Id = :vendorCustomization.Id];
        System.assertEquals('Active', updatedVendorCustomization.Status__c);
        System.assertEquals(true, updatedVendorCustomization.Active__c);
    }

    @isTest
    static void testActivateRecord_withSiblings() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c rootCustomization = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, null, true);
        Vendor_Customization__c activeSibling = TestDataFactory.createVendorCustomization(vendor, 'Active', true, rootCustomization.Id, true);
        Vendor_Customization__c draftRecord = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, rootCustomization.Id, true);

        Test.startTest();
        OnboardingAppActivationService.activateRecord('Vendor_Customization__c', draftRecord.Id);
        Test.stopTest();

        Vendor_Customization__c updated = [SELECT Status__c, Active__c FROM Vendor_Customization__c WHERE Id = :draftRecord.Id];
        Vendor_Customization__c sibling = [SELECT Active__c FROM Vendor_Customization__c WHERE Id = :activeSibling.Id];

        System.assertEquals('Active', updated.Status__c);
        System.assertEquals(true, updated.Active__c);
        System.assertEquals(false, sibling.Active__c);
    }

    @isTest
    static void testActivateRecord_alreadyActive() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c record = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        Test.startTest();
        try {
            OnboardingAppActivationService.activateRecord('Vendor_Customization__c', record.Id);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testActivateRecord_statusRulesNotAllActive_shouldThrow() {
        // Arrange
        Onboarding_Status_Rules_Engine__c engine = new Onboarding_Status_Rules_Engine__c(
            Name = 'Test Engine',
            Active__c = false
        );
        insert engine;

        Onboarding_Status_Rule__c activeRule = new Onboarding_Status_Rule__c(
            Parent_Rule__c = engine.Id,
            Active__c = true,
            Rule_Number__c = 1
        );
        Onboarding_Status_Rule__c inactiveRule = new Onboarding_Status_Rule__c(
            Parent_Rule__c = engine.Id,
            Active__c = false,
            Rule_Number__c = 2
        );
        insert new List<Onboarding_Status_Rule__c>{ activeRule, inactiveRule };

        // Act + Assert
        Test.startTest();
        try {
            OnboardingAppActivationService.activateRecord('Onboarding_Status_Rules_Engine__c', engine.Id);
            System.assert(false, 'Expected AuraHandledException due to inactive rule.');
        } catch (AuraHandledException ex) {
            System.assertEquals(
                'Cannot activate Rules Engine unless all Status Rules are active.',
                ex.getMessage()
            );
        }
        Test.stopTest();
    }
}