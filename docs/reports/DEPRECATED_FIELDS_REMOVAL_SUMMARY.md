# Deprecated Fields Removal Summary

## Overview

Successfully removed all references to deprecated fields from Apex classes and refactored code to use junction objects exclusively.

## Deprecated Fields Removed

1. **`Onboarding_Requirement_Set__c`** - Master-Detail field on `Vendor_Program_Onboarding_Req_Template__c`
   - **Replaced by**: `Requirement_Set_Template__c` junction object

2. **`Vendor_Program__c`** - Lookup field on `Onboarding_Requirement_Set__c`
   - **Replaced by**: `Vendor_Program_Requirement_Set__c` junction object

## Classes Refactored

### 1. RequirementTemplateTriggerHandler.cls

**Changes**:
- `preventDuplicateLabels()`: Now uses junction objects to find requirement sets linked to templates
  - For before insert: Skip duplicate checking (junction records don't exist yet)
  - For before update: Check duplicates via junction queries
- `setVersionNumbers()`: Now uses junction objects to find requirement sets
  - For before insert: Default to version '1' (junction records don't exist yet)
  - For before update: Calculate version based on junction-linked requirement sets

**Key Logic**:
- Inserts don't have junction records yet, so version defaults to '1'
- Duplicate checking is deferred until update when junction records exist
- Version calculation uses maximum version across all requirement sets a template belongs to

### 2. OnboardingRequirementSetService.cls

**Changes**:
- `createOnboardingRequirementSet()`: Removed use of `Vendor_Program__c` field
  - Now accepts optional `List<Id> vendorProgramIds` parameter
  - Creates junction records automatically via `VendorProgramRequirementSetService`
- `createOnboardingRequirementTemplate()`: Removed use of `Onboarding_Requirement_Set__c` field
  - Now accepts optional `List<Id> requirementSetIds` parameter
  - Creates junction records automatically via `RequirementSetTemplateService`
- `createRequirementSetFromExisting()`: Updated to use junction objects for linking
- `getOnboardingContext()`: Updated to use junction queries instead of direct field queries
- Overloaded methods updated to not extract IDs from deprecated fields

**Key Logic**:
- All linking now happens via junction objects
- Backward-compatible overloaded methods accept empty lists instead of extracting from deprecated fields

### 3. VendorOnboardingWizardRepository.cls

**Changes**:
- `searchOnboardingRequirementSets()`: Removed fallback to `Vendor_Program__c` field
- `fetchOnboardingRequirementSets()`: Removed `Vendor_Program__c` from SELECT
- `getRequirementSetsWithTemplates()`: Removed `Vendor_Program__c` from SELECT
- `searchRequirementSetsWithTemplates()`: Removed legacy MD relationship fallback
- `getTemplatesForRequirementSet()`: Removed fallback to legacy MD relationship
- `getRequirementSetById()`: Removed `Vendor_Program__c` from SELECT
- `getHistoricalGroupMembers()`: Removed fallback to `Vendor_Program__c` field
- `getHistoricalStatusRulesEngines()`: Removed fallback to `Vendor_Program__c` field
- `linkRequirementSetToVendorProgram()`: Simplified to only use junction service

**Key Logic**:
- All queries now use junction objects exclusively
- No fallback logic to deprecated fields
- Cleaner, more consistent codebase

### 4. VendorOnboardingWizardService.cls

**Changes**:
- `createOnboardingRequirementTemplate()`: Removed extraction of requirement set ID from deprecated field
  - Now passes empty list to service method
  - Junction records must be created separately

### 5. VendorOnboardingWizardController.cls

**Changes**:
- `buildRequirementSetHierarchy()`: Removed legacy MD relationship fallback query
  - Now uses only junction objects

### 6. Test Classes

**TestOnboardingRequirementSetFactory.cls**:
- Removed `Vendor_Program__c` field assignment
- Now creates `Vendor_Program_Requirement_Set__c` junction record after insert

**TestVdrPrgrmOnboardingReqTemplateFactory.cls**:
- Removed `Onboarding_Requirement_Set__c` field assignment
- Now creates `Requirement_Set_Template__c` junction record after insert

## Important Notes

### Before Insert Trigger Limitations

**Issue**: Junction records are created AFTER template/requirement set creation (in service layer), but triggers run BEFORE insert.

**Impact**:
- **Duplicate Checking**: Cannot check duplicates across requirement sets in before insert (no junction records exist yet)
  - **Solution**: Duplicate checking only occurs on updates when junction records exist
- **Version Numbers**: Cannot calculate version based on requirement sets in before insert
  - **Solution**: Default to version '1' for new templates, calculate proper version on first update

**Future Consideration**: If duplicate checking on insert is critical, consider:
1. Creating junction records before template insert (requires refactoring service layer)
2. Moving duplicate checking to after insert trigger
3. Using a different validation mechanism

### Field Metadata Removal

**Note**: The deprecated field metadata files should be removed from Salesforce:
- `Vendor_Program_Onboarding_Req_Template__c.Onboarding_Requirement_Set__c` (if Master-Detail, this may require additional steps)
- `Onboarding_Requirement_Set__c.Vendor_Program__c`

**Warning**: If `Onboarding_Requirement_Set__c` was a Master-Detail field, removing it requires:
1. Converting to Lookup first (if not already)
2. Or handling data migration before deletion

## Migration Requirements

Before deploying these changes to production:

1. **Run Migration Scripts**: Ensure all existing data has junction records created
   - `docs/migrations/migration-scripts/01_Migrate_Template_To_RequirementSet_Junctions.apex`
   - `docs/migrations/migration-scripts/02_Migrate_VendorProgram_To_RequirementSet_Junctions.apex`

2. **Verify Data Integrity**: Ensure all templates have at least one junction record to a requirement set
3. **Test Trigger Behavior**: New templates will default to version '1' until first update
4. **Update UI/Flows**: Ensure all UI components and Flows use junction-based queries

## Testing Checklist

- [ ] Create new template without requirement set - should work (can link later)
- [ ] Create new template with requirement set - junction record should be created
- [ ] Update template - duplicate checking should work via junction
- [ ] Update template - version calculation should work via junction
- [ ] Create requirement set without vendor program - should work
- [ ] Create requirement set with vendor program - junction record should be created
- [ ] Query templates for requirement set - should use junction
- [ ] Query requirement sets for vendor program - should use junction
- [ ] Test factories create junction records correctly
- [ ] Verify no compilation errors

## Files Modified

1. `force-app/main/default/classes/handlers/RequirementTemplateTriggerHandler.cls`
2. `force-app/main/default/classes/services/OnboardingRequirementSetService.cls`
3. `force-app/main/default/classes/repository/VendorOnboardingWizardRepository.cls`
4. `force-app/main/default/classes/services/VendorOnboardingWizardService.cls`
5. `force-app/main/default/classes/controllers/VendorOnboardingWizardController.cls`
6. `force-app/main/default/classes/test/TestOnboardingRequirementSetFactory.cls`
7. `force-app/main/default/classes/test/TestVdrPrgrmOnboardingReqTemplateFactory.cls`

## Next Steps

1. Remove field metadata files from Salesforce (via Metadata API or UI)
2. Update any Flows or Process Builder that reference deprecated fields
3. Update any UI components (LWCs) that reference deprecated fields
4. Run full test suite to ensure no regressions
5. Deploy to sandbox for UAT
6. Create data migration scripts if needed
7. Deploy to production

---

**Status**: ✅ Apex Refactoring Complete
**Date**: December 2025
**Version**: 1.0

