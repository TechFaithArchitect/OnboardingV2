/**
 * Controller for Twilio Settings Admin UI
 * Handles CRUD operations for Twilio_Configuration__mdt records
 * Restricted to System Administrators only
 */
public with sharing class TwilioSettingsController {
    
    /**
     * Get all Twilio configuration records
     * Restricted to System Administrators
     * @return List of Twilio configuration wrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<TwilioConfigWrapper> getTwilioConfigurations() {
        // Admin gate: Only System Administrators can access
        if (!OnboardingAccessService.isCurrentUserAdmin()) {
            throw new AuraHandledException('Access denied. Twilio Settings is restricted to System Administrators.');
        }
        
        List<TwilioConfigWrapper> configs = new List<TwilioConfigWrapper>();
        
        try {
            List<Twilio_Configuration__mdt> records = [
                SELECT DeveloperName, MasterLabel, 
                       From_Phone_Number__c, Named_Credential__c, 
                       Account_SID__c, Active__c
                FROM Twilio_Configuration__mdt
                ORDER BY Active__c DESC, MasterLabel
            ];
            
            for (Twilio_Configuration__mdt config : records) {
                configs.add(new TwilioConfigWrapper(config));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error loading Twilio configurations: ' + e.getMessage());
        }
        
        return configs;
    }
    
    /**
     * Validate Twilio configuration
     * Ensures at least one active configuration exists with required fields
     * Restricted to System Administrators
     * @return Validation result with error message if invalid
     */
    @AuraEnabled
    public static ValidationResult validateConfiguration() {
        // Admin gate: Only System Administrators can access
        if (!OnboardingAccessService.isCurrentUserAdmin()) {
            ValidationResult result = new ValidationResult();
            result.isValid = false;
            result.errorMessage = 'Access denied. Twilio Settings is restricted to System Administrators.';
            return result;
        }
        ValidationResult result = new ValidationResult();
        result.isValid = true;
        
        try {
            List<Twilio_Configuration__mdt> activeConfigs = [
                SELECT From_Phone_Number__c, Named_Credential__c, Account_SID__c
                FROM Twilio_Configuration__mdt
                WHERE Active__c = true
            ];
            
            if (activeConfigs.isEmpty()) {
                result.isValid = false;
                result.errorMessage = 'No active Twilio configuration found. At least one active configuration is required.';
                return result;
            }
            
            // Check if any active config has required fields
            Boolean hasValidConfig = false;
            for (Twilio_Configuration__mdt config : activeConfigs) {
                if (String.isNotBlank(config.From_Phone_Number__c) && 
                    String.isNotBlank(config.Named_Credential__c)) {
                    hasValidConfig = true;
                    break;
                }
            }
            
            if (!hasValidConfig) {
                result.isValid = false;
                result.errorMessage = 'Active Twilio configuration must have From Phone Number and Named Credential.';
                return result;
            }
            
        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'Error validating configuration: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Wrapper class for Twilio configuration metadata
     */
    public class TwilioConfigWrapper {
        @AuraEnabled public String developerName;
        @AuraEnabled public String masterLabel;
        @AuraEnabled public String fromPhoneNumber;
        @AuraEnabled public String namedCredential;
        @AuraEnabled public String accountSid;
        @AuraEnabled public Boolean active;
        
        public TwilioConfigWrapper(Twilio_Configuration__mdt config) {
            this.developerName = config.DeveloperName;
            this.masterLabel = config.MasterLabel;
            this.fromPhoneNumber = config.From_Phone_Number__c;
            this.namedCredential = config.Named_Credential__c;
            this.accountSid = config.Account_SID__c;
            this.active = config.Active__c != null ? config.Active__c : false;
        }
    }
    
    /**
     * Validation result wrapper
     */
    public class ValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String errorMessage;
    }
}