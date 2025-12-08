public with sharing class OnboardingStatusEvaluator {

    public static void evaluateAndApplyStatus(List<Onboarding__c> onboardings) {
        evaluateAndApplyStatusInternal(onboardings, false);
    }

    public static void evaluateAndApplyStatus(Onboarding__c onboarding) {
        if (onboarding != null) {
            evaluateAndApplyStatus(new List<Onboarding__c>{ onboarding });
        }
    }

    /**
     * Version with optional fallback progression based on requirement completion.
     */
    public static void evaluateAndApplyStatusWithProgress(List<Onboarding__c> onboardings) {
        evaluateAndApplyStatusInternal(onboardings, true);
    }

    public static void evaluateAndApplyStatusWithProgress(Onboarding__c onboarding) {
        if (onboarding != null) {
            evaluateAndApplyStatusWithProgress(new List<Onboarding__c>{ onboarding });
        }
    }

    private static void evaluateAndApplyStatusInternal(List<Onboarding__c> onboardings, Boolean useProgressFallback) {
        if (onboardings == null || onboardings.isEmpty()) return;
        
        Set<Id> onboardingIds = new Set<Id>();
        for (Onboarding__c ob : onboardings) {
            onboardingIds.add(ob.Id);
        }
        
        Map<Id, Map<Id, Onboarding_Requirement__c>> reqByOnboardingByVPR = 
            OnboardingRulesService.getRequirementsByVPRBulk(onboardingIds);
        
        Map<Id, Id> vendorProgramByOnboarding = OnboardingRulesService.getVendorProgramIdsBulk(onboardingIds);
        
        Set<Id> vendorProgramIds = new Set<Id>(vendorProgramByOnboarding.values());
        Map<Id, List<Id>> groupIdsByVendorProgram = OnboardingRulesService.getVendorProgramGroupIdsBulk(vendorProgramIds);
        
        Set<Id> allGroupIds = new Set<Id>();
        for (List<Id> groupIds : groupIdsByVendorProgram.values()) {
            allGroupIds.addAll(groupIds);
        }
        List<Onboarding_Status_Rules_Engine__c> allRules = OnboardingRulesService.getRulesForGroups(new List<Id>(allGroupIds));
        Map<Id, List<Onboarding_Status_Rules_Engine__c>> rulesByGroup = new Map<Id, List<Onboarding_Status_Rules_Engine__c>>();
        for (Onboarding_Status_Rules_Engine__c rule : allRules) {
            if (!rulesByGroup.containsKey(rule.Vendor_Program_Group__c)) {
                rulesByGroup.put(rule.Vendor_Program_Group__c, new List<Onboarding_Status_Rules_Engine__c>());
            }
            rulesByGroup.get(rule.Vendor_Program_Group__c).add(rule);
        }
        
        // Fetch full Onboarding__c records with all fields for dynamic field access
        Map<Id, Onboarding__c> onboardingRecordsById = new Map<Id, Onboarding__c>(
            OnboardingRulesRepository.fetchOnboardingsByIdsWithAllFields(onboardingIds)
        );
        
        List<Onboarding__c> toUpdate = new List<Onboarding__c>();
        for (Onboarding__c onboarding : onboardings) {
            Map<Id, Onboarding_Requirement__c> reqByVPR = reqByOnboardingByVPR.get(onboarding.Id);
            if (reqByVPR == null || reqByVPR.isEmpty()) continue;
            
            Id vendorProgramId = vendorProgramByOnboarding.get(onboarding.Id);
            if (vendorProgramId == null) continue;
            
            List<Id> groupIds = groupIdsByVendorProgram.get(vendorProgramId);
            if (groupIds == null || groupIds.isEmpty()) continue;
            
            // Get the full onboarding record for dynamic field access
            Onboarding__c fullOnboardingRecord = onboardingRecordsById.get(onboarding.Id);
            if (fullOnboardingRecord == null) {
                fullOnboardingRecord = onboarding; // Fallback to provided record
            }

            // If override is enabled, skip status evaluation to honor external override
            if (Boolean.valueOf(fullOnboardingRecord.get('External_Override_Enabled__c'))) {
                continue;
            }
            
            String newStatus = null;
            for (Id groupId : groupIds) {
                List<Onboarding_Status_Rules_Engine__c> rules = rulesByGroup.get(groupId);
                if (rules == null) continue;
                
                for (Onboarding_Status_Rules_Engine__c rule : rules) {
                    Boolean rulePassed = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR, fullOnboardingRecord);
                    if (rulePassed && String.isNotBlank(rule.Target_Onboarding_Status__c)) {
                        newStatus = rule.Target_Onboarding_Status__c;
                        break;
                    }
                }
                if (newStatus != null) break;
            }

            if (newStatus == null && useProgressFallback) {
                newStatus = computeProgressStatus(reqByVPR.values());
            }
            
            if (newStatus != null && onboarding.Onboarding_Status__c != newStatus) {
                onboarding.Onboarding_Status__c = newStatus;
                toUpdate.add(onboarding);
            }
        }
        
        // Use repository for update
        if (!toUpdate.isEmpty()) {
            OnboardingRepository.updateOnboardings(toUpdate);
        }
    }

    /**
     * Simple fallback progression based on requirement completion.
     * Priority: Denied > Setup Complete/Complete > In Process > New.
     */
    private static String computeProgressStatus(Iterable<Onboarding_Requirement__c> reqs) {
        Integer total = 0;
        Integer completeCount = 0;
        Integer startedCount = 0;
        Boolean anyDenied = false;

        for (Onboarding_Requirement__c req : reqs) {
            String status = req.Status__c;

            if ('Denied' == status) {
                anyDenied = true;
            }

            total++;

            Boolean isComplete = ('Setup Complete' == status || 'Complete' == status || req.Completed__c == true);
            if (isComplete) {
                completeCount++;
            } else if (status != null && status != 'New') {
                startedCount++;
            }
        }

        if (anyDenied) {
            return 'Denied';
        }
        if (total > 0 && completeCount == total) {
            return 'Setup Complete';
        }
        if (startedCount > 0) {
            return 'In Process';
        }
        return 'New';
    }
}
