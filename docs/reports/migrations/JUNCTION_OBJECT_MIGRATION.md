# Junction Object Migration Guide

## Overview

This migration refactors the object relationships to enable true many-to-many relationships using junction objects, following the Campaign/CampaignMember pattern.

## Migration Goals

1. **Enable Many Vendor Programs → One Requirement Set**: Multiple vendor programs can now share the same requirement set
2. **Enable One Template → Many Requirement Sets**: A template can belong to multiple requirement sets
3. **Maintain Existing Functionality**: All existing features continue to work during and after migration

## Architecture Changes

### Before (Current State)

```
Vendor_Program_Onboarding_Req_Template__c (Master-Detail) → Onboarding_Requirement_Set__c
Onboarding_Requirement_Set__c (Lookup) → Vendor_Customization__c (1-to-1)
```

### After (Target State)

```
Vendor_Program_Onboarding_Req_Template__c ← (Junction) → Onboarding_Requirement_Set__c
                                                           ↓
                                    Requirement_Set_Template__c

Vendor_Customization__c ← (Junction) → Onboarding_Requirement_Set__c
                                          ↓
                      Vendor_Program_Requirement_Set__c
```

## New Objects Created

### 1. Requirement_Set_Template__c

**Purpose**: Junction object connecting Templates to Requirement Sets

**Fields**:
- `Onboarding_Requirement_Set__c` (Lookup, Required) → Onboarding_Requirement_Set__c
- `Requirement_Template__c` (Lookup, Required) → Vendor_Program_Onboarding_Req_Template__c

**Relationship Name**: `Requirement_Set_Templates`

**Note**: Simple junction object - just links templates to requirement sets. To remove a relationship, simply delete the junction record.

### 2. Vendor_Program_Requirement_Set__c

**Purpose**: Junction object connecting Vendor Programs to Requirement Sets

**Fields**:
- `Vendor_Program__c` (Lookup, Required) → Vendor_Customization__c
- `Onboarding_Requirement_Set__c` (Lookup, Required) → Onboarding_Requirement_Set__c

**Relationship Name**: `Vendor_Program_Requirement_Sets`

**Note**: Simple junction object - just links vendor programs to requirement sets. To remove a relationship, simply delete the junction record.

## Migration Steps

### Phase 1: Deploy New Objects and Services

1. Deploy new junction objects:
   - `Requirement_Set_Template__c`
   - `Vendor_Program_Requirement_Set__c`

2. Deploy new service classes:
   - `RequirementSetTemplateService.cls`
   - `VendorProgramRequirementSetService.cls`

3. Deploy updated repository classes that support both legacy and junction approaches

### Phase 2: Data Migration

#### Step 1: Migrate Template → Requirement Set Relationships

Run the migration script to create junction records from existing Master-Detail relationships:

```apex
// Migration Script: Create Requirement_Set_Template__c records
List<Requirement_Set_Template__c> junctionsToCreate = new List<Requirement_Set_Template__c>();

for (Vendor_Program_Onboarding_Req_Template__c template : [
    SELECT Id, Onboarding_Requirement_Set__c
    FROM Vendor_Program_Onboarding_Req_Template__c
    WHERE Onboarding_Requirement_Set__c != null
]) {
    junctionsToCreate.add(new Requirement_Set_Template__c(
        Requirement_Template__c = template.Id,
        Onboarding_Requirement_Set__c = template.Onboarding_Requirement_Set__c,
        Active__c = true
    ));
}

if (!junctionsToCreate.isEmpty()) {
    insert junctionsToCreate;
    System.debug('Created ' + junctionsToCreate.size() + ' Requirement_Set_Template__c records');
}
```

#### Step 2: Migrate Vendor Program → Requirement Set Relationships

Run the migration script to create junction records from existing Lookup relationships:

```apex
// Migration Script: Create Vendor_Program_Requirement_Set__c records
List<Vendor_Program_Requirement_Set__c> junctionsToCreate = new List<Vendor_Program_Requirement_Set__c>();

for (Onboarding_Requirement_Set__c reqSet : [
    SELECT Id, Vendor_Program__c
    FROM Onboarding_Requirement_Set__c
    WHERE Vendor_Program__c != null
]) {
    // Check if junction already exists
    List<Vendor_Program_Requirement_Set__c> existing = [
        SELECT Id
        FROM Vendor_Program_Requirement_Set__c
        WHERE Vendor_Program__c = :reqSet.Vendor_Program__c
        AND Onboarding_Requirement_Set__c = :reqSet.Id
        LIMIT 1
    ];
    
    if (existing.isEmpty()) {
        junctionsToCreate.add(new Vendor_Program_Requirement_Set__c(
            Vendor_Program__c = reqSet.Vendor_Program__c,
            Onboarding_Requirement_Set__c = reqSet.Id,
            Active__c = true,
            Default__c = true // Set first requirement set as default for each vendor program
        ));
    }
}

if (!junctionsToCreate.isEmpty()) {
    insert junctionsToCreate;
    System.debug('Created ' + junctionsToCreate.size() + ' Vendor_Program_Requirement_Set__c records');
}
```

### Phase 3: Update Application Code

1. **Update LWC Components**:
   - Modify `vendorProgramOnboardingReqTemplate` to support linking templates to multiple requirement sets
   - Update UI to show/manage junction relationships instead of direct fields
   - Update requirement set selection components

2. **Update Validation Rules**:
   - Remove or modify any validation rules that assume 1-to-1 relationships
   - Add validation rules to prevent duplicate junction records

3. **Update Workflows/Flows**:
   - Review and update any flows that reference the old relationship fields
   - Update workflows to work with junction objects

### Phase 4: Optional Cleanup

**Important**: Only perform after thorough testing and validation!

1. **Make Onboarding_Requirement_Set__c field optional on Template**:
   - Change the Master-Detail field to Lookup (if possible)
   - Or deprecate the field and update all code references

2. **Deprecate Vendor_Program__c field on Requirement Set**:
   - Remove direct updates to this field
   - Update documentation to indicate it's for legacy data only

## Backward Compatibility

The updated codebase maintains backward compatibility:

1. **Repository Methods**: Check for junction records first, fall back to legacy fields if none exist
2. **Service Methods**: Support both old and new relationship patterns during transition
3. **Legacy Data**: Existing Master-Detail and Lookup relationships continue to work

## Testing Checklist

- [ ] Verify templates can be linked to multiple requirement sets
- [ ] Verify requirement sets can be linked to multiple vendor programs
- [ ] Verify existing functionality still works with legacy data
- [ ] Verify new relationships work correctly
- [ ] Test bulk operations (create, update, delete)
- [ ] Verify reports and dashboards still function
- [ ] Test permission and sharing rules
- [ ] Verify validation rules work correctly
- [ ] Test API integrations (if any)

## Rollback Plan

If issues are encountered:

1. **Immediate**: Remove new junction objects (delete records, then objects)
2. **Code Rollback**: Deploy previous version of repository and service classes
3. **Data Preservation**: Junction records can remain; they won't interfere with legacy relationships

## Timeline

- **Week 1**: Deploy objects and services, run data migration scripts
- **Week 2**: Update LWC components, test thoroughly
- **Week 3**: Update workflows/flows, final testing
- **Week 4**: Optional cleanup phase (only if all tests pass)

## Notes

- The Master-Detail field `Onboarding_Requirement_Set__c` on `Vendor_Program_Onboarding_Req_Template__c` cannot be directly converted to Lookup in Salesforce
- During migration, both relationships exist simultaneously
- After migration is complete and tested, the Master-Detail field can be made optional (requires manual Salesforce configuration)
- Junction objects provide better flexibility but require additional queries compared to direct relationships

## Support

For issues or questions during migration, contact the development team or refer to:
- Service classes: `RequirementSetTemplateService`, `VendorProgramRequirementSetService`
- Repository: `VendorOnboardingWizardRepository`
- Documentation: This file

