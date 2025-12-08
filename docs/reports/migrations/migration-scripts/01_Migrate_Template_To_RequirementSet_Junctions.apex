/**
 * Migration Script: Create Requirement_Set_Template__c junction records
 * 
 * This script migrates existing Master-Detail relationships between
 * Vendor_Program_Onboarding_Req_Template__c and Onboarding_Requirement_Set__c
 * to the new Requirement_Set_Template__c junction object.
 * 
 * Usage: Execute in Anonymous Apex (Developer Console or VS Code)
 * 
 * Pre-requisites:
 * - Junction object Requirement_Set_Template__c must be deployed
 * - Service class RequirementSetTemplateService must be deployed
 * 
 * Post-execution:
 * - Verify junction records were created: SELECT COUNT() FROM Requirement_Set_Template__c
 * - Verify counts match: SELECT COUNT() FROM Vendor_Program_Onboarding_Req_Template__c WHERE Onboarding_Requirement_Set__c != null
 */
public class MigrateTemplateToRequirementSetJunctions {
    
    public static void execute() {
        System.debug('=== Starting Template → Requirement Set Junction Migration ===');
        
        // Query all templates with requirement sets
        List<Vendor_Program_Onboarding_Req_Template__c> templates = [
            SELECT Id, Onboarding_Requirement_Set__c, Requirement_Label__c
            FROM Vendor_Program_Onboarding_Req_Template__c
            WHERE Onboarding_Requirement_Set__c != null
        ];
        
        System.debug('Found ' + templates.size() + ' templates with requirement sets');
        
        // Get existing junction records to avoid duplicates
        Set<String> existingJunctions = new Set<String>();
        for (Requirement_Set_Template__c existing : [
            SELECT Requirement_Template__c, Onboarding_Requirement_Set__c
            FROM Requirement_Set_Template__c
        ]) {
            String key = existing.Requirement_Template__c + '|' + existing.Onboarding_Requirement_Set__c;
            existingJunctions.add(key);
        }
        
        System.debug('Found ' + existingJunctions.size() + ' existing junction records');
        
        // Create junction records
        List<Requirement_Set_Template__c> junctionsToCreate = new List<Requirement_Set_Template__c>();
        
        for (Vendor_Program_Onboarding_Req_Template__c template : templates) {
            String key = template.Id + '|' + template.Onboarding_Requirement_Set__c;
            
            // Skip if junction already exists
            if (existingJunctions.contains(key)) {
                continue;
            }
            
            junctionsToCreate.add(new Requirement_Set_Template__c(
                Requirement_Template__c = template.Id,
                Onboarding_Requirement_Set__c = template.Onboarding_Requirement_Set__c
            ));
        }
        
        System.debug('Creating ' + junctionsToCreate.size() + ' new junction records');
        
        if (!junctionsToCreate.isEmpty()) {
            // Insert in batches to handle large datasets
            Integer batchSize = 200;
            for (Integer i = 0; i < junctionsToCreate.size(); i += batchSize) {
                Integer endIndex = Math.min(i + batchSize, junctionsToCreate.size());
                List<Requirement_Set_Template__c> batch = new List<Requirement_Set_Template__c>();
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
        Integer totalJunctions = [SELECT COUNT() FROM Requirement_Set_Template__c];
        System.debug('=== Migration Complete ===');
        System.debug('Total junction records: ' + totalJunctions);
        System.debug('Expected: ' + templates.size());
        
        if (totalJunctions >= templates.size()) {
            System.debug('✓ Migration successful - all templates have junction records');
        } else {
            System.debug('⚠ Warning: Some templates may not have junction records. Please verify.');
        }
    }
}

// Execute the migration
MigrateTemplateToRequirementSetJunctions.execute();

