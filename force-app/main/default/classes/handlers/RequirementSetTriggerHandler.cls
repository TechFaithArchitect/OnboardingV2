/**
 * Handler for Onboarding_Requirement_Set__c trigger logic
 * Handles Display_Label__c population using junction objects
 */
public with sharing class RequirementSetTriggerHandler {
    
    // Static flag to prevent recursion
    private static Boolean isUpdatingDisplayLabel = false;
    
    /**
     * Before insert/update logic
     */
    public static void run(List<Onboarding_Requirement_Set__c> newList, Map<Id, Onboarding_Requirement_Set__c> oldMap) {
        // No before logic currently needed
    }
    
    /**
     * After insert logic - populate Display_Label__c
     */
    public static void afterInsert(List<Onboarding_Requirement_Set__c> newList) {
        if (!isUpdatingDisplayLabel) {
            updateDisplayLabels(newList);
        }
    }
    
    /**
     * After update logic - update Display_Label__c if Version__c or other fields changed
     */
    public static void afterUpdate(List<Onboarding_Requirement_Set__c> newList, Map<Id, Onboarding_Requirement_Set__c> oldMap) {
        if (isUpdatingDisplayLabel) {
            return; // Prevent recursion
        }
        
        List<Onboarding_Requirement_Set__c> toUpdate = new List<Onboarding_Requirement_Set__c>();
        
        for (Onboarding_Requirement_Set__c reqSet : newList) {
            Onboarding_Requirement_Set__c oldReqSet = oldMap.get(reqSet.Id);
            
            // Check if Version__c changed (if field exists)
            // Note: Version__c might not exist - handle gracefully
            try {
                if (oldReqSet != null && reqSet.get('Version__c') != oldReqSet.get('Version__c')) {
                    toUpdate.add(reqSet);
                }
            } catch (Exception e) {
                // Version__c field doesn't exist - ignore
            }
        }
        
        if (!toUpdate.isEmpty()) {
            updateDisplayLabels(toUpdate);
        }
    }
    
    /**
     * Updates Display_Label__c for requirement sets based on junction objects.
     * Called from Vendor_Program_Requirement_Set__c trigger when junction records change.
     */
    public static void updateDisplayLabelsFromJunction(
        List<Vendor_Program_Requirement_Set__c> junctions, 
        Map<Id, Vendor_Program_Requirement_Set__c> oldMap
    ) {
        if (isUpdatingDisplayLabel) {
            return; // Prevent recursion
        }
        
        Set<Id> requirementSetIds = new Set<Id>();
        
        if (junctions != null && !junctions.isEmpty()) {
            for (Vendor_Program_Requirement_Set__c junction : junctions) {
                if (junction.Onboarding_Requirement_Set__c != null) {
                    requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
                }
            }
        }
        
        // Also check old map for deleted records
        if (oldMap != null && !oldMap.isEmpty()) {
            for (Vendor_Program_Requirement_Set__c oldJunction : oldMap.values()) {
                if (oldJunction.Onboarding_Requirement_Set__c != null) {
                    requirementSetIds.add(oldJunction.Onboarding_Requirement_Set__c);
                }
            }
        }
        
        if (requirementSetIds.isEmpty()) {
            return;
        }
        
        List<Onboarding_Requirement_Set__c> requirementSets = [
            SELECT Id
            FROM Onboarding_Requirement_Set__c
            WHERE Id IN :requirementSetIds
        ];
        
        if (!requirementSets.isEmpty()) {
            updateDisplayLabels(requirementSets);
        }
    }
    
    /**
     * Updates Display_Label__c for requirement sets based on linked vendor programs via junction.
     * Formula: First Vendor Program Label + " Requirements - v" + Version (if exists)
     * If multiple vendor programs, uses first one alphabetically by Label.
     */
    private static void updateDisplayLabels(List<Onboarding_Requirement_Set__c> requirementSets) {
        if (requirementSets == null || requirementSets.isEmpty()) {
            return;
        }
        
        Set<Id> requirementSetIds = new Set<Id>();
        for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
            requirementSetIds.add(reqSet.Id);
        }
        
        // Get vendor programs linked via junction
        Map<Id, String> vendorProgramLabelByRequirementSet = new Map<Id, String>();
        
        for (Vendor_Program_Requirement_Set__c junction : [
            SELECT Onboarding_Requirement_Set__c, 
                   Vendor_Program__r.Label__c
            FROM Vendor_Program_Requirement_Set__c
            WHERE Onboarding_Requirement_Set__c IN :requirementSetIds
            ORDER BY Vendor_Program__r.Label__c ASC NULLS LAST
        ]) {
            // Store first vendor program label (sorted alphabetically)
            if (!vendorProgramLabelByRequirementSet.containsKey(junction.Onboarding_Requirement_Set__c) &&
                junction.Vendor_Program__r.Label__c != null) {
                vendorProgramLabelByRequirementSet.put(
                    junction.Onboarding_Requirement_Set__c, 
                    junction.Vendor_Program__r.Label__c
                );
            }
        }
        
        // Query requirement sets with Version__c if it exists
        List<Onboarding_Requirement_Set__c> reqSetsToUpdate = new List<Onboarding_Requirement_Set__c>();
        
        try {
            // Try to query with Version__c
            Map<Id, Onboarding_Requirement_Set__c> reqSetsMap = new Map<Id, Onboarding_Requirement_Set__c>([
                SELECT Id, Version__c
                FROM Onboarding_Requirement_Set__c
                WHERE Id IN :requirementSetIds
            ]);
            
            for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
                Onboarding_Requirement_Set__c fullReqSet = reqSetsMap.get(reqSet.Id);
                if (fullReqSet == null) {
                    continue;
                }
                
                String vendorProgramLabel = vendorProgramLabelByRequirementSet.get(reqSet.Id);
                String displayLabel = buildDisplayLabel(vendorProgramLabel, fullReqSet.Version__c);
                
                reqSet.Display_Label__c = displayLabel;
                reqSetsToUpdate.add(reqSet);
            }
        } catch (Exception e) {
            // Version__c field doesn't exist - build without version
            for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
                String vendorProgramLabel = vendorProgramLabelByRequirementSet.get(reqSet.Id);
                String displayLabel = buildDisplayLabel(vendorProgramLabel, null);
                
                reqSet.Display_Label__c = displayLabel;
                reqSetsToUpdate.add(reqSet);
            }
        }
        
        if (!reqSetsToUpdate.isEmpty()) {
            // Set flag to prevent recursion
            isUpdatingDisplayLabel = true;
            try {
                update reqSetsToUpdate;
            } finally {
                isUpdatingDisplayLabel = false;
            }
        }
    }
    
    /**
     * Builds the display label string.
     * Format: "Vendor Program Label Requirements - v{Version}" or "Requirements - v{Version}" if no vendor program
     * @param vendorProgramLabel The vendor program label (can be null)
     * @param version The version (can be Decimal, String, or null)
     */
    private static String buildDisplayLabel(String vendorProgramLabel, Object version) {
        String versionText = '1';
        
        if (version != null) {
            if (version instanceof Decimal) {
                versionText = String.valueOf((Decimal)version);
            } else if (version instanceof String) {
                String versionStr = (String)version;
                versionText = String.isNotBlank(versionStr) ? versionStr : '1';
            } else {
                versionText = String.valueOf(version);
            }
        }
        
        if (String.isNotBlank(vendorProgramLabel)) {
            return vendorProgramLabel + ' Requirements - v' + versionText;
        } else {
            return 'Requirements - v' + versionText;
        }
    }
}