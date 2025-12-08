/**
 * Controller for Validation Rule Builder
 * Handles creating/updating validation rules in Custom Metadata Type
 */
public with sharing class ValidationRuleBuilderController {

    /**
     * Get requirement fields for field reference picker
     * @return List of field metadata
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldMetadata> getRequirementFields() {
        List<FieldMetadata> fields = new List<FieldMetadata>();
        
        // Query Requirement_Field__c to get available fields
        // This provides the field picker for expression building
        try {
            List<Requirement_Field__c> reqFields = [
                SELECT Id, Name, Field_API_Name__c, Field_Type__c
                FROM Requirement_Field__c
                ORDER BY Sequence__c ASC NULLS LAST, Name ASC
                LIMIT 100
            ];
            
            for (Requirement_Field__c rf : reqFields) {
                FieldMetadata fm = new FieldMetadata();
                fm.id = rf.Id;
                fm.apiName = rf.Field_API_Name__c != null ? rf.Field_API_Name__c : 'Value__c';
                fm.label = rf.Name;
                fm.type = rf.Field_Type__c;
                fields.add(fm);
            }
        } catch (Exception e) {
            System.debug('Error loading requirement fields: ' + e.getMessage());
        }
        
        return fields;
    }

    /**
     * Validate expression syntax
     * @param expression Validation expression to validate
     * @param validationType Type of validation
     * @return ValidationResult with isValid flag and error message
     */
    @AuraEnabled
    public static ValidationResult validateExpression(String expression, String validationType) {
        ValidationResult result = new ValidationResult();
        
        if (String.isBlank(expression)) {
            result.isValid = false;
            result.errorMessage = 'Expression cannot be blank';
            return result;
        }
        
        try {
            // Basic syntax validation
            // Check for balanced parentheses
            Integer openParens = expression.countMatches('(');
            Integer closeParens = expression.countMatches(')');
            if (openParens != closeParens) {
                result.isValid = false;
                result.errorMessage = 'Unbalanced parentheses';
                return result;
            }
            
            // Check for balanced brackets
            Integer openBrackets = expression.countMatches('[');
            Integer closeBrackets = expression.countMatches(']');
            if (openBrackets != closeBrackets) {
                result.isValid = false;
                result.errorMessage = 'Unbalanced brackets';
                return result;
            }
            
            // Validate common function names
            List<String> validFunctions = new List<String>{
                'REGEX', 'ISBLANK', 'LEN', 'CONTAINS', 'NOT', 'AND', 'OR',
                'ISNULL', 'ISNOTNULL', 'BEGINS', 'ENDS', 'INCLUDES'
            };
            
            // Basic validation - check if expression contains valid patterns
            // More sophisticated validation would require expression parsing
            
            result.isValid = true;
            result.message = 'Expression syntax is valid';
            
        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'Validation error: ' + e.getMessage();
        }
        
        return result;
    }

    /**
     * Test a validation rule expression with test values
     * @param expression Validation expression
     * @param testValues Map of field values to test
     * @return ValidationTestResult
     */
    @AuraEnabled
    public static ValidationTestResult testRuleExpression(String expression, Map<String, Object> testValues) {
        ValidationTestResult result = new ValidationTestResult();
        
        if (String.isBlank(expression)) {
            result.isValid = false;
            result.errorMessage = 'Expression cannot be blank';
            return result;
        }
        
        try {
            // This is a simplified test - in production, you'd need a proper expression evaluator
            // For now, we'll do basic pattern matching
            
            // Extract field references from expression
            Pattern fieldPattern = Pattern.compile('([A-Za-z_][A-Za-z0-9_]*(?:__c)?)');
            Matcher matcher = fieldPattern.matcher(expression);
            Set<String> referencedFields = new Set<String>();
            while (matcher.find()) {
                String fieldName = matcher.group(1);
                if (fieldName.contains('__c') || fieldName.equals('Value') || fieldName.equals('EncryptedValue')) {
                    referencedFields.add(fieldName);
                }
            }
            
            // Check if all referenced fields have test values
            for (String field : referencedFields) {
                String testKey = field.replace('__c', '');
                if (!testValues.containsKey(testKey) && !testValues.containsKey(field)) {
                    result.isValid = false;
                    result.errorMessage = 'Missing test value for field: ' + field;
                    return result;
                }
            }
            
            // Basic validation - in production, use a proper expression evaluator
            // For now, just check if expression structure is valid
            result.isValid = true;
            result.message = 'Test passed (simplified validation - full evaluation requires expression parser)';
            
        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'Test error: ' + e.getMessage();
        }
        
        return result;
    }

    /**
     * Save validation rule to Custom Metadata Type
     * Uses Metadata API to create/update Custom Metadata records
     * @param ruleData Map containing rule data
     * @param recordId Existing rule DeveloperName (for updates)
     * @return SaveResult with rule ID
     */
    @AuraEnabled
    public static SaveResult saveValidationRule(Map<String, Object> ruleData, String recordId) {
        SaveResult result = new SaveResult();
        
        try {
            // Validate required fields
            String ruleName = (String)ruleData.get('name');
            String expression = (String)ruleData.get('expression');
            String errorMessage = (String)ruleData.get('errorMessage');
            
            if (String.isBlank(ruleName) || String.isBlank(expression) || String.isBlank(errorMessage)) {
                throw new AuraHandledException('Name, Expression, and Error Message are required');
            }
            
            // Build Custom Metadata record
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            String developerName = String.isNotBlank(recordId) ? recordId : generateDeveloperName(ruleName);
            customMetadata.fullName = 'Requirement_Field_Validation_Rule.' + developerName;
            customMetadata.label = ruleName;
            customMetadata.values = new List<Metadata.CustomMetadataValue>();
            
            // Add field values
            addMetadataValue(customMetadata, 'Description__c', ruleData.get('description'));
            addMetadataValue(customMetadata, 'Validation_Type__c', ruleData.get('validationType'));
            addMetadataValue(customMetadata, 'Validation_Expression__c', expression);
            addMetadataValue(customMetadata, 'Error_Message__c', errorMessage);
            addMetadataValue(customMetadata, 'Validation_Mode__c', ruleData.get('validationMode'));
            addMetadataValue(customMetadata, 'External_Service__c', ruleData.get('externalServiceId'));
            addMetadataValue(customMetadata, 'Is_Active__c', true);
            
            // Deploy metadata
            Metadata.DeployContainer container = new Metadata.DeployContainer();
            container.addMetadata(customMetadata);
            
            // Use Metadata API to deploy
            Id asyncResultId = Metadata.Operations.enqueueDeployment(container, null);
            
            result.success = true;
            result.id = developerName;
            result.message = 'Validation rule queued for deployment. Deployment ID: ' + asyncResultId;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error saving validation rule: ' + e.getMessage();
            throw new AuraHandledException(result.message);
        }
        
        return result;
    }

    /**
     * Helper: Add metadata value
     */
    private static void addMetadataValue(Metadata.CustomMetadata metadata, String fieldName, Object value) {
        if (value != null) {
            Metadata.CustomMetadataValue customValue = new Metadata.CustomMetadataValue();
            customValue.field = fieldName;
            customValue.value = value;
            metadata.values.add(customValue);
        }
    }

    /**
     * Helper: Generate developer name from label
     */
    private static String generateDeveloperName(String label) {
        // Convert label to valid developer name
        String devName = label.replaceAll('[^a-zA-Z0-9_]', '_');
        devName = devName.replaceAll('_{2,}', '_');
        devName = devName.removeStart('_').removeEnd('_');
        
        // Ensure it starts with a letter
        if (devName.length() > 0) {
            String firstChar = devName.substring(0, 1);
            if (!Pattern.matches('[a-zA-Z]', firstChar)) {
                devName = 'Rule_' + devName;
            }
        }
        
        // Limit length
        if (devName.length() > 40) {
            devName = devName.substring(0, 40);
        }
        
        return devName;
    }

    /**
     * Field metadata wrapper
     */
    public class FieldMetadata {
        @AuraEnabled public String id;
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
    }

    /**
     * Validation result wrapper
     */
    public class ValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String message;
        @AuraEnabled public String errorMessage;
    }

    /**
     * Validation test result wrapper
     */
    public class ValidationTestResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String message;
        @AuraEnabled public String errorMessage;
    }

    /**
     * Save result wrapper
     */
    public class SaveResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String id;
        @AuraEnabled public String message;
    }
}

