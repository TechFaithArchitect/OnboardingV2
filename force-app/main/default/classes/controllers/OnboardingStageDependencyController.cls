/**
 * Controller for Stage Dependency Viewer component
 */
public with sharing class OnboardingStageDependencyController {

    /**
     * Gets stages with dependency information for visualization
     * @param processId The onboarding process ID
     * @param vendorProgramId The vendor program ID (optional, for completion status)
     * @return List of StageWithDependencyDTO objects
     */
    @AuraEnabled(cacheable=true)
    public static List<StageWithDependencyDTO> getStagesWithDependencies(Id processId, Id vendorProgramId) {
        ValidationHelper.requireId(processId, 'Process ID');
        
        List<StageWithDependencyDTO> result = new List<StageWithDependencyDTO>();
        
        // Get all stages for the process
        // Note: Repository returns Display_Order__c, not Sequence__c
        List<Onboarding_Application_Stage__c> stages = OnboardingApplicationRepository.fetchStagesForProcess(processId);
        
        // Get completed stages if vendor program is provided
        Set<Id> completedStageIds = new Set<Id>();
        if (vendorProgramId != null) {
            completedStageIds = OnboardingStageDependencyRepository.getCompletedStageIds(vendorProgramId, processId);
        }
        
        // Get all dependencies for all stages (bulk query)
        Set<Id> stageIds = new Set<Id>();
        for (Onboarding_Application_Stage__c stage : stages) {
            stageIds.add(stage.Id);
        }
        List<Onboarding_Application_Stage_Dependency__c> allDependencies = 
            OnboardingStageDependencyRepository.getDependenciesForTargetStages(stageIds);
        
        // Build map of dependencies by target stage
        Map<Id, List<Onboarding_Application_Stage_Dependency__c>> dependenciesByStage = 
            new Map<Id, List<Onboarding_Application_Stage_Dependency__c>>();
        for (Onboarding_Application_Stage_Dependency__c dep : allDependencies) {
            if (!dependenciesByStage.containsKey(dep.Target_Stage__c)) {
                dependenciesByStage.put(dep.Target_Stage__c, new List<Onboarding_Application_Stage_Dependency__c>());
            }
            dependenciesByStage.get(dep.Target_Stage__c).add(dep);
        }
        
        // Build DTOs
        for (Onboarding_Application_Stage__c stage : stages) {
            StageWithDependencyDTO dto = new StageWithDependencyDTO();
            dto.stageId = stage.Id;
            dto.stageName = stage.Name;
            // Use Display_Order__c as sequence (repository doesn't query Sequence__c)
            dto.sequence = stage.Display_Order__c != null ? Integer.valueOf(stage.Display_Order__c) : 0;
            dto.isCompleted = completedStageIds.contains(stage.Id);
            dto.isBlocked = false;
            dto.requiredStageIds = new List<Id>();
            
            // Get dependencies for this stage
            List<Onboarding_Application_Stage_Dependency__c> deps = dependenciesByStage.get(stage.Id);
            if (deps != null && !deps.isEmpty()) {
                for (Onboarding_Application_Stage_Dependency__c dep : deps) {
                    if (dep.Required__c == true) {
                        for (Onboarding_App_Stage_Dependency_Member__c member : dep.Onboarding_App_Stage_Dependency_Members__r) {
                            if (member.Required_Stage__c != null && member.Required__c != false) {
                                dto.requiredStageIds.add(member.Required_Stage__c);
                                
                                // Check if blocked (dependency not met)
                                if (!completedStageIds.contains(member.Required_Stage__c)) {
                                    dto.isBlocked = true;
                                }
                            }
                        }
                    }
                }
            }
            
            result.add(dto);
        }
        
        // Sort by sequence
        result.sort(new StageSequenceComparator());
        
        return result;
    }

    /**
     * DTO for stage with dependency information
     */
    public class StageWithDependencyDTO {
        @AuraEnabled public Id stageId;
        @AuraEnabled public String stageName;
        @AuraEnabled public Integer sequence;
        @AuraEnabled public Boolean isCompleted;
        @AuraEnabled public Boolean isBlocked;
        @AuraEnabled public List<Id> requiredStageIds;
    }

    /**
     * Comparator for sorting stages by sequence
     */
    private class StageSequenceComparator implements Comparator<StageWithDependencyDTO> {
        public Integer compare(StageWithDependencyDTO a, StageWithDependencyDTO b) {
            if (a.sequence < b.sequence) return -1;
            if (a.sequence > b.sequence) return 1;
            return 0;
        }
    }
}