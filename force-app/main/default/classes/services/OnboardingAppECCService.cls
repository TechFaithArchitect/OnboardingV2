public with sharing class OnboardingAppECCService {

    public static List<Required_Credential__c> getRequiredCredentials(Id vendorProgramId) {
        return OnboardingAppECCRepository.fetchRequiredCredentials(vendorProgramId);
    }

    public static List<External_Contact_Credential_Type__c> getAvailableCredentialTypes() {
        return OnboardingAppECCRepository.fetchCredentialTypes();
    }

    public static External_Contact_Credential_Type__c createCredentialType(External_Contact_Credential_Type__c record) {
        ValidationHelper.requireRecord(record, 'Credential Type');
        ValidationHelper.requireField(record.Name, 'Name');
        ValidationHelper.requireId(record.Vendor_Customization__c, 'Vendor Program');

        External_Contact_Credential_Type__c newType = new External_Contact_Credential_Type__c();
        newType.Name = record.Name.trim();
        newType.Vendor_Customization__c = record.Vendor_Customization__c;
        newType.Active__c = record.Active__c != null ? record.Active__c : true;
        if (record.Sort_Order__c != null) {
            newType.Sort_Order__c = record.Sort_Order__c;
        }
        if (String.isNotBlank(record.Description__c)) {
            newType.Description__c = record.Description__c;
        }

        return OnboardingAppECCRepository.insertCredentialType(newType);
    }

    public static External_Contact_Credential_Type__c createCredentialType(String name, Integer sortOrder, Id vendorCustomizationId, Boolean active) {
        return OnboardingAppECCRepository.insertCredentialType(name, sortOrder, vendorCustomizationId, active);
    }

    public static void linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId) {
        OnboardingAppECCRepository.updateRequiredCredential(requiredCredentialId, credentialTypeId);
    }
}
