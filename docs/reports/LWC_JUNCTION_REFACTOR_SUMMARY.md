# LWC Component Updates for Junction Object Architecture

## Summary

Updated Lightning Web Components to work with the new junction-based many-to-many relationship model. Components now support:
- Templates linked to multiple requirement sets
- Requirement sets linked to multiple vendor programs
- Backward compatibility with legacy Master-Detail and Lookup relationships

## Updated Components

### 1. vendorProgramOnboardingReqTemplate

**File**: `force-app/main/default/lwc/vendorProgramOnboardingReqTemplate/vendorProgramOnboardingReqTemplate.js`

**Changes**:
- Updated template creation to mark `Onboarding_Requirement_Set__c` as optional
- Added comments explaining that junction records are the primary linking mechanism
- Service layer automatically creates junction records when `Onboarding_Requirement_Set__c` is provided
- Supports backward compatibility with existing MD relationship

**Key Code**:
```javascript
// Template creation - Onboarding_Requirement_Set__c is optional for many-to-many support
const templateToCreate = {
  Onboarding_Requirement_Set__c: this.requirementSetId || null, // Optional for many-to-many
  Requirement_Label__c: trimmedLabel,
  // ... other fields
};

// Junction record is created automatically by the service if Onboarding_Requirement_Set__c was provided
```

### 2. vendorProgramOnboardingRequirementSet

**File**: `force-app/main/default/lwc/vendorProgramOnboardingRequirementSet/vendorProgramOnboardingRequirementSet.js`

**Changes**:
- Updated requirement set creation to mark `Vendor_Program__c` as optional
- Service layer automatically creates junction records when `Vendor_Program__c` is provided
- Supports backward compatibility with existing Lookup relationship

**Key Code**:
```javascript
// Create requirement set - Vendor_Program__c is optional for many-to-many support
const requirementSetId = await createOnboardingRequirementSet({ 
  requirementSet: { 
    Name: this.newRequirementSetName.trim(),
    Vendor_Program__c: this.vendorProgramId || null // Optional for many-to-many
  } 
});
```

### 3. vendorProgramOnboardingRequirementSetOrCreate

**File**: `force-app/main/default/lwc/vendorProgramOnboardingRequirementSetOrCreate/vendorProgramOnboardingRequirementSetOrCreate.js`

**Changes**:
- Updated both requirement set and template creation to use optional fields
- `linkRequirementSetToVendorProgram` now uses junction objects (updated in service layer)
- Maintains backward compatibility

**Key Code**:
```javascript
// Create requirement set - Vendor_Program__c is optional for many-to-many support
const newSetId = await createOnboardingRequirementSet({
  requirementSet: {
    Vendor_Program__c: this.vendorProgramId || null, // Optional for many-to-many
    Status__c: 'Draft'
  }
});

// Create template - Onboarding_Requirement_Set__c is optional
const templateId = await createOnboardingRequirementTemplate({
  template: {
    Onboarding_Requirement_Set__c: this.currentRequirementSetId || null, // Optional for many-to-many
    // ... other fields
  }
});
```

## Updated Apex Controller Methods

### New Methods Added to VendorOnboardingWizardController

1. **linkTemplateToRequirementSets** - Links a template to one or more requirement sets via junction
2. **linkRequirementSetToVendorPrograms** - Links a requirement set to one or more vendor programs via junction
3. **getRequirementSetsForTemplate** - Gets all requirement sets linked to a template
4. **getVendorProgramsForRequirementSet** - Gets all vendor programs linked to a requirement set
5. **unlinkTemplateFromRequirementSet** - Removes junction link between template and requirement set
6. **unlinkRequirementSetFromVendorProgram** - Removes junction link between requirement set and vendor program

### Updated Methods

1. **createOnboardingRequirementTemplate** - Now supports optional `Onboarding_Requirement_Set__c` and creates junction records automatically
2. **createOnboardingRequirementSet** - Now supports optional `Vendor_Program__c` and creates junction records automatically
3. **linkRequirementSetToVendorProgram** - Now uses junction objects instead of direct field update
4. **buildRequirementSetHierarchy** - Updated to fetch templates via junction objects instead of child relationship

## Updated Service Methods

### OnboardingRequirementSetService

- **createOnboardingRequirementTemplate**: 
  - Now accepts optional `List<Id> requirementSetIds` parameter
  - Creates junction records automatically after template creation
  - Maintains backward compatibility with overloaded method

- **createOnboardingRequirementSet**:
  - Now accepts optional `List<Id> vendorProgramIds` parameter
  - Creates junction records automatically after requirement set creation
  - Maintains backward compatibility with overloaded method

- **linkRequirementSetToVendorProgram**:
  - Now uses `VendorProgramRequirementSetService.linkVendorProgramToRequirementSet()`
  - No longer updates `Vendor_Program__c` field directly

### RequirementSetTemplateService (New)

- `linkTemplateToRequirementSet()` - Creates junction record
- `linkTemplatesToRequirementSet()` - Bulk create junction records
- `unlinkTemplateFromRequirementSet()` - Deletes junction record
- `getRequirementSetsForTemplate()` - Queries via junction
- `getTemplatesForRequirementSet()` - Queries via junction
- `getTemplatesWithDetailsForRequirementSet()` - Full template details via junction

### VendorProgramRequirementSetService (New)

- `linkVendorProgramToRequirementSet()` - Creates junction record
- `linkRequirementSetsToVendorProgram()` - Bulk create junction records
- `unlinkRequirementSetFromVendorProgram()` - Deletes junction record
- `getRequirementSetsForVendorProgram()` - Queries via junction
- `getVendorProgramsForRequirementSet()` - Queries via junction
- `getRequirementSetsWithDetailsForVendorProgram()` - Full requirement set details via junction

## Backward Compatibility

All changes maintain backward compatibility:

1. **Legacy Fields**: `Onboarding_Requirement_Set__c` and `Vendor_Program__c` fields still work if provided
2. **Dual-Mode Queries**: Repository methods check junction first, fall back to legacy fields
3. **Gradual Migration**: Existing data continues to work while new data uses junctions
4. **Automatic Junction Creation**: When legacy fields are provided, junction records are created automatically

## Migration Path

1. **Phase 1 (Current)**: Deploy objects, services, and updated components
   - New templates/requirement sets automatically create junction records
   - Existing relationships continue to work

2. **Phase 2**: Run migration scripts to create junction records from existing data
   - See `docs/migrations/migration-scripts/`

3. **Phase 3 (Future)**: Update UI to support multi-select for requirement sets/vendor programs
   - Add UI for linking templates to multiple requirement sets
   - Add UI for linking requirement sets to multiple vendor programs

4. **Phase 4 (Future)**: Make legacy fields optional
   - Remove requirement for `Onboarding_Requirement_Set__c` on templates
   - Remove requirement for `Vendor_Program__c` on requirement sets
   - Deprecate legacy fields

## Testing Checklist

- [ ] Create template with requirement set ID - verify junction record created
- [ ] Create template without requirement set ID - verify template created (can link later)
- [ ] Create requirement set with vendor program ID - verify junction record created
- [ ] Create requirement set without vendor program ID - verify requirement set created
- [ ] Query templates for requirement set - verify junction query works
- [ ] Query requirement sets for vendor program - verify junction query works
- [ ] Link template to multiple requirement sets - verify multiple junction records
- [ ] Link requirement set to multiple vendor programs - verify multiple junction records
- [ ] Verify legacy data still works (existing MD/Lookup relationships)
- [ ] Verify hierarchy tree-grid displays correctly with junction queries

## Notes

- The Master-Detail field `Onboarding_Requirement_Set__c` on Template may still be required in Salesforce
- During transition, templates can have both MD relationship AND junction records
- After migration, prioritize using junction records for new relationships
- Legacy fields will be deprecated in future phase

---

**Status**: ✅ LWC Updates Complete
**Date**: December 2025
**Version**: 1.0

