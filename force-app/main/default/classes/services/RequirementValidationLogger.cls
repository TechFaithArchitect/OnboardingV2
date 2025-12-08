/**
 * Centralized, minimal logging for validation outcomes.
 * Stores status and metadata only—no field values/PII.
 */
public with sharing class RequirementValidationLogger {

    public class LogEntry {
        public Id fieldValueId;
        public String fieldApiName;
        public String validationResult;
        public String validationType;
        public String message;
        public String ruleName;
        public String correlationId;
        public Datetime validatedOn;
    }

    public static void log(List<LogEntry> entries) {
        if (entries == null || entries.isEmpty()) {
            return;
        }
        List<Validation_Failure__c> records = new List<Validation_Failure__c>();
        for (LogEntry entry : entries) {
            if (entry == null || entry.fieldValueId == null) {
                continue;
            }
            Validation_Failure__c vf = new Validation_Failure__c();
            vf.Requirement_Field_Value__c = entry.fieldValueId;
            vf.Requirement_Field__c = entry.fieldApiName;
            vf.Validation_Result__c = entry.validationResult;
            vf.Validation_Type__c = entry.validationType;
            vf.Message__c = entry.message;
            vf.Rule_Name__c = entry.ruleName;
            vf.Correlation_Id__c = entry.correlationId;
            vf.Validated_On__c = entry.validatedOn != null ? entry.validatedOn : Datetime.now();
            records.add(vf);
        }
        if (!records.isEmpty()) {
            insert records;
        }
    }
}
