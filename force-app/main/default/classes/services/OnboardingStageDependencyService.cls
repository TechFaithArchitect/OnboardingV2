/**
 * Service layer for Onboarding Stage Dependency validation.
 * Checks if stages can be started based on dependency rules.
 */
public with sharing class OnboardingStageDependencyService {

    /**
     * Checks if a target stage can be started based on its dependencies.
     * Returns a DTO with validation result and any blocking dependencies.
     * 
     * @param targetStageId The stage the user wants to start
     * @param vendorProgramId The vendor program ID
     * @param processId The onboarding process ID
     * @return StageDependencyValidationDTO with canStart flag and blocking dependencies
     */
    public static StageDependencyValidationDTO canStartStage(Id targetStageId, Id vendorProgramId, Id processId) {
        StageDependencyValidationDTO result = new StageDependencyValidationDTO();
        result.targetStageId = targetStageId;
        result.canStart = true;
        result.blockingDependencies = new List<DependencyInfo>();

        // Get all dependencies for this target stage
        List<Onboarding_Application_Stage_Dependency__c> dependencies = 
            OnboardingStageDependencyRepository.getDependenciesForTargetStage(targetStageId);

        if (dependencies.isEmpty()) {
            // No dependencies, stage can be started
            return result;
        }

        // Get completed stages for this vendor program and process
        Set<Id> completedStageIds = OnboardingStageDependencyRepository.getCompletedStageIds(
            vendorProgramId, 
            processId
        );

        // Evaluate each dependency rule
        for (Onboarding_Application_Stage_Dependency__c dependency : dependencies) {
            // Skip if dependency is not required
            if (dependency.Required__c == false) {
                continue;
            }

            // Get required stages from members
            List<Id> requiredStageIds = new List<Id>();
            for (Onboarding_App_Stage_Dependency_Member__c member : dependency.Onboarding_App_Stage_Dependency_Members__r) {
                if (member.Required__c != false && member.Required_Stage__c != null) {
                    requiredStageIds.add(member.Required_Stage__c);
                }
            }

            if (requiredStageIds.isEmpty()) {
                continue; // No required stages in this dependency
            }

            // Evaluate based on logic type
            Boolean dependencyMet = evaluateDependency(
                dependency.Logic_Type__c,
                requiredStageIds,
                completedStageIds
            );

            if (!dependencyMet) {
                result.canStart = false;
                
                // Build blocking dependency info
                DependencyInfo blockingInfo = new DependencyInfo();
                blockingInfo.dependencyId = dependency.Id;
                blockingInfo.dependencyName = dependency.Name;
                blockingInfo.logicType = dependency.Logic_Type__c;
                blockingInfo.requiredStageIds = requiredStageIds;
                blockingInfo.completedStageIds = new List<Id>();
                blockingInfo.missingStageIds = new List<Id>();

                // Determine which stages are missing
                for (Id requiredId : requiredStageIds) {
                    if (completedStageIds.contains(requiredId)) {
                        blockingInfo.completedStageIds.add(requiredId);
                    } else {
                        blockingInfo.missingStageIds.add(requiredId);
                    }
                }

                result.blockingDependencies.add(blockingInfo);
            }
        }

        return result;
    }

    /**
     * Evaluates a dependency based on its logic type.
     * 
     * @param logicType The logic type: ALL, ANY, or CUSTOM
     * @param requiredStageIds List of required stage IDs
     * @param completedStageIds Set of completed stage IDs
     * @return True if dependency is met, false otherwise
     */
    private static Boolean evaluateDependency(
        String logicType,
        List<Id> requiredStageIds,
        Set<Id> completedStageIds
    ) {
        if (requiredStageIds.isEmpty()) {
            return true; // No requirements means dependency is met
        }

        if (logicType == 'ALL') {
            // All required stages must be completed
            for (Id requiredId : requiredStageIds) {
                if (!completedStageIds.contains(requiredId)) {
                    return false;
                }
            }
            return true;
        } else if (logicType == 'ANY') {
            // At least one required stage must be completed
            for (Id requiredId : requiredStageIds) {
                if (completedStageIds.contains(requiredId)) {
                    return true;
                }
            }
            return false;
        } else if (logicType == 'CUSTOM') {
            // Custom logic not yet implemented - default to ALL for safety
            // TODO: Implement custom logic evaluation if needed
            for (Id requiredId : requiredStageIds) {
                if (!completedStageIds.contains(requiredId)) {
                    return false;
                }
            }
            return true;
        } else {
            // Unknown logic type - default to ALL for safety
            for (Id requiredId : requiredStageIds) {
                if (!completedStageIds.contains(requiredId)) {
                    return false;
                }
            }
            return true;
        }
    }

    /**
     * Gets dependency information for a target stage (for display purposes).
     * Returns all dependencies regardless of whether they're met.
     * 
     * @param targetStageId The stage to get dependencies for
     * @param vendorProgramId The vendor program ID
     * @param processId The onboarding process ID
     * @return List of dependency information
     */
    public static List<DependencyInfo> getDependencyInfo(Id targetStageId, Id vendorProgramId, Id processId) {
        List<DependencyInfo> dependencyInfoList = new List<DependencyInfo>();

        // Get all dependencies for this target stage
        List<Onboarding_Application_Stage_Dependency__c> dependencies = 
            OnboardingStageDependencyRepository.getDependenciesForTargetStage(targetStageId);

        if (dependencies.isEmpty()) {
            return dependencyInfoList;
        }

        // Get completed stages
        Set<Id> completedStageIds = OnboardingStageDependencyRepository.getCompletedStageIds(
            vendorProgramId, 
            processId
        );

        // Build dependency info for each dependency rule
        for (Onboarding_Application_Stage_Dependency__c dependency : dependencies) {
            DependencyInfo info = new DependencyInfo();
            info.dependencyId = dependency.Id;
            info.dependencyName = dependency.Name;
            info.logicType = dependency.Logic_Type__c;
            info.requiredStageIds = new List<Id>();
            info.completedStageIds = new List<Id>();
            info.missingStageIds = new List<Id>();

            // Process members
            for (Onboarding_App_Stage_Dependency_Member__c member : dependency.Onboarding_App_Stage_Dependency_Members__r) {
                if (member.Required_Stage__c != null) {
                    info.requiredStageIds.add(member.Required_Stage__c);
                    
                    if (completedStageIds.contains(member.Required_Stage__c)) {
                        info.completedStageIds.add(member.Required_Stage__c);
                    } else {
                        info.missingStageIds.add(member.Required_Stage__c);
                    }
                }
            }

            dependencyInfoList.add(info);
        }

        return dependencyInfoList;
    }

    /**
     * DTO for stage dependency validation result
     */
    public class StageDependencyValidationDTO {
        @AuraEnabled public Id targetStageId;
        @AuraEnabled public Boolean canStart;
        @AuraEnabled public List<DependencyInfo> blockingDependencies;
    }

    /**
     * DTO for dependency information
     */
    public class DependencyInfo {
        @AuraEnabled public Id dependencyId;
        @AuraEnabled public String dependencyName;
        @AuraEnabled public String logicType;
        @AuraEnabled public List<Id> requiredStageIds;
        @AuraEnabled public List<Id> completedStageIds;
        @AuraEnabled public List<Id> missingStageIds;
    }
}


