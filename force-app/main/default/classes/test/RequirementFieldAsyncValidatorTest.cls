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

    @isTest
    static void testAndExpression() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'value1',
            'Field2__c' => 'value2',
            'Field3__c' => 'value3'
        };

        // Both conditions true
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "value1" AND Field2__c == "value2"', values);
        System.assertEquals(true, result1, 'AND expression should pass when both conditions are true');

        // One condition false
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "value1" AND Field2__c == "wrong"', values);
        System.assertEquals(false, result2, 'AND expression should fail when one condition is false');
    }

    @isTest
    static void testOrExpression() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'value1',
            'Field2__c' => 'value2'
        };

        // One condition true
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "value1" OR Field2__c == "wrong"', values);
        System.assertEquals(true, result1, 'OR expression should pass when one condition is true');

        // Both conditions false
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "wrong" OR Field2__c == "wrong"', values);
        System.assertEquals(false, result2, 'OR expression should fail when both conditions are false');
    }

    @isTest
    static void testNestedParentheses() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'value1',
            'Field2__c' => 'value2',
            'Field3__c' => 'value3'
        };

        // Nested parentheses: (Field1 == Field2) OR (Field3 == "value3")
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('(Field1__c == Field2__c) OR (Field3__c == "value3")', values);
        System.assertEquals(true, result1, 'Nested parentheses should evaluate correctly');

        // Complex nested: ((Field1 == "value1") AND (Field2 == "value2")) OR (Field3 == "wrong")
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('((Field1__c == "value1") AND (Field2__c == "value2")) OR (Field3__c == "wrong")', values);
        System.assertEquals(true, result2, 'Complex nested expressions should evaluate correctly');
    }

    @isTest
    static void testIsBlankFunctions() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => '',
            'Field2__c' => 'value2',
            'Field3__c' => null
        };

        // ISBLANK with blank field
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('ISBLANK(Field1__c)', values);
        System.assertEquals(true, result1, 'ISBLANK should return true for blank field');

        // ISNOTBLANK with non-blank field
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('ISNOTBLANK(Field2__c)', values);
        System.assertEquals(true, result2, 'ISNOTBLANK should return true for non-blank field');

        // Combined with AND
        Boolean result3 = RequirementFieldAsyncValidator.evaluateCrossField('ISBLANK(Field1__c) AND ISNOTBLANK(Field2__c)', values);
        System.assertEquals(true, result3, 'ISBLANK/ISNOTBLANK should work with AND');
    }

    @isTest
    static void testInequalityOperator() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'value1',
            'Field2__c' => 'value2'
        };

        // Inequality true
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c != Field2__c', values);
        System.assertEquals(true, result1, 'Inequality should return true when values differ');

        // Inequality false
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c != "value1"', values);
        System.assertEquals(false, result2, 'Inequality should return false when values are equal');
    }

    @isTest
    static void testComplexExpression() {
        Map<String, String> values = new Map<String, String>{
            'Email__c' => 'test@example.com',
            'ConfirmEmail__c' => 'test@example.com',
            'Phone__c' => '1234567890',
            'Country__c' => 'US'
        };

        // Complex: (Email == ConfirmEmail) AND (ISNOTBLANK(Phone) OR Country == "US")
        Boolean result = RequirementFieldAsyncValidator.evaluateCrossField(
            '(Email__c == ConfirmEmail__c) AND (ISNOTBLANK(Phone__c) OR Country__c == "US")',
            values
        );
        System.assertEquals(true, result, 'Complex expression should evaluate correctly');
    }

    @isTest
    static void testLiteralValues() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'test'
        };

        // Literal comparison
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "test"', values);
        System.assertEquals(true, result1, 'Literal comparison should work');

        // Literal with single quotes
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == \'test\'', values);
        System.assertEquals(true, result2, 'Single quote literals should work');
    }
}