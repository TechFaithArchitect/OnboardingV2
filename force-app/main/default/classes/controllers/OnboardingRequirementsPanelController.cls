public with sharing class OnboardingRequirementsPanelController {
  @AuraEnabled(cacheable=true)
  public static List<OnboardingApplicationService.RequirementDTO> getRequirements(
    Id onboardingId
  ) {
    return OnboardingApplicationService.getRequirements(onboardingId);
  }

  @AuraEnabled
  public static void updateRequirementStatuses(
    List<OnboardingApplicationService.RequirementDTO> updates
  ) {
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

    // Use repository for data access
    List<Requirement_Field_Value__c> invalidValues = RequirementFieldValueRepository.getInvalidFieldValuesByOnboarding(
      onboardingId
    );

    List<InvalidFieldDTO> invalidFieldDTOList = new List<InvalidFieldDTO>();
    for (Requirement_Field_Value__c fieldValue : invalidValues) {
      InvalidFieldDTO invalidFieldDTO = new InvalidFieldDTO();
      invalidFieldDTO.fieldValueId = fieldValue.Id;
      invalidFieldDTO.requirementName = fieldValue.Onboarding_Requirement__r.Name;
      invalidFieldDTO.fieldName = fieldValue.Requirement_Field__r.Name;
      invalidFieldDTO.fieldApiName = fieldValue.Requirement_Field__r.Field_API_Name__c;
      invalidFieldDTO.status = fieldValue.Validation_Status__c;
      invalidFieldDTO.message = fieldValue.Validation_Error_Message__c;
      invalidFieldDTOList.add(invalidFieldDTO);
    }
    return invalidFieldDTOList;
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
    @AuraEnabled
    public Id fieldValueId;
    @AuraEnabled
    public String requirementName;
    @AuraEnabled
    public String fieldName;
    @AuraEnabled
    public String fieldApiName;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String message;
  }
}
