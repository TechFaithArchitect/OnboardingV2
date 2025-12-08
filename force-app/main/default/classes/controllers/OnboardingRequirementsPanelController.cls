public with sharing class OnboardingRequirementsPanelController {

    @AuraEnabled(cacheable=true)
    public static List<OnboardingApplicationService.RequirementDTO> getRequirements(Id onboardingId) {
        return OnboardingApplicationService.getRequirements(onboardingId);
    }

    @AuraEnabled
    public static void updateRequirementStatuses(List<OnboardingApplicationService.RequirementDTO> updates) {
        OnboardingApplicationService.updateRequirementStatuses(updates);
    }

    @AuraEnabled
    public static void runRuleEvaluation(Id onboardingId) {
        OnboardingApplicationService.runRuleEvaluation(onboardingId);
    }

    /**
     * Returns Requirement Field Values that are not Valid for the given onboarding record.
     * Used by the Requirements Panel to surface only the fields that need correction.
     */
    @AuraEnabled(cacheable=true)
    public static List<InvalidFieldDTO> getInvalidFieldValues(Id onboardingId) {
        ValidationHelper.requireId(onboardingId, 'Onboarding ID');

        List<Requirement_Field_Value__c> invalidValues = [
            SELECT Id,
                   Validation_Status__c,
                   Validation_Error_Message__c,
                   Requirement_Field__r.Name,
                   Requirement_Field__r.Field_API_Name__c,
                   Onboarding_Requirement__r.Name
            FROM Requirement_Field_Value__c
            WHERE Onboarding_Requirement__r.Onboarding__c = :onboardingId
              AND Is_Archived__c = false
              AND Validation_Status__c != 'Valid'
        ];

        List<InvalidFieldDTO> results = new List<InvalidFieldDTO>();
        for (Requirement_Field_Value__c fv : invalidValues) {
            InvalidFieldDTO dto = new InvalidFieldDTO();
            dto.fieldValueId = fv.Id;
            dto.requirementName = fv.Onboarding_Requirement__r.Name;
            dto.fieldName = fv.Requirement_Field__r.Name;
            dto.fieldApiName = fv.Requirement_Field__r.Field_API_Name__c;
            dto.status = fv.Validation_Status__c;
            dto.message = fv.Validation_Error_Message__c;
            results.add(dto);
        }
        return results;
    }

    /**
     * Re-runs async validation for the specified field values.
     * The UI can call this after users correct individual fields.
     */
    @AuraEnabled
    public static void rerunValidation(List<Id> fieldValueIds) {
        if (fieldValueIds == null || fieldValueIds.isEmpty()) {
            return;
        }
        RequirementFieldAsyncValidator.enqueue(new Set<Id>(fieldValueIds));
    }

    public class InvalidFieldDTO {
        @AuraEnabled public Id fieldValueId;
        @AuraEnabled public String requirementName;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }
}
