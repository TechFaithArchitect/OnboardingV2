# Junction Object Refactor - Implementation Summary

## Executive Summary

This refactoring implements a junction-based architecture to enable true many-to-many relationships between:
- **Templates and Requirement Sets**: One template can belong to multiple requirement sets
- **Vendor Programs and Requirement Sets**: Multiple vendor programs can share the same requirement set

This follows the Campaign/CampaignMember pattern used throughout the onboarding application.

## Files Created

### New Objects

1. **Requirement_Set_Template__c** (`force-app/main/default/objects/Requirement_Set_Template__c/`)
   - Junction object: Template ↔ Requirement Set
   - Fields: `Onboarding_Requirement_Set__c`, `Requirement_Template__c`, `Sequence__c`, `Active__c`

2. **Vendor_Program_Requirement_Set__c** (`force-app/main/default/objects/Vendor_Program_Requirement_Set__c/`)
   - Junction object: Vendor Program ↔ Requirement Set
   - Fields: `Vendor_Program__c`, `Onboarding_Requirement_Set__c`, `Active__c`, `Default__c`

### New Service Classes

1. **RequirementSetTemplateService.cls** (`force-app/main/default/classes/services/`)
   - Methods for managing Template ↔ Requirement Set relationships
   - Key methods:
     - `linkTemplateToRequirementSet()` - Create junction record
     - `linkTemplatesToRequirementSet()` - Bulk create
     - `unlinkTemplateFromRequirementSet()` - Delete junction
     - `getTemplatesForRequirementSet()` - Query templates via junction
     - `getRequirementSetsForTemplate()` - Query requirement sets via junction

2. **VendorProgramRequirementSetService.cls** (`force-app/main/default/classes/services/`)
   - Methods for managing Vendor Program ↔ Requirement Set relationships
   - Key methods:
     - `linkVendorProgramToRequirementSet()` - Create junction record
     - `linkRequirementSetsToVendorProgram()` - Bulk create
     - `unlinkRequirementSetFromVendorProgram()` - Delete junction
     - `getRequirementSetsForVendorProgram()` - Query requirement sets via junction
     - `getVendorProgramsForRequirementSet()` - Query vendor programs via junction
     - `getDefaultRequirementSetForVendorProgram()` - Get default requirement set

### Updated Files

1. **VendorOnboardingWizardRepository.cls**
   - Updated `getTemplatesForRequirementSet()` - Uses junction, falls back to legacy MD relationship
   - Updated `linkRequirementSetToVendorProgram()` - Uses junction instead of direct field update
   - Updated `searchOnboardingRequirementSets()` - Supports junction queries
   - Updated `getRequirementSetsWithTemplates()` - Updated to work with junctions
   - Updated `searchRequirementSetsWithTemplates()` - Uses junction for template search
   - Updated `getHistoricalStatusRulesEngines()` - Uses junction to find vendor programs

### Documentation

1. **JUNCTION_OBJECT_MIGRATION.md** (`docs/migrations/`)
   - Complete migration guide with step-by-step instructions
   - Architecture diagrams (before/after)
   - Testing checklist
   - Rollback plan

2. **Migration Scripts** (`docs/migrations/migration-scripts/`)
   - `01_Migrate_Template_To_RequirementSet_Junctions.apex` - Migrates template relationships
   - `02_Migrate_VendorProgram_To_RequirementSet_Junctions.apex` - Migrates vendor program relationships

## Architecture Changes

### Before
```
Vendor_Program_Onboarding_Req_Template__c (Master-Detail) → Onboarding_Requirement_Set__c
Onboarding_Requirement_Set__c (Lookup) → Vendor_Customization__c (1-to-1)
```

**Limitations:**
- Template can only belong to ONE requirement set (Master-Detail constraint)
- Requirement set can only belong to ONE vendor program (Lookup = 1-to-1)

### After
```
Vendor_Program_Onboarding_Req_Template__c ← Junction → Onboarding_Requirement_Set__c
                                              ↓
                           Requirement_Set_Template__c

Vendor_Customization__c ← Junction → Onboarding_Requirement_Set__c
                                ↓
            Vendor_Program_Requirement_Set__c
```

**Benefits:**
- Template can belong to MANY requirement sets (many-to-many)
- Requirement set can belong to MANY vendor programs (many-to-many)
- Flexible sequencing and ordering via junction fields
- Default designation support for vendor programs

## Backward Compatibility

All repository methods maintain backward compatibility:

1. **Dual-Mode Queries**: Check junction first, fall back to legacy fields if no junctions exist
2. **Legacy Support**: Existing Master-Detail and Lookup relationships continue to work
3. **Gradual Migration**: Data can be migrated incrementally without breaking existing functionality

## Key Features

### Junction Object Features

**Requirement_Set_Template__c:**
- Simple junction object with just the two lookup fields
- To remove a relationship, simply delete the junction record

**Vendor_Program_Requirement_Set__c:**
- Simple junction object with just the two lookup fields
- To remove a relationship, simply delete the junction record

## Migration Strategy

### Phase 1: Deploy (Current)
- Deploy new objects and service classes
- Code supports both old and new relationships

### Phase 2: Data Migration
- Run migration scripts to create junction records from existing relationships
- Verify data integrity

### Phase 3: Update UI (Pending)
- Update LWC components to use junction relationships
- Add UI for managing multiple relationships

### Phase 4: Cleanup (Future)
- Make legacy fields optional
- Update all references to use junctions exclusively

## Testing Considerations

### Test Scenarios

1. **Template Relationships:**
   - Create template, link to multiple requirement sets
   - Query templates via junction
   - Update sequence
   - Deactivate link (soft delete)

2. **Vendor Program Relationships:**
   - Link requirement set to multiple vendor programs
   - Set default requirement set
   - Query requirement sets for vendor program
   - Handle multiple defaults (should prevent)

3. **Backward Compatibility:**
   - Verify legacy queries still work
   - Verify migration fallback logic
   - Test with data that has both old and new relationships

4. **Bulk Operations:**
   - Bulk link templates to requirement sets
   - Bulk link requirement sets to vendor programs
   - Bulk delete operations

## Next Steps

1. **Deploy to Sandbox**: Deploy new objects and classes
2. **Run Migration Scripts**: Create junction records from existing data
3. **Update LWC Components**: Modify UI to support new relationships
4. **Test Thoroughly**: Verify all scenarios work correctly
5. **Deploy to Production**: After validation

## Notes

- Master-Detail field `Onboarding_Requirement_Set__c` on Template **cannot** be directly converted to Lookup in Salesforce
- During transition, both old and new relationships coexist
- Junction objects add query complexity but provide much-needed flexibility
- Service classes abstract this complexity from consumers

## Support

For questions or issues:
- Review service class documentation
- Check migration guide: `docs/migrations/JUNCTION_OBJECT_MIGRATION.md`
- Review repository methods for query patterns

---

**Status**: ✅ Implementation Complete (Pending LWC Updates)
**Date**: December 2025
**Version**: 1.0

