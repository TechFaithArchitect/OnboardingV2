/**
 * Service for resolving "ownership" and visibility for Onboarding__c records.
 *
 * This is intentionally separate from the LWC controller so that:
 * - Ownership rules are defined in one place.
 * - Other entry points (flows, actions, jobs) can reuse the same logic.
 * - Controllers stay thin and delegate business logic to services.
 *
 * ## Ownership Model
 *
 * Onboarding__c is Master-Detail to Account__c, so record-level sharing is
 * controlled by Account. However, for the dashboard we treat multiple users
 * as "owners" of an onboarding:
 *
 * 1. **Account Owner**
 *    - `Account__r.OwnerId` is always considered an owner.
 *
 * 2. **Onboarding Reps via Territory_Assignments__c**
 *    - Territory_Assignments__c links to Account__c through Zip Code Territory junction:
 *        - Territory_Assignments__c → Zip_Code_Territory__c → Zip_Code__c
 *        - Then query Accounts WHERE Zip_Code__c IN :zipCodeIds (Account has lookup TO Zip Code)
 *    - It has user lookups such as:
 *        - `Onboarding_Rep__c`
 *        - `Base_App_OB_Rep__c`
 *    - Any user referenced in those fields for a Territory Assignment is considered
 *      an "onboarding owner" for Accounts linked via Zip Codes in that territory.
 *
 * 3. **Territory_Role_Assignment__c (User-centric view)**
 *    - Territory_Role_Assignment__c is kept in sync with
 *      Territory_Assignments__c via Apex and is used primarily for
 *      user-centric selection and reporting.
 *    - The dashboard's ownership checks are Account-centric, so the SOQL
 *      owner clause uses Territory_Assignments__c (Account → Users).
 *      Territory_Role_Assignment__c remains the system-of-record for
 *      user-facing configuration but is not directly queried here.
 *
 * ## View Filters
 *
 * The dashboard supports three view filters that map to sets of user Ids:
 *
 * - `MY_VIEW`  : only the current user
 * - `MY_TEAM`  : current user + all users in their role hierarchy subtree
 * - `ORG_WIDE` : no owner filter; caller sees all records allowed by sharing
 *
 * The public methods in this service expose two concepts:
 *
 * - A **set of user Ids** to be treated as "owners" for a view filter.
 * - A **SOQL WHERE clause fragment** that can be appended to an
 *   `Onboarding__c` query to enforce those ownership rules.
 */
public with sharing class OnboardingAccessService {

    /**
     * Returns the user Ids that should be treated as owners for the given
     * view filter.
     *
     * Ownership rules:
     * - MY_VIEW:   only the current user's Id.
     * - MY_TEAM:   current user + all users in their role hierarchy subtree.
     * - ORG_WIDE:  empty set (no owner filter will be applied).
     *
     * @param viewFilter One of 'MY_VIEW', 'MY_TEAM', 'ORG_WIDE'. Null/blank
     *                   defaults to 'MY_VIEW'.
     * @return Set of User Ids representing owners for this view.
     */
    public static Set<Id> getUserIdsForViewFilter(String viewFilter) {
        String effectiveFilter = String.isBlank(viewFilter) ? 'MY_VIEW' : viewFilter;
        Id currentUserId = UserInfo.getUserId();

        if (effectiveFilter == 'ORG_WIDE') {
            // Empty set signals that no owner filter should be applied.
            return new Set<Id>();
        }

        if (effectiveFilter == 'MY_TEAM') {
            return getUsersInRoleHierarchy(currentUserId);
        }

        // Default: MY_VIEW
        return new Set<Id>{ currentUserId };
    }

    /**
     * Returns the set of Account IDs that should be considered "owned" by the
     * given user IDs, based on Account ownership and territory assignments.
     *
     * This method avoids SOQL subquery limitations by querying through junction objects
     * separately and combining the results with Account owner checks.
     *
     * An Account is considered "owned" if:
     * 1. The Account's OwnerId is in the userIds set, OR
     * 2. The Account is linked via Zip Code to a Territory Assignment where either:
     *    - Onboarding_Rep__c is in userIds, OR
     *    - Base_App_OB_Rep__c is in userIds
     *    
     *    Path: Territory_Assignments__c → Zip_Code_Territory__c → Zip_Code__c
 *    Then: Accounts WHERE Zip_Code__c IN :zipCodeIds
     *
     * @param userIds Set of User Ids to treat as owners.
     * @return Set of Account IDs that are owned by the specified users.
     *         Returns empty set if userIds is null/empty.
     */
    public static Set<Id> getAccountIdsForOwners(Set<Id> userIds) {
        Set<Id> accountIds = new Set<Id>();
        
        if (userIds == null || userIds.isEmpty()) {
            return accountIds;
        }

        // Performance Optimization: Combine Account owner query with bulk collection
        // Get Accounts where the owner is in the userIds set
        for (Account acc : [
            SELECT Id
            FROM Account
            WHERE OwnerId IN :userIds
            LIMIT 10000
        ]) {
            accountIds.add(acc.Id);
        }

        // Get Accounts from Territory_Assignments__c via Zip Code Territory junction
        // Path: Territory_Assignments__c → Zip_Code_Territory__c → Zip_Code__c
        // Then query Accounts WHERE Zip_Code__c IN :zipCodeIds (Account has lookup TO Zip Code)
        // Performance Optimization: Single query with bulk collection
        Set<Id> territoryAssignmentIds = new Set<Id>();
        for (Territory_Assignments__c ta : [
            SELECT Id
            FROM Territory_Assignments__c
            WHERE Onboarding_Rep__c IN :userIds 
               OR Base_App_OB_Rep__c IN :userIds
            LIMIT 10000
        ]) {
            territoryAssignmentIds.add(ta.Id);
        }
        
        // Early exit if no territory assignments found
        if (territoryAssignmentIds.isEmpty()) {
            return accountIds;
        }
        
        // Performance Optimization: Single query to get all Zip Code IDs
        Set<Id> zipCodeIds = new Set<Id>();
        for (Zip_Code_Territory__c junction : [
            SELECT Zip_Code__c
            FROM Zip_Code_Territory__c
            WHERE Territory_Assignments__c IN :territoryAssignmentIds
              AND Zip_Code__c != null
            LIMIT 10000
        ]) {
            zipCodeIds.add(junction.Zip_Code__c);
        }
        
        // Early exit if no zip codes found
        if (zipCodeIds.isEmpty()) {
            return accountIds;
        }
        
        // Performance Optimization: Query Accounts directly via Zip Code lookup
        // Account, Contact, Lead have lookup fields TO Zip Code (Account.Zip_Code__c)
        // So 1 Zip Code can have many Accounts, Contacts, Leads
        // Also handles deduplication automatically via Set
        for (Account acc : [
            SELECT Id
            FROM Account
            WHERE Zip_Code__c IN :zipCodeIds
            LIMIT 10000
        ]) {
            accountIds.add(acc.Id);
        }

        return accountIds;
    }

    /**
     * Builds a SOQL WHERE clause fragment that enforces ownership for
     * Onboarding__c records based on Account ownership and territory
     * onboarding reps.
     *
     * @deprecated This method uses a subquery which causes SOQL errors when
     * combined with other WHERE conditions. Use getAccountIdsForOwners() instead
     * and filter by Account__c IN :accountIds.
     *
     * @param userIds Set of User Ids to treat as owners.
     * @return SOQL WHERE fragment (deprecated - may cause nested subquery errors).
     */
    public static String buildOwnerClauseForOnboarding(Set<Id> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return '';
        }

        // NOTE: This method is deprecated because it creates nested subqueries
        // that violate SOQL limitations. Use getAccountIdsForOwners() instead.
        // 
        // NOTE: This deprecated method cannot properly traverse junction objects in SOQL.
        // The path would be: Territory_Assignments__c → Zip_Code_Territory__c → Zip_Code__c
        // Then: Accounts WHERE Zip_Code__c IN :zipCodeIds
        // which requires multiple queries that cannot be expressed in a single SOQL subquery.
        // Use getAccountIdsForOwners() which handles the junction traversal properly.
        return '(Account__r.OwnerId IN :userIds)';
    }

    /**
     * Returns all users in the current user's role hierarchy subtree,
     * including the user themself.
     *
     * This is used to power the `MY_TEAM` view:
     * - Starting from the current user's UserRoleId
     * - Traverse child roles recursively
     * - Collect all users whose UserRoleId is in that set of roles
     *
     * @param userId The root user for the hierarchy (usually current user).
     * @return Set of user Ids including the root user and all users in
     *         descendant roles.
     */
    @TestVisible
    private static Set<Id> getUsersInRoleHierarchy(Id userId) {
        Set<Id> roleIds = new Set<Id>();

        // Get the starting role for the user (if any)
        User user = [
            SELECT UserRoleId
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];

        if (user.UserRoleId != null) {
            Set<Id> toProcess = new Set<Id>{ user.UserRoleId };
            while (!toProcess.isEmpty()) {
                roleIds.addAll(toProcess);

                // Get direct child roles for the current batch.
                List<UserRole> children = [
                    SELECT Id
                    FROM UserRole
                    WHERE ParentRoleId IN :toProcess
                ];

                toProcess = new Set<Id>();
                for (UserRole child : children) {
                    toProcess.add(child.Id);
                }
            }
        }

        // Collect all users in the role hierarchy, including the root user.
        Set<Id> userIds = new Set<Id>{ userId };
        if (!roleIds.isEmpty()) {
            for (User usr : [
                SELECT Id
                FROM User
                WHERE UserRoleId IN :roleIds
            ]) {
                userIds.add(usr.Id);
            }
        }

        return userIds;
    }

    /**
     * Checks if the current user has System Administrator access.
     * 
     * A user is considered an admin if they have:
     * 1. System Administrator profile, OR
     * 2. Customize Application permission (typically admin-level)
     * 
     * @return Boolean indicating if current user is an admin
     */
    public static Boolean isCurrentUserAdmin() {
        // Check if user is System Administrator
        Profile userProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        if (userProfile.Name == 'System Administrator') {
            return true;
        }
        
        // Check for Customize Application permission (typically admin-level)
        try {
            PermissionSetAssignment[] assignments = [
                SELECT PermissionSet.PermissionsCustomizeApplication
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
                  AND PermissionSet.PermissionsCustomizeApplication = true
                LIMIT 1
            ];
            return !assignments.isEmpty();
        } catch (Exception e) {
            // If permission check fails, default to false for security
            return false;
        }
    }
}