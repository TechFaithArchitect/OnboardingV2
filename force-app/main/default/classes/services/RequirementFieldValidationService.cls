/**
 * Validates Requirement_Field_Value__c records using metadata-driven rules.
 * - Required check uses Requirement_Field__c.Required__c.
 * - Format check uses Requirement_Field_Validation_Rule__mdt matched by Field_API_Name__c.
 * - Updates validation status, error message, and last validated timestamp when asked to persist.
 */
public with sharing class RequirementFieldValidationService {

    public class ValidationResult {
        @AuraEnabled public Id fieldValueId;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }

    /**
     * Validate and persist Requirement_Field_Value__c records by Id.
     * Useful for synchronous validation flows.
     */
    public static List<ValidationResult> validateAndUpdate(Set<Id> fieldValueIds) {
        if (fieldValueIds == null || fieldValueIds.isEmpty()) {
            return new List<ValidationResult>();
        }

        // Use repository for data access
        List<Requirement_Field_Value__c> fieldValues = RequirementFieldValueRepository.getFieldValuesByIds(fieldValueIds);

        Map<Id, Requirement_Field__c> requirementFieldsById = new Map<Id, Requirement_Field__c>();
        Set<String> fieldApiNames = new Set<String>();
        for (Requirement_Field_Value__c fv : fieldValues) {
            if (fv.Requirement_Field__c != null && fv.Requirement_Field__r != null) {
                requirementFieldsById.put(fv.Requirement_Field__c, fv.Requirement_Field__r);
                if (String.isNotBlank(fv.Requirement_Field__r.Field_API_Name__c)) {
                    fieldApiNames.add(fv.Requirement_Field__r.Field_API_Name__c);
                }
            }
        }

        Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = loadRulesByFieldApi(fieldApiNames);

        List<ValidationResult> results = new List<ValidationResult>();
        List<RequirementValidationLogger.LogEntry> logs = new List<RequirementValidationLogger.LogEntry>();
        for (Requirement_Field_Value__c fv : fieldValues) {
            Requirement_Field__c reqField = requirementFieldsById.get(fv.Requirement_Field__c);
            ValidationResult result = evaluateFieldValue(fv, reqField, rulesByApi);
            fv.Validation_Status__c = result.status;
            fv.Validation_Error_Message__c = result.message;
            fv.Last_Validated_Date__c = DateTime.now();
            results.add(result);

            // Log non-Valid outcomes
            if (result.status != null && result.status != 'Valid') {
                RequirementValidationLogger.LogEntry log = new RequirementValidationLogger.LogEntry();
                log.fieldValueId = fv.Id;
                log.fieldApiName = reqField != null ? reqField.Field_API_Name__c : null;
                log.validationResult = result.status;
                log.validationType = reqField != null ? reqField.Validation_Type__c : null;
                log.message = result.message;
                log.ruleName = (rulesByApi != null && reqField != null)
                    ? rulesByApi.get(reqField.Field_API_Name__c) != null
                        ? rulesByApi.get(reqField.Field_API_Name__c).DeveloperName
                        : null
                    : null;
                log.correlationId = String.valueOf(Crypto.getRandomLong());
                log.validatedOn = fv.Last_Validated_Date__c;
                logs.add(log);
            }
        }

        if (!fieldValues.isEmpty()) {
            update fieldValues;
        }

        if (!logs.isEmpty()) {
            RequirementValidationLogger.log(logs);
        }

        return results;
    }

    /**
     * Pure evaluation helper: no DML. Useful for LWC/Flow preview or tests.
     */
    public static ValidationResult evaluateFieldValue(
        Requirement_Field_Value__c fieldValue,
        Requirement_Field__c requirementField,
        Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi
    ) {
        ValidationResult result = new ValidationResult();
        result.fieldValueId = fieldValue != null ? fieldValue.Id : null;
        result.status = 'Valid';
        result.message = '';

        if (requirementField == null) {
            result.status = 'Invalid';
            result.message = 'Missing requirement field definition.';
            return result;
        }

        String fieldApi = requirementField.Field_API_Name__c;
        result.fieldApiName = fieldApi;
        String value = getValue(fieldValue);
        Boolean isBlank = String.isBlank(value);

        if (requirementField.Required__c && isBlank) {
            result.status = 'Needs_Correction';
            result.message = 'This field is required.';
            return result;
        }

        Requirement_Field_Validation_Rule__mdt rule = rulesByApi != null ? rulesByApi.get(fieldApi) : null;
        String validationType = requirementField.Validation_Type__c;

        if (rule != null && rule.Is_Active__c && rule.Validation_Type__c == 'Format' &&
            !String.isBlank(rule.Validation_Expression__c) && !isBlank) {
            try {
                if (!Pattern.compile(rule.Validation_Expression__c).matcher(value).matches()) {
                    result.status = 'Invalid';
                    result.message = String.isBlank(rule.Error_Message__c)
                        ? 'Value does not match required format.'
                        : rule.Error_Message__c;
                    return result;
                }
            } catch (Exception ex) {
                result.status = 'Invalid';
                result.message = 'Invalid validation expression: ' + ex.getMessage();
                return result;
            }
        }

        // If the field calls for cross-field or external validation, leave as Pending for downstream async validation.
        if (validationType == 'Cross-Field' || validationType == 'External') {
            result.status = 'Pending';
            return result;
        }

        result.status = 'Valid';
        return result;
    }

    /**
     * Convenience evaluation by Requirement Field API name and value (no DML).
     */
    @AuraEnabled(cacheable=false)
    public static ValidationResult evaluateSingle(String requirementFieldApiName, String value) {
        ValidationResult result = new ValidationResult();
        if (String.isBlank(requirementFieldApiName)) {
            result.status = 'Invalid';
            result.message = 'Requirement field API name is required.';
            return result;
        }

        List<Requirement_Field__c> fields = [
            SELECT Id, Field_API_Name__c, Required__c, Validation_Type__c
            FROM Requirement_Field__c
            WHERE Field_API_Name__c = :requirementFieldApiName
            LIMIT 1
        ];
        if (fields.isEmpty()) {
            result.status = 'Invalid';
            result.message = 'Requirement field not found for API name ' + requirementFieldApiName;
            return result;
        }

        Requirement_Field__c reqField = fields[0];
        Requirement_Field_Value__c fv = new Requirement_Field_Value__c();
        fv.Requirement_Field__c = reqField.Id;
        fv.Value__c = value;

        Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi =
            loadRulesByFieldApi(new Set<String>{ requirementFieldApiName });

        return evaluateFieldValue(fv, reqField, rulesByApi);
    }

    public static Map<String, Requirement_Field_Validation_Rule__mdt> loadRulesByFieldApi(Set<String> fieldApiNames) {
        Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = new Map<String, Requirement_Field_Validation_Rule__mdt>();
        if (fieldApiNames == null || fieldApiNames.isEmpty()) {
            return rulesByApi;
        }

        for (Requirement_Field_Validation_Rule__mdt rule : [
            SELECT DeveloperName, Requirement_Field__c, Validation_Type__c,
                   Validation_Expression__c, Error_Message__c, Is_Active__c
            FROM Requirement_Field_Validation_Rule__mdt
            WHERE Requirement_Field__c IN :fieldApiNames
            AND Is_Active__c = true
        ]) {
            rulesByApi.put(rule.Requirement_Field__c, rule);
        }
        return rulesByApi;
    }

    private static String getValue(Requirement_Field_Value__c fv) {
        if (fv == null) {
            return null;
        }
        if (fv.Encrypted_Value__c != null) {
            return String.valueOf(fv.Encrypted_Value__c);
        }
        return fv.Value__c;
    }
}