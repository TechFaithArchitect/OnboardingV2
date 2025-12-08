/**
 * Service for Vendor Program domain operations
 * Handles all business logic related to Vendor_Customization__c records
 */
public with sharing class VendorProgramService {
    
    /**
     * Searches for vendor programs by name
     * @param vendorProgramName The vendor program name to search for
     * @return List of matching vendor programs
     */
    public static List<Vendor_Customization__c> searchVendorPrograms(String vendorProgramName) {
        return VendorOnboardingWizardRepository.searchVendorPrograms(vendorProgramName);
    }
    
    /**
     * Gets recent vendor programs
     * @param limitCount Maximum number of records to return
     * @return List of recent vendor programs
     */
    public static List<Vendor_Customization__c> getRecentVendorPrograms(Integer limitCount) {
        return VendorOnboardingWizardRepository.getRecentVendorPrograms(limitCount);
    }
    
    /**
     * Creates a new vendor program record
     * @param vendorProgram The vendor program record to create
     * @param vendorId The ID of the associated vendor
     * @return The ID of the created vendor program
     * @throws AuraHandledException if vendorProgram is null or vendorId is null
     */
    public static Id createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId) {
        ValidationHelper.requireRecord(vendorProgram, 'Vendor Program');
        ValidationHelper.requireId(vendorId, 'Vendor ID');
        
        vendorProgram.Vendor__c = vendorId;
        
        // Apply default values
        DefaultValueHelper.applyVendorProgramDefaults(vendorProgram);
        
        return VendorOnboardingWizardRepository.insertVendorProgram(vendorProgram);
    }
    
    /**
     * Finalizes a vendor program by linking it to groups
     * @param vendorProgramId The vendor program ID
     * @param vendorId The vendor ID
     * @param vendorProgramGroupId The vendor program group ID
     * @param vendorProgramRequirementGroupId The requirement group ID
     * @throws AuraHandledException if required IDs are null
     */
    public static void finalizeVendorProgram(
        Id vendorProgramId, 
        Id vendorId, 
        Id vendorProgramGroupId, 
        Id vendorProgramRequirementGroupId
    ) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        ValidationHelper.requireId(vendorId, 'Vendor ID');
        
        VendorOnboardingWizardRepository.linkVendorProgramToGroups(
            vendorProgramId,
            vendorId,
            vendorProgramGroupId,
            vendorProgramRequirementGroupId
        );
    }
    
    /**
     * Gets the vendor program group ID for a vendor program
     * @param vendorProgramId The vendor program ID
     * @return The vendor program group ID, or null if not found
     * @throws AuraHandledException if vendorProgramId is null
     */
    public static Id getVendorProgramGroupForVendorProgram(Id vendorProgramId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        return VendorOnboardingWizardRepository.getVendorProgramGroupForVendorProgram(vendorProgramId);
    }
    
    /**
     * Gets the requirement group ID for a vendor program
     * @param vendorProgramId The vendor program ID
     * @return The requirement group ID, or null if not found
     * @throws AuraHandledException if vendorProgramId is null
     */
    public static Id getVendorProgramRequirementGroupForVendorProgram(Id vendorProgramId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        return VendorOnboardingWizardRepository.getVendorProgramRequirementGroupForVendorProgram(vendorProgramId);
    }
}

