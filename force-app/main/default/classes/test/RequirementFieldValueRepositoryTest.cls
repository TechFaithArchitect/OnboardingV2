/**
 * Test class for RequirementFieldValueRepository
 */
@isTest
private class RequirementFieldValueRepositoryTest {

    @testSetup
    static void setupTestData() {
        // Create test data using factory
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        // Create Requirement_Field_Group__c
        Requirement_Field_Group__c fieldGroup = new Requirement_Field_Group__c(
            Name = 'Test Group',
            Sequence__c = 1
        );
        insert fieldGroup;
        
        // Create Requirement_Field__c records
        Requirement_Field__c field1 = new Requirement_Field__c(
            Field_API_Name__c = 'Test_Field_1__c',
            Required__c = true,
            Validation_Type__c = 'Format',
            Requirement_Field_Group__c = fieldGroup.Id,
            Sequence__c = 1
        );
        
        Requirement_Field__c field2 = new Requirement_Field__c(
            Field_API_Name__c = 'Test_Field_2__c',
            Required__c = false,
            Validation_Type__c = 'Cross-Field',
            Requirement_Field_Group__c = fieldGroup.Id,
            Sequence__c = 2
        );
        
        insert new List<Requirement_Field__c>{ field1, field2 };
        
        // Create Requirement_Field_Value__c records
        Requirement_Field_Value__c value1 = new Requirement_Field_Value__c(
            Onboarding_Requirement__c = ctx.requirement.Id,
            Requirement_Field__c = field1.Id,
            Value__c = 'Valid Value',
            Validation_Status__c = 'Valid'
        );
        
        Requirement_Field_Value__c value2 = new Requirement_Field_Value__c(
            Onboarding_Requirement__c = ctx.requirement.Id,
            Requirement_Field__c = field2.Id,
            Value__c = 'Invalid Value',
            Validation_Status__c = 'Invalid',
            Validation_Error_Message__c = 'Test error'
        );
        
        Requirement_Field_Value__c value3 = new Requirement_Field_Value__c(
            Onboarding_Requirement__c = ctx.requirement.Id,
            Requirement_Field__c = field1.Id,
            Value__c = null,
            Validation_Status__c = 'Pending'
        );
        
        insert new List<Requirement_Field_Value__c>{ value1, value2, value3 };
    }

    @isTest
    static void testGetFieldValuesByIds() {
        List<Requirement_Field_Value__c> fieldValues = [
            SELECT Id FROM Requirement_Field_Value__c LIMIT 3
        ];
        
        Set<Id> fieldValueIds = new Set<Id>();
        for (Requirement_Field_Value__c fv : fieldValues) {
            fieldValueIds.add(fv.Id);
        }
        
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getFieldValuesByIds(fieldValueIds);
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should return 3 field values');
        for (Requirement_Field_Value__c fv : results) {
            System.assertNotEquals(null, fv.Requirement_Field__r, 'Should have Requirement_Field__r relationship');
        }
    }

    @isTest
    static void testGetFieldValuesByIds_EmptySet() {
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getFieldValuesByIds(new Set<Id>());
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for empty set');
    }

    @isTest
    static void testGetFieldValuesByIds_Null() {
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getFieldValuesByIds(null);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for null');
    }

    @isTest
    static void testGetFieldValuesByRequirement() {
        Onboarding_Requirement__c requirement = [
            SELECT Id FROM Onboarding_Requirement__c LIMIT 1
        ];
        
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getFieldValuesByRequirement(requirement.Id);
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should return 3 field values for requirement');
        // Verify ordering by sequence
        System.assert(results[0].Requirement_Field__r.Sequence__c <= results[1].Requirement_Field__r.Sequence__c, 'Should be ordered by sequence');
    }

    @isTest
    static void testGetFieldValuesByRequirement_Null() {
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getFieldValuesByRequirement(null);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for null');
    }

    @isTest
    static void testGetInvalidFieldValuesByOnboarding() {
        Onboarding__c onboarding = [
            SELECT Id FROM Onboarding__c LIMIT 1
        ];
        
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getInvalidFieldValuesByOnboarding(onboarding.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return 1 invalid field value');
        System.assertEquals('Invalid', results[0].Validation_Status__c, 'Should have Invalid status');
    }

    @isTest
    static void testGetInvalidFieldValuesByOnboarding_Null() {
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getInvalidFieldValuesByOnboarding(null);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for null');
    }

    @isTest
    static void testGetSiblingFieldValues() {
        List<Requirement_Field_Value__c> fieldValues = [
            SELECT Id FROM Requirement_Field_Value__c LIMIT 1
        ];
        
        if (fieldValues.isEmpty()) {
            return;
        }
        
        Test.startTest();
        Map<String, Requirement_Field_Value__c> siblings = RequirementFieldValueRepository.getSiblingFieldValues(fieldValues[0].Id);
        Test.stopTest();
        
        System.assertNotEquals(null, siblings, 'Siblings map should not be null');
        // Should have 2 siblings (3 total - 1 source = 2 siblings)
        System.assertEquals(2, siblings.size(), 'Should return 2 sibling field values');
    }

    @isTest
    static void testGetSiblingFieldValues_Null() {
        Test.startTest();
        Map<String, Requirement_Field_Value__c> siblings = RequirementFieldValueRepository.getSiblingFieldValues(null);
        Test.stopTest();
        
        System.assertEquals(0, siblings.size(), 'Should return empty map for null');
    }

    @isTest
    static void testGetSiblingFieldValues_InvalidId() {
        Test.startTest();
        Map<String, Requirement_Field_Value__c> siblings = RequirementFieldValueRepository.getSiblingFieldValues(UserInfo.getUserId()); // Invalid ID
        Test.stopTest();
        
        System.assertEquals(0, siblings.size(), 'Should return empty map for invalid ID');
    }

    @isTest
    static void testGetPendingFieldValues() {
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getPendingFieldValues(10);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        // Should have at least 1 pending value
        for (Requirement_Field_Value__c fv : results) {
            System.assertEquals('Pending', fv.Validation_Status__c, 'Should only return Pending status');
        }
    }

    @isTest
    static void testGetPendingFieldValues_DefaultLimit() {
        Test.startTest();
        List<Requirement_Field_Value__c> results = RequirementFieldValueRepository.getPendingFieldValues(null);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetInvalidFieldValueCount() {
        Onboarding__c onboarding = [
            SELECT Id FROM Onboarding__c LIMIT 1
        ];
        
        Test.startTest();
        Integer count = RequirementFieldValueRepository.getInvalidFieldValueCount(onboarding.Id);
        Test.stopTest();
        
        System.assertEquals(1, count, 'Should return count of 1 invalid field value');
    }

    @isTest
    static void testGetInvalidFieldValueCount_Null() {
        Test.startTest();
        Integer count = RequirementFieldValueRepository.getInvalidFieldValueCount(null);
        Test.stopTest();
        
        System.assertEquals(0, count, 'Should return 0 for null');
    }

    @isTest
    static void testGetInvalidFieldValueCount_NoInvalid() {
        // Create onboarding with no invalid values
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(testVendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        
        Test.startTest();
        Integer count = RequirementFieldValueRepository.getInvalidFieldValueCount(onboarding.Id);
        Test.stopTest();
        
        System.assertEquals(0, count, 'Should return 0 when no invalid values exist');
    }
}

