@isTest
private class RequirementFieldValidationActionTest {

    @isTest
    static void validatesAndReturnsStatuses() {
        Requirement_Field__c reqField = new Requirement_Field__c(
            Name = 'Action Field',
            Field_API_Name__c = 'Action_Field__c',
            Required__c = true,
            Validation_Type__c = 'None'
        );
        insert reqField;

        Requirement_Field_Value__c fv = new Requirement_Field_Value__c(
            Requirement_Field__c = reqField.Id
        );
        insert fv;

        RequirementFieldValidationAction.Request req = new RequirementFieldValidationAction.Request();
        req.requirementFieldValueId = fv.Id;

        Test.startTest();
        List<RequirementFieldValidationAction.Response> responses =
            RequirementFieldValidationAction.validate(new List<RequirementFieldValidationAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(fv.Id, responses[0].requirementFieldValueId);
        System.assertEquals('Needs_Correction', responses[0].status, 'Required blank should need correction');
        System.assertNotEquals(null, responses[0].message, 'Should have a validation message');
    }
}