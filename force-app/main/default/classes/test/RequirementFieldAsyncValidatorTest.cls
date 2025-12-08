@isTest
private class RequirementFieldAsyncValidatorTest {

    @isTest
    static void asyncValidatorMarksValidWhenNotRequired() {
        Requirement_Field__c reqField = new Requirement_Field__c(
            Name = 'Async Field',
            Field_API_Name__c = 'Async_Field__c',
            Validation_Type__c = 'External',
            Required__c = false
        );
        insert reqField;

        Requirement_Field_Value__c fv = new Requirement_Field_Value__c(
            Requirement_Field__c = reqField.Id,
            Value__c = 'abc'
        );
        insert fv;

        Test.startTest();
        RequirementFieldAsyncValidator.enqueue(new Set<Id>{ fv.Id });
        Test.stopTest();

        Requirement_Field_Value__c updated = [
            SELECT Validation_Status__c, Validation_Error_Message__c, Last_Validated_Date__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fv.Id
        ];

        System.assertEquals('Valid', updated.Validation_Status__c, 'Should mark as valid when not required');
        System.assertEquals(null, updated.Validation_Error_Message__c, 'No error expected');
        System.assertNotEquals(null, updated.Last_Validated_Date__c, 'Should stamp validation time');
    }

    @isTest
    static void asyncValidatorFlagsRequiredBlank() {
        Requirement_Field__c reqField = new Requirement_Field__c(
            Name = 'Async Required Field',
            Field_API_Name__c = 'Async_Required_Field__c',
            Validation_Type__c = 'Cross-Field',
            Required__c = true
        );
        insert reqField;

        Requirement_Field_Value__c fv = new Requirement_Field_Value__c(
            Requirement_Field__c = reqField.Id
        );
        insert fv;

        Test.startTest();
        RequirementFieldAsyncValidator.enqueue(new Set<Id>{ fv.Id });
        Test.stopTest();

        Requirement_Field_Value__c updated = [
            SELECT Validation_Status__c, Validation_Error_Message__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fv.Id
        ];

        System.assertEquals('Needs_Correction', updated.Validation_Status__c, 'Blank required field should need correction');
        System.assertEquals('This field is required.', updated.Validation_Error_Message__c);
    }

    @isTest
    static void crossFieldExpressionPassesEquality() {
        Requirement_Field__c left = new Requirement_Field__c(
            Name = 'Left',
            Field_API_Name__c = 'Left__c',
            Validation_Type__c = 'Cross-Field',
            Required__c = false
        );
        Requirement_Field__c right = new Requirement_Field__c(
            Name = 'Right',
            Field_API_Name__c = 'Right__c',
            Validation_Type__c = 'None',
            Required__c = false
        );
        insert new List<Requirement_Field__c>{ left, right };

        // Directly test the cross-field evaluator helper
        Map<String, String> values = new Map<String, String>{
            'Left__c' => 'X',
            'Right__c' => 'X'
        };
        Boolean passed = RequirementFieldAsyncValidator.evaluateCrossField('Left__c==Right__c', values);
        System.assertEquals(true, passed, 'Cross-field equality should validate');
    }
}
