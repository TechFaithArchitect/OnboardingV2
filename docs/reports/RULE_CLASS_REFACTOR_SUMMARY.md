# Rule Class Refactoring Summary

## Overview

Refactored rule classes and controller to use junction objects instead of deprecated direct relationship fields.

## Classes Refactored

### 1. AllRequirementSetMustBeActiveRule.cls

**Problem**: 
- Used deprecated `Onboarding_Requirement_Set__r` relationship field to check if requirement set is active
- This relationship field no longer exists after removing `Onboarding_Requirement_Set__c` from templates

**Solution**:
- Now uses `Requirement_Set_Template__c` junction object to find requirement sets linked to templates
- Queries junction records to get requirement set IDs
- Validates Active__c status on requirement sets via junction

**Key Changes**:
```apex
// OLD: Direct relationship query (deprecated)
SELECT Id, Name, Onboarding_Requirement_Set__r.Active__c
FROM Vendor_Program_Onboarding_Req_Template__c

// NEW: Junction-based query
// Step 1: Get requirement set IDs via junction
SELECT Requirement_Template__c, Onboarding_Requirement_Set__c
FROM Requirement_Set_Template__c
WHERE Requirement_Template__c IN :recordIds

// Step 2: Query requirement sets separately
SELECT Id, Active__c
FROM Onboarding_Requirement_Set__c
WHERE Id IN :requirementSetIds
```

**Behavior**:
- If a template has no requirement sets linked (no junction records), it can be activated independently
- If templates are linked to requirement sets, all linked requirement sets must be active

### 2. VendorOnboardingWizardController.cls

**Problem**:
- SELECT statement included deprecated `Onboarding_Requirement_Set__c` field in `buildRequirementSetHierarchy()` method
- Field no longer exists on template object

**Solution**:
- Removed `Onboarding_Requirement_Set__c` from SELECT statement
- Templates are already fetched via junction objects, so this field was not needed

**Key Changes**:
```apex
// OLD: Included deprecated field
SELECT Id, Requirement_Label__c, Requirement_Type__c, Status__c, 
       Is_Current_Version__c, CreatedDate, LastModifiedDate, 
       Onboarding_Requirement_Set__c  // <-- DEPRECATED
FROM Vendor_Program_Onboarding_Req_Template__c

// NEW: Removed deprecated field
SELECT Id, Requirement_Label__c, Requirement_Type__c, Status__c, 
       Is_Current_Version__c, CreatedDate, LastModifiedDate
FROM Vendor_Program_Onboarding_Req_Template__c
```

**Impact**:
- No functional change - field was not being used in the DTO mapping
- Cleaner code, no reference to deprecated field

## Validation Logic

### AllRequirementSetMustBeActiveRule

**Purpose**: Prevents activation of templates when their linked requirement sets are not active.

**Validation Flow**:
1. Get template IDs being activated
2. Query `Requirement_Set_Template__c` junction records to find linked requirement sets
3. Query `Onboarding_Requirement_Set__c` records to check `Active__c` status
4. For each template, check all linked requirement sets
5. Throw exception if any linked requirement set is not active

**Edge Cases Handled**:
- Templates with no junction records (can activate independently)
- Templates linked to multiple requirement sets (all must be active)
- Missing requirement sets (skipped safely)

## Testing Considerations

When testing these changes:

1. **Test AllRequirementSetMustBeActiveRule**:
   - ✅ Template with no requirement sets → should activate
   - ✅ Template with active requirement set → should activate
   - ✅ Template with inactive requirement set → should throw error
   - ✅ Template with multiple requirement sets (all active) → should activate
   - ✅ Template with multiple requirement sets (one inactive) → should throw error

2. **Test VendorOnboardingWizardController**:
   - ✅ Verify hierarchy builds correctly without deprecated field
   - ✅ Verify templates are properly linked via junction in hierarchy
   - ✅ Verify tree-grid displays correctly

## Related Classes

The following classes were **NOT** refactored because they use valid fields:
- `AllTemplatesInReqSetMustBeActiveRule.cls` - Uses `Vendor_Program__c` on `Vendor_Program_Requirement__c` (valid lookup)
- `AllChildRequirementsMustBeActiveRule.cls` - Uses `Vendor_Program__c` on `Vendor_Program_Requirement__c` (valid lookup)
- Other rule classes - Use `Vendor_Program__c` on different objects (valid lookups)

## Deployment Notes

1. Deploy rule classes after junction objects are deployed
2. Test activation rules thoroughly in sandbox
3. Ensure all existing templates have junction records (run migration scripts if needed)
4. Monitor for any activation errors after deployment

---

**Status**: ✅ Refactoring Complete
**Date**: December 2025
**Version**: 1.0

