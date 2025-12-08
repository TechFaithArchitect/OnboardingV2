public with sharing class OnboardingTargetRecordFinder {
    /*
    // This is the Invocable class that Flow will call
    @InvocableMethod(label='Find Target Record Id for Onboarding' description='Returns the first related record Id found on the Onboarding record')
    public static List<TargetRecordIdResult> findTargetRecordId(List<OnboardingInput> onboardingInputs) {
        List<TargetRecordIdResult> results = new List<TargetRecordIdResult>();

        for (OnboardingInput input : onboardingInputs) {
            TargetRecordIdResult result = new TargetRecordIdResult();
            result.TargetRecordId = OnboardingHelper.getTargetRecordId(input.OnboardingRecord);
            results.add(result);
        }
        
        return results;
    }

    // Input class to accept Onboarding__c record
    public class OnboardingInput {
        @InvocableVariable(label='Onboarding Record' required=true)
        public Onboarding__c OnboardingRecord;
    }

    // Output class to return TargetRecordId
    public class TargetRecordIdResult {
        @InvocableVariable(label='Target Record Id')
        public Id TargetRecordId;
    }
	*/
}