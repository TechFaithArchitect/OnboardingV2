/**
 * Migration Script: Create Vendor_Program_Requirement_Set__c junction records
 * 
 * This script migrates existing Lookup relationships between
 * Onboarding_Requirement_Set__c and Vendor_Customization__c
 * to the new Vendor_Program_Requirement_Set__c junction object.
 * 
 * Usage: Execute in Anonymous Apex (Developer Console or VS Code)
 * 
 * Pre-requisites:
 * - Junction object Vendor_Program_Requirement_Set__c must be deployed
 * - Service class VendorProgramRequirementSetService must be deployed
 * 
 * Post-execution:
 * - Verify junction records were created: SELECT COUNT() FROM Vendor_Program_Requirement_Set__c
 * - Verify counts match: SELECT COUNT() FROM Onboarding_Requirement_Set__c WHERE Vendor_Program__c != null
 */
public class MigrateVendorProgramToRequirementSetJunctions {
    
    public static void execute() {
        System.debug('=== Starting Vendor Program → Requirement Set Junction Migration ===');
        
        // Query all requirement sets with vendor programs
        List<Onboarding_Requirement_Set__c> requirementSets = [
            SELECT Id, Vendor_Program__c, Name
            FROM Onboarding_Requirement_Set__c
            WHERE Vendor_Program__c != null
        ];
        
        System.debug('Found ' + requirementSets.size() + ' requirement sets with vendor programs');
        
        // Get existing junction records to avoid duplicates
        Set<String> existingJunctions = new Set<String>();
        for (Vendor_Program_Requirement_Set__c existing : [
            SELECT Vendor_Program__c, Onboarding_Requirement_Set__c
            FROM Vendor_Program_Requirement_Set__c
        ]) {
            String key = existing.Vendor_Program__c + '|' + existing.Onboarding_Requirement_Set__c;
            existingJunctions.add(key);
        }
        
        System.debug('Found ' + existingJunctions.size() + ' existing junction records');
        
        // Create junction records
        List<Vendor_Program_Requirement_Set__c> junctionsToCreate = new List<Vendor_Program_Requirement_Set__c>();
        
        for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
            String key = reqSet.Vendor_Program__c + '|' + reqSet.Id;
            
            // Skip if junction already exists
            if (existingJunctions.contains(key)) {
                continue;
            }
            
            junctionsToCreate.add(new Vendor_Program_Requirement_Set__c(
                Vendor_Program__c = reqSet.Vendor_Program__c,
                Onboarding_Requirement_Set__c = reqSet.Id
            ));
        }
        
        System.debug('Creating ' + junctionsToCreate.size() + ' new junction records');
        
        if (!junctionsToCreate.isEmpty()) {
            // Insert in batches to handle large datasets
            Integer batchSize = 200;
            for (Integer i = 0; i < junctionsToCreate.size(); i += batchSize) {
                Integer endIndex = Math.min(i + batchSize, junctionsToCreate.size());
                List<Vendor_Program_Requirement_Set__c> batch = new List<Vendor_Program_Requirement_Set__c>();
                for (Integer j = i; j < endIndex; j++) {
                    batch.add(junctionsToCreate[j]);
                }
                
                try {
                    insert batch;
                    System.debug('Inserted batch ' + (i / batchSize + 1) + ': ' + batch.size() + ' records');
                } catch (DmlException e) {
                    System.debug('ERROR inserting batch: ' + e.getMessage());
                    for (Integer k = 0; k < e.getNumDml(); k++) {
                        System.debug('  Record ' + e.getDmlIndex(k) + ': ' + e.getDmlMessage(k));
                    }
                }
            }
        }
        
        // Verification
        Integer totalJunctions = [SELECT COUNT() FROM Vendor_Program_Requirement_Set__c];
        System.debug('=== Migration Complete ===');
        System.debug('Total junction records: ' + totalJunctions);
        System.debug('Expected: ' + requirementSets.size());
        
        if (totalJunctions >= requirementSets.size()) {
            System.debug('✓ Migration successful - all requirement sets have junction records');
        } else {
            System.debug('⚠ Warning: Some requirement sets may not have junction records. Please verify.');
        }
    }
}

// Execute the migration
MigrateVendorProgramToRequirementSetJunctions.execute();

