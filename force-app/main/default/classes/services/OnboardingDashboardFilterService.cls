/**
 * Service for Onboarding Dashboard filter logic
 * Centralizes date range calculations and filter clause building
 */
public with sharing class OnboardingDashboardFilterService {

    /**
     * Gets the start date for a time filter
     * @param timeFilter Time filter value (LAST_30_DAYS, LAST_90_DAYS, YEAR_TO_DATE, ALL_TIME)
     * @return Start date or null for ALL_TIME
     */
    public static Date getDateRangeFilter(String timeFilter) {
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
     * Gets WHERE clause for view filter
     * @param viewFilter View filter value (MY_VIEW, MY_TEAM, ORG_WIDE)
     * @param currentUserId Current user ID
     * @return WHERE clause string (without WHERE keyword)
     */
    public static String getViewFilterClause(String viewFilter, Id currentUserId) {
        if (viewFilter == 'MY_VIEW' || String.isBlank(viewFilter)) {
            return 'CreatedById = :currentUserId';
        } else if (viewFilter == 'MY_TEAM') {
            // Get direct reports
            List<User> teamMembers = [SELECT Id FROM User WHERE ManagerId = :currentUserId];
            Set<Id> teamUserIds = new Set<Id>{ currentUserId };
            for (User u : teamMembers) {
                teamUserIds.add(u.Id);
            }
            return 'CreatedById IN :teamUserIds';
        }
        // ORG_WIDE: return empty string (no filter)
        return '';
    }

    /**
     * Builds a complete WHERE clause with all filters
     * @param timeFilter Time range filter
     * @param vendorIds List of vendor IDs to filter by
     * @param programIds List of vendor program IDs to filter by
     * @param viewFilter View filter
     * @param currentUserId Current user ID
     * @param baseClause Base WHERE clause (e.g., status filters)
     * @return Complete WHERE clause string
     */
    public static String buildFilterClause(
        String timeFilter,
        List<Id> vendorIds,
        List<Id> programIds,
        String viewFilter,
        Id currentUserId,
        String baseClause
    ) {
        List<String> clauses = new List<String>();
        
        // Add base clause
        if (String.isNotBlank(baseClause)) {
            clauses.add(baseClause);
        }
        
        // Add view filter
        String viewClause = getViewFilterClause(viewFilter, currentUserId);
        if (String.isNotBlank(viewClause)) {
            clauses.add(viewClause);
        }
        
        // Add time filter
        Date startDate = getDateRangeFilter(timeFilter);
        if (startDate != null) {
            clauses.add('CreatedDate >= :startDate');
        }
        
        // Add vendor filter
        if (vendorIds != null && !vendorIds.isEmpty()) {
            clauses.add('Vendor_Customization__r.Vendor__c IN :vendorIds');
        }
        
        // Add program filter
        if (programIds != null && !programIds.isEmpty()) {
            clauses.add('Vendor_Customization__c IN :programIds');
        }
        
        return String.join(clauses, ' AND ');
    }

    /**
     * Builds WHERE clause for LastModifiedDate filter (used for recent activity)
     * @param timeFilter Time range filter
     * @param vendorIds List of vendor IDs to filter by
     * @param programIds List of vendor program IDs to filter by
     * @param baseClause Base WHERE clause
     * @return Complete WHERE clause string
     */
    public static String buildLastModifiedFilterClause(
        String timeFilter,
        List<Id> vendorIds,
        List<Id> programIds,
        String baseClause
    ) {
        List<String> clauses = new List<String>();
        
        // Add base clause
        if (String.isNotBlank(baseClause)) {
            clauses.add(baseClause);
        }
        
        // Add time filter (using LastModifiedDate)
        Date startDate = getDateRangeFilter(timeFilter);
        if (startDate != null) {
            clauses.add('LastModifiedDate >= :startDate');
        }
        
        // Add vendor filter
        if (vendorIds != null && !vendorIds.isEmpty()) {
            clauses.add('Vendor_Customization__r.Vendor__c IN :vendorIds');
        }
        
        // Add program filter
        if (programIds != null && !programIds.isEmpty()) {
            clauses.add('Vendor_Customization__c IN :programIds');
        }
        
        return String.join(clauses, ' AND ');
    }
}

