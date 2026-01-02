/**
 * Service for external validation of Requirement_Field_Value__c records
 * Integrates with external systems (e.g., credit checks, license verification, etc.)
 * 
 * NOTE: This is a framework for external validation. Implement actual integrations as needed.
 */
public with sharing class RequirementFieldExternalValidator {

    /**
     * Validate field values externally
     * This method should be called from RequirementFieldAsyncValidator for External validation types
     * 
     * @param fieldValueIds Set of Requirement_Field_Value__c IDs to validate externally
     */
    public static void validateExternally(Set<Id> fieldValueIds) {
        if (fieldValueIds == null || fieldValueIds.isEmpty()) {
            return;
        }

        // Get field values with their validation rules
        List<Requirement_Field_Value__c> fieldValues = RequirementFieldValueRepository.getFieldValuesByIds(fieldValueIds);
        
        // Group by validation rule to batch similar validations
        Map<String, List<Requirement_Field_Value__c>> valuesByRule = new Map<String, List<Requirement_Field_Value__c>>();
        Set<String> fieldApiNames = new Set<String>();
        
        for (Requirement_Field_Value__c fv : fieldValues) {
            if (fv.Requirement_Field__r != null && String.isNotBlank(fv.Requirement_Field__r.Field_API_Name__c)) {
                fieldApiNames.add(fv.Requirement_Field__r.Field_API_Name__c);
            }
        }

        // Load validation rules
        Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = RequirementFieldValidationService.loadRulesByFieldApi(fieldApiNames);

        // Group field values by their validation rule
        for (Requirement_Field_Value__c fv : fieldValues) {
            if (fv.Requirement_Field__r == null || String.isBlank(fv.Requirement_Field__r.Field_API_Name__c)) {
                continue;
            }
            
            Requirement_Field_Validation_Rule__mdt rule = rulesByApi.get(fv.Requirement_Field__r.Field_API_Name__c);
            Boolean isExternal = rule != null
                ? isExternalValidation(rule.Validation_Type__c)
                : isExternalValidation(fv.Requirement_Field__r.Validation_Type__c);
            if (!isExternal) {
                continue;
            }

            String ruleKey = (rule != null && rule.DeveloperName != null) ? rule.DeveloperName : 'default';
            if (!valuesByRule.containsKey(ruleKey)) {
                valuesByRule.put(ruleKey, new List<Requirement_Field_Value__c>());
            }
            valuesByRule.get(ruleKey).add(fv);
        }

        // Process each rule group
        List<Requirement_Field_Value__c> valuesToUpdate = new List<Requirement_Field_Value__c>();
        List<RequirementValidationLogger.LogEntry> logs = new List<RequirementValidationLogger.LogEntry>();

        for (String ruleKey : valuesByRule.keySet()) {
            List<Requirement_Field_Value__c> ruleValues = valuesByRule.get(ruleKey);
            
            // Call appropriate external validation based on rule configuration
            for (Requirement_Field_Value__c fv : ruleValues) {
                // Get the rule for this specific field
                Requirement_Field_Validation_Rule__mdt rule = null;
                if (fv.Requirement_Field__r != null && String.isNotBlank(fv.Requirement_Field__r.Field_API_Name__c)) {
                    rule = rulesByApi.get(fv.Requirement_Field__r.Field_API_Name__c);
                }
                
                ExternalValidationResult result = performExternalValidation(fv, rule);
                
                // Update field value based on result
                fv.Validation_Status__c = result.isValid ? 'Valid' : 'Invalid';
                fv.Validation_Error_Message__c = result.errorMessage;
                fv.Last_Validated_Date__c = DateTime.now();
                valuesToUpdate.add(fv);

                // Log the validation
                RequirementValidationLogger.LogEntry log = new RequirementValidationLogger.LogEntry();
                log.fieldValueId = fv.Id;
                log.fieldApiName = fv.Requirement_Field__r != null ? fv.Requirement_Field__r.Field_API_Name__c : null;
                log.validationResult = fv.Validation_Status__c;
                log.validationType = 'External';
                log.message = result.errorMessage;
                log.correlationId = result.correlationId;
                log.validatedOn = fv.Last_Validated_Date__c;
                logs.add(log);
            }
        }

        // Update field values
        if (!valuesToUpdate.isEmpty()) {
            update valuesToUpdate;
        }

        // Log validation results
        if (!logs.isEmpty()) {
            RequirementValidationLogger.log(logs);
        }
    }

    private static Boolean isExternalValidation(String validationType) {
        return String.isNotBlank(validationType) && validationType.toLowerCase().startsWith('external');
    }

    /**
     * Perform external validation for a single field value
     * This method should be extended to integrate with actual external systems
     * 
     * @param fieldValue Requirement_Field_Value__c to validate
     * @param rule Validation rule metadata
     * @return ExternalValidationResult
     */
    @TestVisible
    private static ExternalValidationResult performExternalValidation(
        Requirement_Field_Value__c fieldValue,
        Requirement_Field_Validation_Rule__mdt rule
    ) {
        ExternalValidationResult result = new ExternalValidationResult();
        result.correlationId = String.valueOf(Crypto.getRandomLong());

        // TODO: Implement actual external validation based on rule configuration
        // Examples:
        // - Credit check API
        // - License verification service
        // - Tax ID validation
        // - Business registration lookup
        // - Address verification
        
        // For now, implement placeholder logic based on rule metadata
        String fieldApiName = fieldValue.Requirement_Field__r != null 
            ? fieldValue.Requirement_Field__r.Field_API_Name__c 
            : null;
        
        String value = String.isNotBlank(fieldValue.Encrypted_Value__c) 
            ? String.valueOf(fieldValue.Encrypted_Value__c) 
            : fieldValue.Value__c;

        // Placeholder: Check if value is not blank (basic validation)
        if (String.isBlank(value)) {
            result.isValid = false;
            result.errorMessage = 'External validation requires a value.';
            return result;
        }

        String externalService = (rule != null && String.isNotBlank(rule.External_Service__c))
            ? rule.External_Service__c
            : 'ExternalValidationAPI';
        String endpoint = 'callout:' + externalService + '/validate';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'fieldApiName' => fieldApiName,
            'value' => value,
            'ruleId' => rule != null ? rule.DeveloperName : null,
            'correlationId' => result.correlationId
        }));

        try {
            HttpResponse res = new Http().send(req);
            Integer statusCode = res.getStatusCode();
            if (statusCode >= 200 && statusCode < 300) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                Boolean isValidValue = response != null && response.get('isValid') != null
                    ? (Boolean)response.get('isValid')
                    : false;
                result.isValid = isValidValue;
                result.errorMessage = response != null ? (String)response.get('errorMessage') : 'External validation failed.';
            } else {
                result.isValid = false;
                result.errorMessage = 'External validation service unavailable.';
            }
        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'External validation error: ' + e.getMessage();
        }

        return result;
    }

    /**
     * Result class for external validation
     */
    public class ExternalValidationResult {
        public Boolean isValid;
        public String errorMessage;
        public String correlationId;
    }
}