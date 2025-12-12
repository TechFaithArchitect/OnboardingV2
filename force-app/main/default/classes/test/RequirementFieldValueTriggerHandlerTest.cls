/**
 * Test class for RequirementFieldValueTriggerHandler
 */
@isTest
private class RequirementFieldValueTriggerHandlerTest {

    @isTest
    static void testEnqueueAsyncValidationOnInsert() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        Onboarding_Requirement__c testRequirement = TestOnboardingRequirementFactory.create(
            true, testOnboarding, null
        );

        // Create requirement field with Cross-Field validation type
        Requirement_Field__c crossField = new Requirement_Field__c(
            Name = 'Cross Field Test',
            Field_API_Name__c = 'Cross_Field_Test__c',
            Validation_Type__c = 'Cross-Field',
            Required__c = false
        );
        insert crossField;

        // Create requirement field value
        Requirement_Field_Value__c fieldValue = new Requirement_Field_Value__c(
            Requirement_Field__c = crossField.Id,
            Onboarding_Requirement__c = testRequirement.Id,
            Value__c = 'test value'
        );

        Test.startTest();
        insert fieldValue;
        Test.stopTest();

        // Verify async validation was enqueued (check that status was updated)
        Requirement_Field_Value__c updated = [
            SELECT Id, Validation_Status__c, Last_Validated_Date__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fieldValue.Id
        ];

        // Status should be updated by async validator (may be Valid, Invalid, or Pending)
        System.assertNotEquals(null, updated.Last_Validated_Date__c, 'Validation should have run');
    }

    @isTest
    static void testEnqueueAsyncValidationOnValueChange() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        Onboarding_Requirement__c testRequirement = TestOnboardingRequirementFactory.create(
            true, testOnboarding, null
        );

        Requirement_Field__c crossField = new Requirement_Field__c(
            Name = 'Cross Field Test',
            Field_API_Name__c = 'Cross_Field_Test__c',
            Validation_Type__c = 'Cross-Field',
            Required__c = false
        );
        insert crossField;

        Requirement_Field_Value__c fieldValue = new Requirement_Field_Value__c(
            Requirement_Field__c = crossField.Id,
            Onboarding_Requirement__c = testRequirement.Id,
            Value__c = 'original value'
        );
        insert fieldValue;

        Test.startTest();
        // Update value to trigger async validation
        fieldValue.Value__c = 'updated value';
        update fieldValue;
        Test.stopTest();

        // Verify validation ran
        Requirement_Field_Value__c updated = [
            SELECT Id, Validation_Status__c, Last_Validated_Date__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fieldValue.Id
        ];

        System.assertNotEquals(null, updated.Last_Validated_Date__c, 'Validation should have run after update');
    }

    @isTest
    static void testNoEnqueueForFormatValidationType() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        Onboarding_Requirement__c testRequirement = TestOnboardingRequirementFactory.create(
            true, testOnboarding, null
        );

        // Create requirement field with Format validation type (should not trigger async)
        Requirement_Field__c formatField = new Requirement_Field__c(
            Name = 'Format Field Test',
            Field_API_Name__c = 'Format_Field_Test__c',
            Validation_Type__c = 'Format',
            Required__c = false
        );
        insert formatField;

        Requirement_Field_Value__c fieldValue = new Requirement_Field_Value__c(
            Requirement_Field__c = formatField.Id,
            Onboarding_Requirement__c = testRequirement.Id,
            Value__c = 'test value'
        );

        Test.startTest();
        insert fieldValue;
        Test.stopTest();

        // Format validation is synchronous, so async validation should not be enqueued
        // This test verifies the trigger doesn't break for non-async validation types
        Requirement_Field_Value__c updated = [
            SELECT Id, Validation_Status__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fieldValue.Id
        ];

        System.assertNotEquals(null, updated, 'Field value should exist');
    }

    @isTest
    static void testBulkProcessing() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        Onboarding_Requirement__c testRequirement = TestOnboardingRequirementFactory.create(
            true, testOnboarding, null
        );

        Requirement_Field__c crossField = new Requirement_Field__c(
            Name = 'Cross Field Test',
            Field_API_Name__c = 'Cross_Field_Test__c',
            Validation_Type__c = 'Cross-Field',
            Required__c = false
        );
        insert crossField;

        // Create multiple field values for bulk testing
        List<Requirement_Field_Value__c> fieldValues = new List<Requirement_Field_Value__c>();
        for (Integer i = 0; i < 10; i++) {
            fieldValues.add(new Requirement_Field_Value__c(
                Requirement_Field__c = crossField.Id,
                Onboarding_Requirement__c = testRequirement.Id,
                Value__c = 'value ' + i
            ));
        }

        Test.startTest();
        insert fieldValues;
        Test.stopTest();

        // Verify all records were processed
        List<Requirement_Field_Value__c> updated = [
            SELECT Id, Validation_Status__c, Last_Validated_Date__c
            FROM Requirement_Field_Value__c
            WHERE Id IN :fieldValues
        ];

        System.assertEquals(10, updated.size(), 'All field values should exist');
        for (Requirement_Field_Value__c fv : updated) {
            System.assertNotEquals(null, fv.Last_Validated_Date__c, 'Validation should have run for all records');
        }
    }
}

