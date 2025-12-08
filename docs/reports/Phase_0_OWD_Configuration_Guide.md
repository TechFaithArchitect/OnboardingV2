# Phase 0: Organization-Wide Defaults (OWD) Configuration Guide

## Important Note About Master-Detail Relationships

Objects with Master-Detail relationships automatically use `ControlledByParent` sharing model. This means:
- **Requirement_Field_Value__c** (Master-Detail to Onboarding_Requirement__c) → `ControlledByParent`
- **Requirement_Field__c** (Master-Detail to Vendor_Program_Requirement__c) → `ControlledByParent`
- **Requirement_Field_Group__c** (Master-Detail to Vendor_Program_Requirement__c) → `ControlledByParent`

**This is the correct and desired behavior** - it ensures data security by inheriting access from the parent record.

## OWD Settings Per Object

### Requirement_Field_Value__c
- **Sharing Model**: `ControlledByParent` (automatic with Master-Detail)
- **Parent**: Onboarding_Requirement__c
- **Rationale**: Contains sensitive data (SSN, etc.), dealer-specific. Access controlled by parent Onboarding_Requirement__c.

### Follow_Up_Queue__c
- **Sharing Model**: `Private` (manual setting required)
- **Rationale**: Contains communication history, dealer-specific. No Master-Detail, so must be set to Private manually.

### Requirement_Field__c
- **Sharing Model**: `ControlledByParent` (automatic with Master-Detail)
- **Parent**: Vendor_Program_Requirement__c
- **Rationale**: Metadata-like, shared across programs. Access controlled by parent Vendor_Program_Requirement__c.

### Requirement_Field_Group__c
- **Sharing Model**: `ControlledByParent` (automatic with Master-Detail)
- **Parent**: Vendor_Program_Requirement__c
- **Rationale**: Metadata-like, shared across programs. Access controlled by parent Vendor_Program_Requirement__c.

## Configuration Steps

### Step 1: Verify Master-Detail Objects (Automatic)
The following objects automatically have `ControlledByParent` due to Master-Detail relationships:
- ✅ Requirement_Field_Value__c
- ✅ Requirement_Field__c
- ✅ Requirement_Field_Group__c

**No action needed** - these are automatically configured correctly.

### Step 2: Set Follow_Up_Queue__c to Private (Manual)
1. Go to **Setup** → **Object Manager** → **Follow Up Queue**
2. Click **Sharing Settings**
3. Set **Default Internal Access** to **Private**
4. Set **Default External Access** to **Private**
5. Save

### Step 3: Verify Parent Object Sharing Models
Ensure parent objects have appropriate sharing:
- **Onboarding_Requirement__c** - Should be `ControlledByParent` (parent: Onboarding__c)
- **Vendor_Program_Requirement__c** - Check current sharing model

## Expected Behavior

### With ControlledByParent (Master-Detail):
- Users can only access child records if they have access to the parent
- Deleting parent automatically deletes children (cascade delete)
- Roll-up summary fields can be created
- Sharing rules on parent affect children

### With Private (Follow_Up_Queue__c):
- Users can only access records they own or that are shared with them
- Manual sharing or sharing rules required for access
- More granular control over access

## Testing Checklist

- [ ] Verify Requirement_Field_Value__c is ControlledByParent
- [ ] Verify Requirement_Field__c is ControlledByParent
- [ ] Verify Requirement_Field_Group__c is ControlledByParent
- [ ] Set Follow_Up_Queue__c to Private
- [ ] Test cascade delete: Delete Onboarding_Requirement__c → Requirement_Field_Value__c records deleted
- [ ] Test cascade delete: Delete Vendor_Program_Requirement__c → Requirement_Field__c and Requirement_Field_Group__c records deleted
- [ ] Test access: User without parent access cannot see child records

