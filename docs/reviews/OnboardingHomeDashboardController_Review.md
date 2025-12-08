# OnboardingHomeDashboardController Review

## Review Date
2024-12-19

## Summary
The controller has been updated to handle ownership-based filtering for onboarding records. While the ownership logic is functionally correct, there are several architectural and documentation concerns that should be addressed.

---

## ✅ What's Working Well

1. **Ownership Logic is Sound**: The ownership determination logic correctly handles:
   - Account owner matching
   - Territory assignment-based ownership (Onboarding_Rep__c and Base_App_OB_Rep__c)
   - Role hierarchy traversal for team views

2. **View Filter Implementation**: The three-tier view filter (MY_VIEW, MY_TEAM, ORG_WIDE) is properly implemented

3. **Parameter Handling**: Good null/empty parameter handling with sensible defaults

4. **DTO Usage**: Proper use of DTOs for data transfer

---

## ⚠️ Architectural Concerns

### 1. **Direct SOQL in Controller (High Priority)**

**Issue**: Controllers are building and executing dynamic SOQL queries directly instead of using repositories.

**Location**: Lines 59-64, 134-137, 265-270, 553-558, and others

**Example**:
```apex
String query = 'SELECT Id, Name, Onboarding_Status__c, Account__c, Account__r.Name, ' +
              'Vendor_Customization__c, Vendor_Customization__r.Name, ' +
              'CreatedDate, LastModifiedDate, CreatedById, CreatedBy.Name ' +
              'FROM Onboarding__c WHERE ' + whereClause + ' ORDER BY LastModifiedDate DESC LIMIT 20';
List<Onboarding__c> onboardings = Database.query(query);
```

**Violation**: Controllers should delegate data access to repositories. This violates the established architectural pattern where:
- **Controllers** → Handle LWC communication, coordinate services/repositories
- **Repositories** → Handle all SOQL queries and DML
- **Services** → Handle business logic

**Recommendation**: 
- Create methods in `OnboardingRepository` for filtered queries
- Pass filter criteria as parameters to repository methods
- Repository should build and execute queries

**Example Refactor**:
```apex
// In OnboardingRepository
public static List<Onboarding__c> getActiveOnboardingWithFilters(
    Set<Id> ownerUserIds,
    Date startDate,
    List<Id> vendorIds,
    List<Id> programIds,
    Integer limitCount
) {
    // Build query here
}

// In Controller
List<Onboarding__c> onboardings = OnboardingRepository.getActiveOnboardingWithFilters(
    ownerUserIds, startDate, vendorIds, programIds, 20
);
```

---

### 2. **Business Logic in Controller (High Priority)**

**Issue**: Ownership determination logic (`buildOwnerClause`, `getUserIdsForViewFilter`, `getUsersInRoleHierarchy`) is in the controller.

**Location**: Lines 777-838

**Violation**: Business logic should be in services, not controllers. The ownership rules are business logic that:
- Determines who "owns" an onboarding record
- Traverses role hierarchies
- Applies territory assignment rules

**Recommendation**: 
- Create `OnboardingAccessService` or `OnboardingOwnershipService`
- Move ownership logic to service layer
- Controller calls service methods

**Example Structure**:
```apex
// In OnboardingAccessService
public with sharing class OnboardingAccessService {
    public static Set<Id> getUserIdsForViewFilter(String viewFilter) { ... }
    public static String buildOwnerClause(Set<Id> userIds) { ... }
    public static Set<Id> getUsersInRoleHierarchy(Id userId) { ... }
}

// In Controller
Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter(viewFilter);
String ownerClause = OnboardingAccessService.buildOwnerClause(ownerUserIds);
```

---

### 3. **Dynamic Query Building in Controller (Medium Priority)**

**Issue**: Controllers are building WHERE clauses dynamically using string concatenation.

**Location**: Multiple methods throughout the controller

**Concerns**:
- Harder to test
- Potential for SOQL injection (though mitigated by using bind variables)
- Violates separation of concerns

**Recommendation**: Move query building to repository layer where it belongs.

---

## 📝 Documentation Gaps

### 1. **Ownership Logic Documentation (High Priority)**

**Issue**: The ownership determination logic is not well documented.

**Missing Information**:
- What does "ownership" mean in this context?
- Why do we check both Account owner AND territory assignments?
- What is the business rule for territory assignments?
- What are `Onboarding_Rep__c` and `Base_App_OB_Rep__c`?

**Recommendation**: Add comprehensive JavaDoc explaining:

```apex
/**
 * Determines which users should be considered "owners" of onboarding records
 * for the given view filter.
 * 
 * Ownership Rules:
 * 1. MY_VIEW: Only the current user's records
 * 2. MY_TEAM: Current user + all users in their role hierarchy subtree
 * 3. ORG_WIDE: No ownership filter (all records visible to user via sharing)
 * 
 * An onboarding record is "owned" by a user if:
 * - The Account__c.OwnerId matches the user, OR
 * - The Account has a Territory_Assignments__c record where:
 *   - Onboarding_Rep__c = user, OR
 *   - Base_App_OB_Rep__c = user
 * 
 * This allows onboarding reps assigned to territories to see onboarding
 * records for accounts in their territory, even if they don't own the account.
 * 
 * @param viewFilter One of: 'MY_VIEW', 'MY_TEAM', 'ORG_WIDE'
 * @return Set of User IDs that should be treated as owners
 */
private static Set<Id> getUserIdsForViewFilter(String viewFilter) { ... }
```

---

### 2. **Territory_Assignments__c Relationship (High Priority)**

**Issue**: The `buildOwnerClause` method references `Territory_Assignments__c` without explanation.

**Location**: Line 796-797

**Missing Information**:
- What is `Territory_Assignments__c`?
- What is the relationship between Account and Territory_Assignments__c?
- What do `Onboarding_Rep__c` and `Base_App_OB_Rep__c` represent?
- Why do we check both fields?

**Recommendation**: Add detailed documentation:

```apex
/**
 * Builds a SOQL WHERE clause to filter onboarding records by ownership.
 * 
 * Ownership is determined by:
 * 1. Account Owner: If Account__r.OwnerId matches any user in userIds
 * 2. Territory Assignment: If Account has a Territory_Assignments__c record where:
 *    - Onboarding_Rep__c matches any user in userIds (primary onboarding rep), OR
 *    - Base_App_OB_Rep__c matches any user in userIds (base app onboarding rep)
 * 
 * Territory_Assignments__c is a junction object linking Accounts to Users
 * who are responsible for onboarding activities in that territory. This allows
 * onboarding reps to see records for accounts in their assigned territories
 * without requiring account ownership.
 * 
 * @param userIds Set of User IDs to check ownership against
 * @return SOQL WHERE clause fragment, or empty string if userIds is empty/null
 * @example Returns: "(Account__r.OwnerId IN :userIds OR Account__c IN (...))"
 */
private static String buildOwnerClause(Set<Id> userIds) { ... }
```

---

### 3. **Method Documentation (Medium Priority)**

**Issue**: Some methods lack comprehensive documentation.

**Missing Information**:
- `getUsersInRoleHierarchy`: What does "role hierarchy" mean? Does it include the user themselves?
- `buildOwnerClause`: What does it return? What format?
- Parameter documentation could be more detailed

**Recommendation**: Add JavaDoc to all private helper methods explaining:
- Purpose
- Parameters
- Return values
- Business rules
- Examples

---

## 🔍 Pattern Violations

### 1. **Controller Doing Too Much**

**Issue**: Controller methods are:
- Building queries
- Executing queries
- Applying business logic
- Transforming data

**Pattern**: Controllers should be thin - coordinate between services/repositories and transform to DTOs.

**Current Pattern**:
```
Controller → Direct SOQL → Business Logic → DTOs
```

**Recommended Pattern**:
```
Controller → Service (business logic) → Repository (data access) → DTOs
```

---

### 2. **Inconsistent Repository Usage**

**Issue**: Some methods use repositories (`getAllActiveOnboarding`, `getAccountsForOnboarding`) while others build queries directly.

**Location**: 
- ✅ Uses repository: Line 310, 172
- ❌ Direct query: Lines 59-64, 134-137, 265-270, etc.

**Recommendation**: Be consistent - either use repositories everywhere or document why exceptions exist.

---

## 🎯 Recommendations Priority

### High Priority (Address Immediately)

1. **Extract ownership logic to service layer**
   - Create `OnboardingAccessService`
   - Move `getUserIdsForViewFilter`, `buildOwnerClause`, `getUsersInRoleHierarchy`
   - Update controller to use service

2. **Extract query building to repository**
   - Create repository methods for filtered queries
   - Move dynamic query building to repository
   - Controller passes filter criteria to repository

3. **Add comprehensive documentation**
   - Document ownership rules and business logic
   - Document Territory_Assignments__c relationship
   - Add JavaDoc to all helper methods

### Medium Priority (Address Soon)

4. **Consolidate query building patterns**
   - Standardize on repository pattern
   - Remove direct SOQL from controller

5. **Add unit tests for ownership logic**
   - Test role hierarchy traversal
   - Test territory assignment matching
   - Test view filter logic

### Low Priority (Nice to Have)

6. **Consider caching role hierarchy**
   - Role hierarchy queries could be expensive
   - Consider caching for performance

7. **Extract filter building to service**
   - Create `OnboardingDashboardFilterService` (already exists but not used)
   - Use it for date range and filter clause building

---

## 📋 Specific Code Issues

### Issue 1: Role Hierarchy Query Could Be Expensive

**Location**: Lines 803-838

**Issue**: `getUsersInRoleHierarchy` performs multiple queries in a loop, which could be slow for deep hierarchies.

**Recommendation**: Consider using a single recursive query or caching mechanism.

### Issue 2: Territory Assignment Query in WHERE Clause

**Location**: Line 796-797

**Issue**: Subquery in WHERE clause may not be optimal for performance.

**Recommendation**: Consider pre-querying territory assignments and using IN clause with account IDs.

### Issue 3: Hard-coded Field Names

**Location**: Throughout

**Issue**: Field API names are hard-coded as strings.

**Recommendation**: Consider using Schema describe calls or constants for field names to reduce risk of typos.

---

## ✅ What to Keep

1. **Ownership logic is correct** - The business logic appears sound
2. **View filter implementation** - Properly handles the three view types
3. **Parameter validation** - Good null/empty handling
4. **DTO usage** - Proper separation of concerns for data transfer

---

## 📚 References

- Existing Repository Pattern: `OnboardingRepository`, `AccountRepository`
- Existing Service Pattern: `OnboardingApplicationService`, `VendorOnboardingWizardService`
- Territory Assignment Object: `Territory_Assignments__c` (referenced in multiple places)

---

## Next Steps

1. Review this document with the team
2. Prioritize refactoring based on business needs
3. Create tickets for high-priority items
4. Update controller incrementally to avoid breaking changes
5. Add comprehensive tests for ownership logic

---

## Questions for Clarification

1. What is the exact business rule for territory assignments? When should `Onboarding_Rep__c` vs `Base_App_OB_Rep__c` be used?
2. Should role hierarchy traversal include the user themselves? (Currently yes, but confirm)
3. Are there performance concerns with the current implementation that need immediate attention?
4. Should we maintain backward compatibility during refactoring, or can we break the API?

