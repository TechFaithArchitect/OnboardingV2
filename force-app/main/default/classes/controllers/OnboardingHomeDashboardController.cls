/**
 * Controller for Onboarding Home Dashboard LWC component
 * Provides data for the dashboard interface showing user's onboarding records
 */
public with sharing class OnboardingHomeDashboardController {

    /**
     * Get active onboarding records for the current user
     * Uses CreatedBy to show records created by user, respecting Account sharing
     * Since Onboarding__c is Master-Detail to Account, sharing is controlled by Account access
     * 
     * @param timeFilter Time range filter (LAST_30_DAYS, LAST_90_DAYS, YEAR_TO_DATE, ALL_TIME) - optional, defaults to LAST_90_DAYS
     * @param vendorIds List of vendor IDs to filter by (optional)
     * @param programIds List of vendor program IDs to filter by (optional)
     * @param viewFilter View filter (MY_VIEW, MY_TEAM, ORG_WIDE) - optional, defaults to MY_VIEW
     */
    @AuraEnabled(cacheable=true)
    public static List<OnboardingDTO> getMyActiveOnboarding(
        String timeFilter, 
        List<Id> vendorIds, 
        List<Id> programIds,
        String viewFilter
    ) {
        // Handle null/empty parameters
        if (String.isBlank(timeFilter)) {
            timeFilter = 'LAST_90_DAYS';
        }
        if (String.isBlank(viewFilter)) {
            viewFilter = 'MY_VIEW';
        }
        // Resolve which users should be treated as onboarding owners for this view.
        Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter(viewFilter);
        Date startDate = getStartDateForFilter(timeFilter);
        
        // Use repository to get filtered onboarding records
        List<Onboarding__c> onboardings = OnboardingRepository.getActiveOnboardingWithFilters(
            ownerUserIds,
            startDate,
            vendorIds,
            programIds,
            20
        );
        
        // Transform to DTOs
        List<OnboardingDTO> results = new List<OnboardingDTO>();
        for (Onboarding__c ob : onboardings) {
            results.add(new OnboardingDTO(ob));
        }
        
        return results;
    }

    /**
     * Get summary statistics for onboarding records
     * Uses CreatedById to show records created by user
     * 
     * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
     * @param vendorIds List of vendor IDs to filter by (optional)
     * @param programIds List of vendor program IDs to filter by (optional)
     * @param viewFilter View filter (MY_VIEW, MY_TEAM, ORG_WIDE) - optional, defaults to MY_VIEW
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getOnboardingSummary(
        String timeFilter, 
        List<Id> vendorIds, 
        List<Id> programIds,
        String viewFilter
    ) {
        // Handle null/empty parameters
        if (String.isBlank(timeFilter)) {
            timeFilter = 'LAST_90_DAYS';
        }
        if (String.isBlank(viewFilter)) {
            viewFilter = 'MY_VIEW';
        }
        
        // Resolve owners for summary view
        Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter(viewFilter);
        Date startDate = getStartDateForFilter(timeFilter);
        
        // Use repository to get filtered summary statistics
        return OnboardingRepository.getOnboardingSummaryWithFilters(
            ownerUserIds,
            startDate,
            vendorIds,
            programIds
        );
    }

    /**
     * Get eligible accounts that can start new onboarding
     * 
     * @param timeFilter Time range filter (optional, not currently used for eligible accounts)
     * @param vendorIds List of vendor IDs to filter by (optional)
     * @param programIds List of vendor program IDs to filter by (optional)
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountDTO> getEligibleAccounts(
        String timeFilter, 
        List<Id> vendorIds, 
        List<Id> programIds
    ) {
        // timeFilter parameter is accepted but not currently used for eligible accounts
        List<AccountDTO> results = new List<AccountDTO>();
        
        // Get accounts using repository
        List<Account> accounts = AccountRepository.getAccountsForOnboarding(50);
        
        // For each account, check if there are eligible vendors
        List<Id> accountIds = new List<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        if (!accountIds.isEmpty()) {
            try {
                Map<Id, Integer> accountToVendorCount = OnboardingEligibilityService.getEligibleVendorCountsByAccount(
                    accountIds,
                    vendorIds,
                    programIds
                );
                
                // Build DTOs for accounts with eligible vendors
                for (Account acc : accounts) {
                    Integer eligibleCount = accountToVendorCount.get(acc.Id);
                    if (eligibleCount != null && eligibleCount > 0) {
                        AccountDTO dto = new AccountDTO();
                        dto.Id = acc.Id;
                        dto.Name = acc.Name;
                        dto.Territory = acc.Territory__c;
                        dto.Region = acc.Region__c;
                        dto.EligibleVendorCount = eligibleCount;
                        dto.RecordUrl = '/' + acc.Id;
                        results.add(dto);
                    }
                }
            } catch (Exception e) {
                // Log error and return empty list if service fails
                System.debug('Error getting eligible accounts: ' + e.getMessage());
            }
        }
        
        return results;
    }

    /**
     * Get recent onboarding activity
     * Uses CreatedById to show records created by user
     * 
     * @param recordLimit Maximum number of records to return - optional, defaults to 10
     * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
     * @param vendorIds List of vendor IDs to filter by (optional)
     * @param programIds List of vendor program IDs to filter by (optional)
     */
    @AuraEnabled(cacheable=true)
    public static List<OnboardingDTO> getRecentActivity(
        Integer recordLimit, 
        String timeFilter, 
        List<Id> vendorIds, 
        List<Id> programIds
    ) {
        // Handle null/empty parameters
        if (String.isBlank(timeFilter)) {
            timeFilter = 'LAST_90_DAYS';
        }
        
        Integer limitValue = recordLimit != null && recordLimit > 0 ? recordLimit : 10;
        Date startDate = getStartDateForFilter(timeFilter);
        // Recent activity uses MY_VIEW (current user only)
        Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter('MY_VIEW');
        
        // Use repository to get filtered recent activity
        List<Onboarding__c> onboardings = OnboardingRepository.getRecentOnboardingWithFilters(
            ownerUserIds,
            startDate,
            vendorIds,
            programIds,
            limitValue
        );
        
        // Transform to DTOs
        List<OnboardingDTO> results = new List<OnboardingDTO>();
        for (Onboarding__c ob : onboardings) {
            results.add(new OnboardingDTO(ob));
        }
        
        return results;
    }
    
    /**
     * Helper method to get start date for time filter
     */
    private static Date getStartDateForFilter(String timeFilter) {
        if (String.isBlank(timeFilter)) {
            return null;
        }
        
        Date today = Date.today();
        if (timeFilter == 'LAST_30_DAYS') {
            return today.addDays(-30);
        } else if (timeFilter == 'LAST_90_DAYS') {
            return today.addDays(-90);
        } else if (timeFilter == 'YEAR_TO_DATE') {
            return Date.newInstance(today.year(), 1, 1);
        } else if (timeFilter == 'ALL_TIME') {
            return null;
        }
        
        // Default to last 90 days
        return today.addDays(-90);
    }

    /**
     * Get all active onboarding records (not just user's)
     * Useful for admins/managers
     * Sharing is controlled by Account parent (ControlledByParent)
     */
    @AuraEnabled(cacheable=true)
    public static List<OnboardingDTO> getAllActiveOnboarding() {
        List<Onboarding__c> onboardings = OnboardingRepository.getAllActiveOnboarding(50);
        
        List<OnboardingDTO> results = new List<OnboardingDTO>();
        for (Onboarding__c ob : onboardings) {
            results.add(new OnboardingDTO(ob));
        }
        
        return results;
    }

    /**
     * Get vendor program health metrics
     * Returns metrics for all active vendor programs or filtered by vendor IDs
     * 
     * @param timeFilter Time range filter for onboarding counts - optional, defaults to LAST_90_DAYS
     * @param vendorIds List of vendor IDs to filter by (optional)
     * @return List of VendorProgramMetricsDTO
     */
    @AuraEnabled(cacheable=true)
    public static List<VendorProgramMetricsDTO> getVendorProgramMetrics(
        String timeFilter, 
        List<Id> vendorIds
    ) {
        // Handle null/empty parameters
        if (String.isBlank(timeFilter)) {
            timeFilter = 'LAST_90_DAYS';
        }
        
        Date startDate = getStartDateForFilter(timeFilter);
        
        // Build WHERE clause for vendor programs
        String whereClause = 'Active__c = true';
        if (vendorIds != null && !vendorIds.isEmpty()) {
            whereClause += ' AND Vendor__c IN :vendorIds';
        }
        
        // Query vendor programs
        String query = 'SELECT Id, Name, Label__c, Vendor__c, Vendor__r.Name, Status__c, Active__c ' +
                      'FROM Vendor_Customization__c WHERE ' + whereClause + ' ORDER BY Name';
        
        List<Vendor_Customization__c> programs = Database.query(query);
        
        if (programs.isEmpty()) {
            return new List<VendorProgramMetricsDTO>();
        }
        
        Set<Id> programIds = new Set<Id>();
        for (Vendor_Customization__c prog : programs) {
            programIds.add(prog.Id);
        }
        
        // Get onboarding counts
        String onboardingWhere = 'Vendor_Customization__c IN :programIds';
        if (startDate != null) {
            onboardingWhere += ' AND CreatedDate >= :startDate';
        }
        
        // Count by status
        Map<Id, Map<String, Integer>> countsByProgram = new Map<Id, Map<String, Integer>>();
        String countQuery = 'SELECT Vendor_Customization__c, Onboarding_Status__c, COUNT(Id) cnt ' +
                           'FROM Onboarding__c WHERE ' + onboardingWhere + 
                           ' GROUP BY Vendor_Customization__c, Onboarding_Status__c';
        
        for (AggregateResult ar : Database.query(countQuery)) {
            Id programId = (Id) ar.get('Vendor_Customization__c');
            String status = (String) ar.get('Onboarding_Status__c');
            Integer count = (Integer) ar.get('cnt');
            
            if (!countsByProgram.containsKey(programId)) {
                countsByProgram.put(programId, new Map<String, Integer>());
            }
            countsByProgram.get(programId).put(status, count);
        }
        
        // Get requirement counts (simplified - would need to query Vendor_Program_Requirement__c)
        // For now, we'll set placeholder values
        
        // Build DTOs
        List<VendorProgramMetricsDTO> results = new List<VendorProgramMetricsDTO>();
        for (Vendor_Customization__c prog : programs) {
            VendorProgramMetricsDTO dto = new VendorProgramMetricsDTO();
            dto.Id = prog.Id;
            dto.Name = prog.Name;
            dto.Label = prog.Label__c;
            dto.VendorId = prog.Vendor__c;
            dto.VendorName = prog.Vendor__r != null ? prog.Vendor__r.Name : null;
            dto.Status = prog.Status__c;
            dto.Active = prog.Active__c;
            dto.RecordUrl = '/' + prog.Id;
            
            Map<String, Integer> counts = countsByProgram.get(prog.Id);
            if (counts != null) {
                dto.DealersOnboarded = counts.get('Setup Complete') != null ? counts.get('Setup Complete') : 0;
                dto.InProgressCount = 0;
                for (String status : counts.keySet()) {
                    if (status != 'Setup Complete' && status != 'Denied' && status != 'Expired') {
                        dto.InProgressCount += counts.get(status);
                    }
                }
                dto.BlockedCount = counts.get('Denied') != null ? counts.get('Denied') : 0;
            }
            
            // TODO: Add requirement counts and validation checks
            dto.TotalRequirements = 0;
            dto.CompleteRequirements = 0;
            dto.RulesEngineValid = true;
            dto.DependenciesValid = true;
            dto.GroupNames = new List<String>();
            
            results.add(dto);
        }
        
        return results;
    }

    /**
     * Get count of blocked/at-risk onboarding records
     * 
     * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
     * @param vendorIds List of vendor IDs to filter by (optional)
     * @param programIds List of vendor program IDs to filter by (optional)
     * @return Count of blocked/at-risk onboarding records
     */
    @AuraEnabled(cacheable=true)
    public static Integer getBlockedOnboardingCount(
        String timeFilter,
        List<Id> vendorIds,
        List<Id> programIds
    ) {
        // Handle null/empty parameters
        if (String.isBlank(timeFilter)) {
            timeFilter = 'LAST_90_DAYS';
        }
        
        Date startDate = getStartDateForFilter(timeFilter);
        
        // Build WHERE clause for active onboarding
        String whereClause = 'Onboarding_Status__c != \'Complete\' AND Onboarding_Status__c != \'Expired\'';
        
        if (startDate != null) {
            whereClause += ' AND CreatedDate >= :startDate';
        }
        
        if (vendorIds != null && !vendorIds.isEmpty()) {
            whereClause += ' AND Vendor_Customization__r.Vendor__c IN :vendorIds';
        }
        
        if (programIds != null && !programIds.isEmpty()) {
            whereClause += ' AND Vendor_Customization__c IN :programIds';
        }
        
        // Query onboarding records with requirements
        String query = 'SELECT Id, Onboarding_Status__c, Vendor_Customization__c ' +
                      'FROM Onboarding__c WHERE ' + whereClause;
        
        List<Onboarding__c> onboardings = Database.query(query);
        
        if (onboardings.isEmpty()) {
            return 0;
        }
        
        Set<Id> onboardingIds = new Set<Id>();
        for (Onboarding__c ob : onboardings) {
            onboardingIds.add(ob.Id);
        }
        
        // Check for blocked onboarding (has requirements with Denied/Incomplete status)
        // This is a simplified check - full implementation would use OnboardingBlockingDetectionService
        Integer blockedCount = 0;
        
        // Query requirements with problematic statuses
        // Use AggregateResult since we're using GROUP BY
        List<AggregateResult> blockedReqs = [
            SELECT Onboarding__c
            FROM Onboarding_Requirement__c
            WHERE Onboarding__c IN :onboardingIds
                  AND Status__c IN ('Denied', 'Incomplete')
            GROUP BY Onboarding__c
        ];
        
        blockedCount = blockedReqs.size();
        
        // Also count onboarding with Denied status
        for (Onboarding__c ob : onboardings) {
            if (ob.Onboarding_Status__c == 'Denied') {
                blockedCount++;
            }
        }
        
        return blockedCount;
    }

    /**
     * Get team/org onboarding queue
     * 
     * @param viewFilter View filter (MY_TEAM, ORG_WIDE) - optional, defaults to MY_TEAM
     * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
     * @param vendorIds List of vendor IDs to filter by (optional)
     * @param programIds List of vendor program IDs to filter by (optional)
     * @return List of OnboardingDTO
     */
    @AuraEnabled(cacheable=true)
    public static List<OnboardingDTO> getTeamOnboarding(
        String viewFilter,
        String timeFilter,
        List<Id> vendorIds,
        List<Id> programIds
    ) {
        // Handle null/empty parameters
        if (String.isBlank(viewFilter)) {
            viewFilter = 'MY_TEAM';
        }
        if (String.isBlank(timeFilter)) {
            timeFilter = 'LAST_90_DAYS';
        }
        
        Date startDate = getStartDateForFilter(timeFilter);
        Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter(viewFilter);
        
        // Use repository to get filtered team onboarding records
        List<Onboarding__c> onboardings = OnboardingRepository.getActiveOnboardingWithFilters(
            ownerUserIds,
            startDate,
            vendorIds,
            programIds,
            50
        );
        
        // Transform to DTOs
        List<OnboardingDTO> results = new List<OnboardingDTO>();
        for (Onboarding__c ob : onboardings) {
            results.add(new OnboardingDTO(ob));
        }
        
        return results;
    }

    /**
     * Get onboarding records with blocking information
     * Adds blocking reasons and at-risk indicators to onboarding DTOs
     * 
     * @param onboardingIds List of onboarding IDs to check
     * @return List of OnboardingWithBlockingDTO
     */
    @AuraEnabled(cacheable=true)
    public static List<OnboardingWithBlockingDTO> getOnboardingWithBlockingInfo(List<Id> onboardingIds) {
        if (onboardingIds == null || onboardingIds.isEmpty()) {
            return new List<OnboardingWithBlockingDTO>();
        }
        
        // Query onboarding records
        List<Onboarding__c> onboardings = [
            SELECT Id, Name, Onboarding_Status__c, Account__c, Account__r.Name,
                   Vendor_Customization__c, Vendor_Customization__r.Name,
                   CreatedDate, LastModifiedDate, CreatedById, CreatedBy.Name
            FROM Onboarding__c
            WHERE Id IN :onboardingIds
        ];
        
        // Query requirements to check for blocking
        List<Onboarding_Requirement__c> requirements = [
            SELECT Id, Onboarding__c, Status__c, Vendor_Program_Requirement__c
            FROM Onboarding_Requirement__c
            WHERE Onboarding__c IN :onboardingIds
        ];
        
        // Build map of onboarding to requirements
        Map<Id, List<Onboarding_Requirement__c>> reqsByOnboarding = new Map<Id, List<Onboarding_Requirement__c>>();
        for (Onboarding_Requirement__c req : requirements) {
            if (!reqsByOnboarding.containsKey(req.Onboarding__c)) {
                reqsByOnboarding.put(req.Onboarding__c, new List<Onboarding_Requirement__c>());
            }
            reqsByOnboarding.get(req.Onboarding__c).add(req);
        }
        
        // Build DTOs with blocking info
        List<OnboardingWithBlockingDTO> results = new List<OnboardingWithBlockingDTO>();
        for (Onboarding__c ob : onboardings) {
            OnboardingWithBlockingDTO dto = new OnboardingWithBlockingDTO(ob);
            
            // Check for blocked requirements
            List<Onboarding_Requirement__c> reqs = reqsByOnboarding.get(ob.Id);
            if (reqs != null) {
                for (Onboarding_Requirement__c req : reqs) {
                    if (req.Status__c == 'Denied') {
                        dto.IsBlocked = true;
                        dto.BlockingReasons.add('Requirement denied: ' + req.Id);
                    } else if (req.Status__c == 'Incomplete') {
                        // Check if it's been incomplete for more than 7 days (at risk)
                        if (ob.CreatedDate != null) {
                            Integer daysSinceCreated = ob.CreatedDate.date().daysBetween(Date.today());
                            if (daysSinceCreated > 7) {
                                dto.IsAtRisk = true;
                                dto.BlockingReasons.add('Requirement incomplete for ' + daysSinceCreated + ' days');
                            }
                        }
                    }
                }
            }
            
            // Check if status is Denied
            if (ob.Onboarding_Status__c == 'Denied') {
                dto.IsBlocked = true;
                dto.BlockingReasons.add('Onboarding status is Denied');
            }
            
            results.add(dto);
        }
        
        return results;
    }

    /**
     * Gets all vendors with their associated vendor programs for hierarchical display.
     * Returns data structured for lightning-tree-grid component.
     */
    @AuraEnabled(cacheable=true)
    public static List<VendorHierarchyDTO> getVendorsWithPrograms() {
        List<Vendor__c> vendors = VendorOnboardingWizardService.getVendorsWithPrograms();
        return buildVendorHierarchy(vendors);
    }

    /**
     * Searches vendors with programs by name.
     */
    @AuraEnabled(cacheable=true)
    public static List<VendorHierarchyDTO> searchVendorsWithPrograms(String searchText) {
        List<Vendor__c> vendors = VendorOnboardingWizardService.searchVendorsWithPrograms(searchText);
        return buildVendorHierarchy(vendors);
    }

    /**
     * Builds hierarchical DTO structure for tree-grid display.
     */
    private static List<VendorHierarchyDTO> buildVendorHierarchy(List<Vendor__c> vendors) {
        List<VendorHierarchyDTO> hierarchy = new List<VendorHierarchyDTO>();
        
        for (Vendor__c vendor : vendors) {
            VendorHierarchyDTO vendorDTO = new VendorHierarchyDTO();
            vendorDTO.id = vendor.Id;
            vendorDTO.name = vendor.Name;
            vendorDTO.recordType = 'vendor';
            vendorDTO.status = vendor.Active__c ? 'Active' : 'Inactive';
            vendorDTO.programCount = vendor.Vendor_Customizations__r != null ? vendor.Vendor_Customizations__r.size() : 0;
            vendorDTO.createdDate = vendor.CreatedDate;
            vendorDTO.lastModifiedDate = vendor.LastModifiedDate;
            vendorDTO.children = new List<VendorHierarchyDTO>();
            
            // Add vendor programs as children
            if (vendor.Vendor_Customizations__r != null && !vendor.Vendor_Customizations__r.isEmpty()) {
                for (Vendor_Customization__c program : vendor.Vendor_Customizations__r) {
                    VendorHierarchyDTO programDTO = new VendorHierarchyDTO();
                    programDTO.id = program.Id;
                    programDTO.name = program.Name;
                    programDTO.label = program.Label__c;
                    programDTO.recordType = 'program';
                    programDTO.status = program.Status__c != null ? program.Status__c : 'Draft';
                    programDTO.active = program.Active__c;
                    programDTO.retailOption = program.Retail_Option__c;
                    programDTO.businessVertical = program.Business_Vertical__c;
                    programDTO.createdDate = program.CreatedDate;
                    programDTO.lastModifiedDate = program.LastModifiedDate;
                    programDTO.lastModifiedBy = program.LastModifiedBy != null ? program.LastModifiedBy.Name : null;
                    programDTO.parentId = vendor.Id;
                    programDTO.children = null; // Programs are leaf nodes
                    
                    vendorDTO.children.add(programDTO);
                }
            }
            
            hierarchy.add(vendorDTO);
        }
        
        return hierarchy;
    }

    /**
     * Get list of active vendors for filter dropdown
     * @return List of vendor options with label and value
     */
    @AuraEnabled(cacheable=true)
    public static List<FilterOption> getVendors() {
        List<FilterOption> results = new List<FilterOption>();
        
        List<Vendor__c> vendors = [
            SELECT Id, Name
            FROM Vendor__c
            WHERE Active__c = true
            ORDER BY Name
            LIMIT 1000
        ];
        
        for (Vendor__c vendor : vendors) {
            FilterOption option = new FilterOption();
            option.label = vendor.Name;
            option.value = vendor.Id;
            results.add(option);
        }
        
        return results;
    }

    /**
     * Get list of active vendor programs for filter dropdown
     * @return List of vendor program options with label and value
     */
    @AuraEnabled(cacheable=true)
    public static List<FilterOption> getVendorPrograms() {
        List<FilterOption> results = new List<FilterOption>();
        
        List<Vendor_Customization__c> programs = [
            SELECT Id, Name, Label__c, Vendor__r.Name
            FROM Vendor_Customization__c
            WHERE Active__c = true
            ORDER BY Name
            LIMIT 1000
        ];
        
        for (Vendor_Customization__c program : programs) {
            FilterOption option = new FilterOption();
            String displayName = String.isNotBlank(program.Label__c) ? program.Label__c : program.Name;
            if (program.Vendor__r != null && String.isNotBlank(program.Vendor__r.Name)) {
                displayName += ' (' + program.Vendor__r.Name + ')';
            }
            option.label = displayName;
            option.value = program.Id;
            results.add(option);
        }
        
        return results;
    }

    /**
     * DTO for filter dropdown options
     */
    public class FilterOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    /**
     * DTO for vendor hierarchy structure (vendor with nested programs)
     */
    public class VendorHierarchyDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String recordType; // 'vendor' or 'program'
        @AuraEnabled public String status;
        @AuraEnabled public Boolean active;
        @AuraEnabled public Integer programCount;
        @AuraEnabled public String retailOption;
        @AuraEnabled public String businessVertical;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public DateTime lastModifiedDate;
        @AuraEnabled public String lastModifiedBy;
        @AuraEnabled public String parentId;
        @AuraEnabled public List<VendorHierarchyDTO> children; // Note: Apex doesn't allow _ prefix, will map to _children in JS
    }
}
