public with sharing class OnboardingAppVendorProgramReqSvc {

    public static List<Required_Credential__c> getRequiredCredentials(Id vendorProgramId) {
        return OnboardingAppVendorProgramReqOrch.orchestrateCredentialLoad(vendorProgramId);
    }

    public static List<Training_Requirement__c> getTrainingRequirements(Id vendorProgramId) {
        return OnboardingAppVendorProgramReqOrch.orchestrateTrainingLoad(vendorProgramId);
    }

    public static Id createRequiredCredential(Required_Credential__c record) {
        return OnboardingAppVendorProgramReqOrch.orchestrateCreateCredential(record);
    }

    public static Id createTrainingRequirement(Training_Requirement__c record) {
        return OnboardingAppVendorProgramReqOrch.orchestrateCreateTraining(record);
    }

    public static void updateRequiredCredentials(List<Required_Credential__c> records) {
        OnboardingAppVendorProgramReqRepo.updateRequiredCredentials(records);
    }

    public static List<External_Contact_Credential_Type__c> getCredentialTypes() {
        return OnboardingAppECCService.getAvailableCredentialTypes();
    }

    public static External_Contact_Credential_Type__c createCredentialType(External_Contact_Credential_Type__c record) {
        return OnboardingAppECCService.createCredentialType(record);
    }
    
    public static List<Training_System__c> getTrainingSystems() {
        return OnboardingAppVendorProgramReqRepo.fetchActiveTrainingSystems();
    }
    
    public static Id createTrainingSystem(Training_System__c record) {
        ValidationHelper.requireField(record.Name, 'Name');
        
        // Create a new record to ensure clean state
        Training_System__c newRecord = new Training_System__c();
        newRecord.Name = record.Name.trim();
        
        // Apply default values
        DefaultValueHelper.applyTrainingSystemDefaults(newRecord);
        
        // Override Active__c if explicitly provided
        if (record.Active__c != null) {
            newRecord.Active__c = record.Active__c;
        }
        
        // Set System_Type__c if provided, otherwise use default
        if (String.isNotBlank(record.System_Type__c)) {
            newRecord.System_Type__c = record.System_Type__c;
        } else {
            newRecord.System_Type__c = 'External';
        }
        
        // Copy any other fields if needed
        if (String.isNotBlank(record.Notes__c)) {
            newRecord.Notes__c = record.Notes__c;
        }
        
        return OnboardingAppVendorProgramReqRepo.insertTrainingSystem(newRecord);
    }
    
    public static void updateTrainingRequirementRequiredStatus(List<Id> trainingRequirementIds, Boolean isRequired) {
        if (trainingRequirementIds == null || trainingRequirementIds.isEmpty()) {
            return;
        }
        OnboardingAppVendorProgramReqRepo.updateTrainingRequirementRequiredStatus(trainingRequirementIds, isRequired);
    }
}
