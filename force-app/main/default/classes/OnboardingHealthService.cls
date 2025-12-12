/**
 * Validates presence and ordering of the Vendor Program Onboarding process and components.
 */
public with sharing class OnboardingHealthService {

    public class HealthItem {
        @AuraEnabled public String type;
        @AuraEnabled public String message;
    }

    private static final String PROCESS_NAME = 'Vendor Program Onboarding';
    private static final List<String> EXPECTED_COMPONENTS = new List<String>{
        'vendorProgramOnboardingVendor',
        'vendorProgramOnboardingVendorProgramSearchOrCreate',
        'vendorProgramOnboardingRequirementSetOrCreate',
        'vendorProgramOnboardingRequirementGroupLinking',
        'vendorProgramOnboardingRequiredCredentials',
        'vendorProgramOnboardingTrainingRequirements',
        'vendorProgramOnboardingStatusRulesEngine',
        'vendorProgramOnboardingRecipientGroup',
        'vendorProgramOnboardingCommunicationTemplate',
        'vendorProgramOnboardingFinalize'
    };

    @AuraEnabled(cacheable=true)
    public static List<HealthItem> runHealthCheck() {
        List<HealthItem> results = new List<HealthItem>();

        Map<String, Id> lib = OnboardingHealthRepository.getComponentLibraryByApiName();
        for (String apiName : EXPECTED_COMPONENTS) {
            if (!lib.containsKey(apiName)) {
                results.add(item('component', 'Missing component library entry: ' + apiName));
            }
        }

        List<Onboarding_Application_Process__c> processes =
            OnboardingHealthRepository.fetchActiveProcessesByName(PROCESS_NAME);
        if (processes.isEmpty()) {
            results.add(item('process', 'Active process not found: ' + PROCESS_NAME));
            return results;
        }

        Id processId = processes[0].Id;
        List<Onboarding_Application_Stage__c> stages =
            OnboardingHealthRepository.fetchStagesForProcess(processId);

        if (stages.size() != EXPECTED_COMPONENTS.size()) {
            results.add(item('stage', 'Stage count mismatch. Expected ' +
                EXPECTED_COMPONENTS.size() + ', found ' + stages.size()));
        }

        Map<Integer, Onboarding_Application_Stage__c> stagesByOrder = new Map<Integer, Onboarding_Application_Stage__c>();
        for (Onboarding_Application_Stage__c st : stages) {
            stagesByOrder.put((Integer)st.Display_Order__c, st);
        }

        for (Integer i = 0; i < EXPECTED_COMPONENTS.size(); i++) {
            Integer order = i + 1;
            Onboarding_Application_Stage__c st = stagesByOrder.get(order);
            if (st == null) {
                results.add(item('stage', 'Missing stage at order ' + order));
                continue;
            }
            String expectedApi = EXPECTED_COMPONENTS[i];
            if (st.Onboarding_Component_Library__c == null) {
                results.add(item('stage', 'Stage ' + order + ' has no component link'));
                continue;
            }
            // Fetch component api names once for comparison
            String actualApi = null;
            for (String key : lib.keySet()) {
                if (lib.get(key) == st.Onboarding_Component_Library__c) {
                    actualApi = key;
                    break;
                }
            }
            if (actualApi == null || actualApi != expectedApi) {
                results.add(item('stage', 'Stage ' + order + ' component mismatch. Expected ' +
                    expectedApi + ', found ' + (actualApi == null ? 'unknown' : actualApi)));
            }
        }

        if (results.isEmpty()) {
            results.add(item('ok', 'Component library and process are aligned.'));
        }
        return results;
    }

    private static HealthItem item(String type, String msg) {
        HealthItem hi = new HealthItem();
        hi.type = type;
        hi.message = msg;
        return hi;
    }
}
