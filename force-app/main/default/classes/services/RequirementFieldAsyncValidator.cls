/**
 * Async validator for Requirement_Field_Value__c records that require cross-field or external checks.
 * Current implementation marks pending records as Valid with a fresh timestamp; extend with real logic as needed.
 */
public with sharing class RequirementFieldAsyncValidator implements Queueable {
    private Set<Id> fieldValueIds;

    public RequirementFieldAsyncValidator(Set<Id> fieldValueIds) {
        this.fieldValueIds = fieldValueIds == null ? new Set<Id>() : fieldValueIds;
    }

    /**
     * Enqueue async validation for pending Requirement_Field_Value__c records.
     */
    public static void enqueue(Set<Id> fieldValueIds) {
        if (fieldValueIds == null || fieldValueIds.isEmpty()) {
            return;
        }
        System.enqueueJob(new RequirementFieldAsyncValidator(fieldValueIds));
    }

    public void execute(QueueableContext context) {
        if (fieldValueIds.isEmpty()) {
            return;
        }

        List<Requirement_Field_Value__c> valuesToUpdate = [
            SELECT Id, Value__c, Encrypted_Value__c, Validation_Status__c,
                   Validation_Error_Message__c, Requirement_Field__r.Required__c,
                   Requirement_Field__r.Field_API_Name__c, Requirement_Field__r.Validation_Type__c,
                   Requirement_Field__c, Onboarding_Requirement__c
            FROM Requirement_Field_Value__c
            WHERE Id IN :fieldValueIds
        ];

        // Load rules for the field API names we're validating
        Set<String> fieldApis = new Set<String>();
        Set<Id> requirementIds = new Set<Id>();
        for (Requirement_Field_Value__c fv : valuesToUpdate) {
            if (fv.Requirement_Field__r != null && String.isNotBlank(fv.Requirement_Field__r.Field_API_Name__c)) {
                fieldApis.add(fv.Requirement_Field__r.Field_API_Name__c);
            }
            if (fv.Onboarding_Requirement__c != null) {
                requirementIds.add(fv.Onboarding_Requirement__c);
            }
        }
        Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = RequirementFieldValidationService.loadRulesByFieldApi(fieldApis);

        // Gather sibling values for cross-field checks
        Map<Id, Map<String, String>> valuesByRequirement = new Map<Id, Map<String, String>>();
        if (!requirementIds.isEmpty()) {
            for (Requirement_Field_Value__c sibling : [
                SELECT Onboarding_Requirement__c, Requirement_Field__r.Field_API_Name__c,
                       Value__c, Encrypted_Value__c
                FROM Requirement_Field_Value__c
                WHERE Onboarding_Requirement__c IN :requirementIds
            ]) {
                if (sibling.Requirement_Field__r == null || String.isBlank(sibling.Requirement_Field__r.Field_API_Name__c)) continue;
                Map<String, String> mapByApi = valuesByRequirement.get(sibling.Onboarding_Requirement__c);
                if (mapByApi == null) {
                    mapByApi = new Map<String, String>();
                    valuesByRequirement.put(sibling.Onboarding_Requirement__c, mapByApi);
                }
                mapByApi.put(sibling.Requirement_Field__r.Field_API_Name__c, sibling.Encrypted_Value__c != null ? String.valueOf(sibling.Encrypted_Value__c) : sibling.Value__c);
            }
        }

        List<RequirementValidationLogger.LogEntry> logs = new List<RequirementValidationLogger.LogEntry>();
        for (Requirement_Field_Value__c fv : valuesToUpdate) {
            Boolean isBlank = String.isBlank(fv.Value__c) && String.isBlank(fv.Encrypted_Value__c);

            Requirement_Field_Validation_Rule__mdt rule = (fv.Requirement_Field__r != null)
                ? rulesByApi.get(fv.Requirement_Field__r.Field_API_Name__c)
                : null;

            if (fv.Requirement_Field__r != null && fv.Requirement_Field__r.Required__c && isBlank) {
                fv.Validation_Status__c = 'Needs_Correction';
                fv.Validation_Error_Message__c = 'This field is required.';
            } else if (rule != null && rule.Validation_Type__c == 'Cross-Field' && !String.isBlank(rule.Validation_Expression__c)) {
                fv.Validation_Status__c = evaluateCrossField(rule.Validation_Expression__c, valuesByRequirement.get(fv.Onboarding_Requirement__c))
                    ? 'Valid'
                    : 'Invalid';
                fv.Validation_Error_Message__c = fv.Validation_Status__c == 'Valid'
                    ? null
                    : (String.isNotBlank(rule.Error_Message__c) ? rule.Error_Message__c : 'Cross-field validation failed.');
            } else if (rule != null && rule.Validation_Type__c == 'External') {
                fv.Validation_Status__c = 'Pending';
                fv.Validation_Error_Message__c = 'Awaiting external validation.';
            } else {
                fv.Validation_Status__c = 'Valid';
                fv.Validation_Error_Message__c = null;
            }
            fv.Last_Validated_Date__c = DateTime.now();

            RequirementValidationLogger.LogEntry log = new RequirementValidationLogger.LogEntry();
            log.fieldValueId = fv.Id;
            log.fieldApiName = fv.Requirement_Field__r != null ? fv.Requirement_Field__r.Field_API_Name__c : null;
            log.validationResult = fv.Validation_Status__c;
            log.validationType = fv.Requirement_Field__r != null ? fv.Requirement_Field__r.Validation_Type__c : null;
            log.message = fv.Validation_Error_Message__c;
            log.correlationId = String.valueOf(Crypto.getRandomLong());
            log.validatedOn = fv.Last_Validated_Date__c;
            logs.add(log);
        }

        if (!valuesToUpdate.isEmpty()) {
            update valuesToUpdate;
        }

        if (!logs.isEmpty()) {
            RequirementValidationLogger.log(logs);
        }
    }

    @TestVisible
    private static Boolean evaluateCrossField(String expression, Map<String, String> valuesByApi) {
        if (String.isBlank(expression)) return true;
        if (valuesByApi == null) valuesByApi = new Map<String, String>();

        // Support simple equality/inequality checks: Field__c==OtherField__c or Field__c!='literal'
        if (expression.contains('==')) {
            List<String> parts = expression.split('==');
            if (parts.size() == 2) {
                String left = parts[0].trim();
                String right = parts[1].trim();
                String leftVal = valuesByApi.get(left);
                String rightVal = valuesByApi.containsKey(right) ? valuesByApi.get(right) : right.replace('\"', '');
                return stringEquals(leftVal, rightVal);
            }
        }
        if (expression.contains('!=')) {
            List<String> parts = expression.split('!=');
            if (parts.size() == 2) {
                String left = parts[0].trim();
                String right = parts[1].trim();
                String leftVal = valuesByApi.get(left);
                String rightVal = valuesByApi.containsKey(right) ? valuesByApi.get(right) : right.replace('\"', '');
                return !stringEquals(leftVal, rightVal);
            }
        }
        // Simple ISBLANK/ISNOTBLANK(Field__c)
        if (expression.startsWith('ISBLANK(') && expression.endsWith(')')) {
            String field = expression.substring(8, expression.length() - 1).trim();
            String val = valuesByApi.get(field);
            return String.isBlank(val);
        }
        if (expression.startsWith('ISNOTBLANK(') && expression.endsWith(')')) {
            String field = expression.substring(11, expression.length() - 1).trim();
            String val = valuesByApi.get(field);
            return !String.isBlank(val);
        }
        // If we cannot interpret the expression, fail-safe to Invalid
        return false;
    }

    private static Boolean stringEquals(String a, String b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        return a.equalsIgnoreCase(b);
    }
}
