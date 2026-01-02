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
            String normalizedResult = normalizeValidationResult(entry.validationResult);
            if (String.isNotBlank(normalizedResult)) {
                vf.Validation_Result__c = normalizedResult;
            }
            String normalizedType = normalizeValidationType(entry.validationType);
            if (String.isNotBlank(normalizedType)) {
                vf.Validation_Type__c = normalizedType;
            }
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

    private static String normalizeValidationType(String validationType) {
        if (String.isBlank(validationType)) {
            return null;
        }
        String lowered = validationType.toLowerCase();
        if (lowered.startsWith('external')) {
            return 'External';
        }
        if (lowered.contains('cross')) {
            return 'Cross-Field';
        }
        if (lowered == 'format') {
            return 'Format';
        }
        return 'Other';
    }

    private static String normalizeValidationResult(String validationResult) {
        if (String.isBlank(validationResult)) {
            return null;
        }
        String normalized = validationResult.replace('_', ' ').trim();
        if (normalized.equalsIgnoreCase('pending')) {
            return 'Pending';
        }
        if (normalized.equalsIgnoreCase('valid')) {
            return 'Valid';
        }
        if (normalized.equalsIgnoreCase('invalid')) {
            return 'Invalid';
        }
        if (normalized.equalsIgnoreCase('needs correction')) {
            return 'Needs Correction';
        }
        if (normalized.equalsIgnoreCase('failed')) {
            return 'Failed';
        }
        return null;
    }
}