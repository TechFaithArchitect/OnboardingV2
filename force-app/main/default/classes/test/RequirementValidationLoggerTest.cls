@isTest
private class RequirementValidationLoggerTest {
    @isTest
    static void logsEntries() {
        Requirement_Field__c reqField = new Requirement_Field__c(
            Name = 'Log Field',
            Field_API_Name__c = 'Log_Field__c',
            Validation_Type__c = 'Format'
        );
        insert reqField;

        Requirement_Field_Value__c fv = new Requirement_Field_Value__c(
            Requirement_Field__c = reqField.Id,
            Value__c = 'abc'
        );
        insert fv;

        RequirementValidationLogger.LogEntry entry = new RequirementValidationLogger.LogEntry();
        entry.fieldValueId = fv.Id;
        entry.fieldApiName = reqField.Field_API_Name__c;
        entry.validationResult = 'Invalid';
        entry.validationType = 'Format';
        entry.message = 'Test message';
        entry.ruleName = 'TestRule';
        entry.correlationId = 'corr-123';
        entry.validatedOn = Datetime.now();

        Test.startTest();
        RequirementValidationLogger.log(new List<RequirementValidationLogger.LogEntry>{ entry });
        Test.stopTest();

        Validation_Failure__c log = [
            SELECT Requirement_Field_Value__c, Requirement_Field__c, Validation_Result__c,
                   Validation_Type__c, Message__c, Rule_Name__c, Correlation_Id__c, Validated_On__c
            FROM Validation_Failure__c
            WHERE Requirement_Field_Value__c = :fv.Id
            LIMIT 1
        ];

        System.assertEquals(fv.Id, log.Requirement_Field_Value__c);
        System.assertEquals('Log_Field__c', log.Requirement_Field__c);
        System.assertEquals('Invalid', log.Validation_Result__c);
        System.assertEquals('Format', log.Validation_Type__c);
        System.assertEquals('Test message', log.Message__c);
        System.assertEquals('TestRule', log.Rule_Name__c);
        System.assertEquals('corr-123', log.Correlation_Id__c);
        System.assertNotEquals(null, log.Validated_On__c);
    }
}
