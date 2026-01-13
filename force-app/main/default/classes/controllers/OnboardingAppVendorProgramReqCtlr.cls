public with sharing class OnboardingAppVendorProgramReqCtlr {
    
    @AuraEnabled(cacheable=true)
    public static List<Required_Credential__c> getRequiredCredentials(Id vendorProgramId) {
        return OnboardingAppVendorProgramReqSvc.getRequiredCredentials(vendorProgramId);
    }

    @AuraEnabled
    public static void updateRequiredCredentials(List<Required_Credential__c> requiredCredentialRecords) {
        OnboardingAppVendorProgramReqSvc.updateRequiredCredentials(requiredCredentialRecords);
    }

    @AuraEnabled(cacheable=true)
    public static List<Training_Requirement__c> getTrainingRequirements(Id vendorProgramId) {
        return OnboardingAppVendorProgramReqSvc.getTrainingRequirements(vendorProgramId);
    }

    @AuraEnabled
    public static Id createRequiredCredential(Required_Credential__c newRequirement) {
        return OnboardingAppVendorProgramReqSvc.createRequiredCredential(newRequirement);
    }

    @AuraEnabled
    public static Id createTrainingRequirement(Training_Requirement__c newRequirement) {
        return OnboardingAppVendorProgramReqSvc.createTrainingRequirement(newRequirement);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Training_System__c> getTrainingSystems() {
        return OnboardingAppVendorProgramReqSvc.getTrainingSystems();
    }
    
    @AuraEnabled
    public static Id createTrainingSystem(Training_System__c newTrainingSystem) {
        return OnboardingAppVendorProgramReqSvc.createTrainingSystem(newTrainingSystem);
    }
    
    @AuraEnabled
    public static void updateTrainingRequirementRequiredStatus(List<Id> trainingRequirementIds, Boolean isRequired) {
        OnboardingAppVendorProgramReqSvc.updateTrainingRequirementRequiredStatus(trainingRequirementIds, isRequired);
    }

    // ----- External Contact Credential Types -----
    @AuraEnabled(cacheable=true)
    public static List<External_Contact_Credential_Type__c> getCredentialTypes() {
        return OnboardingAppVendorProgramReqSvc.getCredentialTypes();
    }

    @AuraEnabled
    public static External_Contact_Credential_Type__c createCredentialType(External_Contact_Credential_Type__c newType) {
        return OnboardingAppVendorProgramReqSvc.createCredentialType(newType);
    }
}