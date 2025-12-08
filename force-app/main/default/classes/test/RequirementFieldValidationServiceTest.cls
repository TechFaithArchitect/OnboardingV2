@isTest
private class RequirementFieldValidationServiceTest {

    @isTest
    static void requiredFieldBlankSetsNeedsCorrection() {
        Requirement_Field__c reqField = new Requirement_Field__c(
            Field_API_Name__c = 'Test_Field__c',
            Required__c = true,
            Validation_Type__c = 'None'
        );
        Requirement_Field_Value__c fieldValue = new Requirement_Field_Value__c(
            Requirement_Field__c = reqField.Id
        );

        RequirementFieldValidationService.ValidationResult result =
            RequirementFieldValidationService.evaluateFieldValue(fieldValue, reqField, new Map<String, Requirement_Field_Validation_Rule__mdt>());

        System.assertEquals('Needs_Correction', result.status, 'Required blank field should request correction');
        System.assertEquals('This field is required.', result.message, 'Should return required message');
    }

    @isTest
    static void formatValidationPassesAndFails() {
        Requirement_Field__c reqField = new Requirement_Field__c(
            Field_API_Name__c = 'Number_Field__c',
            Required__c = false,
            Validation_Type__c = 'Format'
        );

        Requirement_Field_Validation_Rule__mdt rule = new Requirement_Field_Validation_Rule__mdt(
            DeveloperName = 'Number_Field_Format',
            MasterLabel = 'Number Field Format',
            Requirement_Field__c = 'Number_Field__c',
            Validation_Type__c = 'Format',
            Validation_Expression__c = '^\\d+$',
            Error_Message__c = 'Numbers only',
            Is_Active__c = true
        );
        Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = new Map<String, Requirement_Field_Validation_Rule__mdt>{
            'Number_Field__c' => rule
        };

        Requirement_Field_Value__c validValue = new Requirement_Field_Value__c(
            Requirement_Field__c = reqField.Id,
            Value__c = '12345'
        );
        Requirement_Field_Value__c invalidValue = new Requirement_Field_Value__c(
            Requirement_Field__c = reqField.Id,
            Value__c = '12AB'
        );

        RequirementFieldValidationService.ValidationResult validResult =
            RequirementFieldValidationService.evaluateFieldValue(validValue, reqField, rulesByApi);
        RequirementFieldValidationService.ValidationResult invalidResult =
            RequirementFieldValidationService.evaluateFieldValue(invalidValue, reqField, rulesByApi);

        System.assertEquals('Valid', validResult.status, 'Digits should pass format validation');
        System.assertEquals('Invalid', invalidResult.status, 'Non-digits should fail format validation');
        System.assertEquals('Numbers only', invalidResult.message, 'Should surface rule error message');
    }

    @isTest
    static void crossFieldRemainsPending() {
        Requirement_Field__c reqField = new Requirement_Field__c(
            Field_API_Name__c = 'CrossField__c',
            Required__c = false,
            Validation_Type__c = 'Cross-Field'
        );
        Requirement_Field_Value__c fieldValue = new Requirement_Field_Value__c(
            Requirement_Field__c = reqField.Id,
            Value__c = 'anything'
        );

        RequirementFieldValidationService.ValidationResult result =
            RequirementFieldValidationService.evaluateFieldValue(fieldValue, reqField, new Map<String, Requirement_Field_Validation_Rule__mdt>());

        System.assertEquals('Pending', result.status, 'Cross-field validations should remain pending for async handling');
    }
}