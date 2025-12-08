public with sharing class OnboardingAppECCController {

    @AuraEnabled(cacheable=true)
    public static List<Required_Credential__c> getRequiredCredentials(Id vendorProgramId) {
        return OnboardingAppECCService.getRequiredCredentials(vendorProgramId);
    }

    @AuraEnabled(cacheable=true)
    public static List<External_Contact_Credential_Type__c> getAvailableCredentialTypes() {
        return OnboardingAppECCService.getAvailableCredentialTypes();
    }

    @AuraEnabled
    public static External_Contact_Credential_Type__c createCredentialType(String name, Integer sortOrder, Id vendorCustomizationId, Boolean active) {
        return OnboardingAppECCService.createCredentialType(name, sortOrder, vendorCustomizationId, active);
    }

    @AuraEnabled
    public static void linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId) {
        OnboardingAppECCService.linkCredentialTypeToRequiredCredential(requiredCredentialId, credentialTypeId);
    }
}