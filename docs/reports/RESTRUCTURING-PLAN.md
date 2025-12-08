# Onboarding Flow Restructuring Plan

**Date:** November 2025  
**Status:** In Progress  
**Goal:** Restructure the 16-step wizard into a streamlined 10-step flow with conditional logic for Users vs Admins

---

## Overview

The business team has requested a complete restructuring of the Vendor Program Onboarding wizard. The new flow consolidates steps, adds conditional logic, and differentiates between User and Admin capabilities.

---

## Current vs New Flow

### Current Flow (16 Steps)
1. Select Vendor
2. Search or Create Vendor Program
3. Create Vendor Program
4. Vendor Program Group
5. Vendor Program Requirement Group
6. Vendor Program Recipient Group
7. Recipient Group
8. Recipient Group Members
9. Training Requirements
10. Required Credentials
11. Select or Create Requirement Set
12. Create Requirement Template
13. Vendor Program Requirements
14. Status Rules Engine
15. Status Rule Builder
16. Communication Template

### New Flow (10 Steps)

**Both User and Admin:**
1. Select Vendor
2. Search or Create Vendor Program
   - **2a:** If Creating Draft Vendor Program, prompt for:
     - Vendor Program Label (text)
     - Retail Option (picklist)
     - Business Vertical (picklist)
3. Create Vendor Program in Draft
4. Select Onboarding Requirement Set OR Create Requirements
   - **4a:** If Requirement Set exists and is selected:
     - **4a-1:** Confirm selection → Add to Vendor Program
     - **4a-2:** Make changes → Create new set with "Label - Onboarding Set"
   - **4b:** If Requirement Set doesn't exist or not selected:
     - **4b-1:** Create Vendor_Program_Requirements using templates
     - **4b-1:** Allow inline template creation (no screen change)
     - **4b-2:** Confirm all requirements created
5. Create and Link Requirement Group Components
   - **5a:** If using selected Requirement Set → Link from historical values
   - **5b:** If creating new → Use "Label - <Object Name> Record" naming
6. Required Credentials (Yes/No prompt)
7. Training Requirements (already built)
8. Select or Create Status Rules Engine
   - **8a:** If creating new or doesn't exist → Create Status Rules Engine and Builder
   - **8b:** If selecting existing → Confirm or make changes
9. Communication Template with Recipient Group and Trigger Conditions
10. Update Vendor Program

**User vs Admin Differences:**
- **Users:** Cannot create Recipient Groups, Recipient Group Members, or Vendor Program Recipient Groups
- **Admins:** Can create Recipient Groups, Recipient Group Members, and Vendor Program Recipient Groups (Step 9)

---

## Implementation Phases

### Phase 1: Step 2 Enhancement ✅
- [x] Add Label, Retail Option, Business Vertical fields to Step 2
- [x] Update createVendorProgram to accept these fields
- [x] Ensure Draft status is set

### Phase 2: Step 3 Verification
- [ ] Verify Vendor Program is created in Draft status
- [ ] Ensure all required fields are set

### Phase 3: Step 4 Major Restructure
- [ ] Create new component: `vendorProgramOnboardingRequirementSetOrCreate`
- [ ] Implement Requirement Set selection logic
- [ ] Implement inline template creation
- [ ] Implement requirement creation flow
- [ ] Add confirmation step

### Phase 4: Step 5 Requirement Group Linking
- [ ] Create component for Requirement Group Member, Vendor Program Group, Vendor Program Requirement Group
- [ ] Implement historical linking logic (5a)
- [ ] Implement new record creation with naming convention (5b)

### Phase 5: Step 6 Conditional Required Credentials
- [ ] Update Required Credentials component to show Yes/No prompt
- [ ] Skip step if No selected

### Phase 6: Step 8 Status Rules Engine
- [ ] Update Status Rules Engine component for selection/creation
- [ ] Add confirmation logic
- [ ] Link Status Rule Builder creation

### Phase 7: Step 9 Communication Template
- [ ] Create Communication Template component with Recipient Group selection
- [ ] Add trigger condition configuration
- [ ] Add admin-only Recipient Group creation UI
- [ ] Add user-only Recipient Group selection UI

### Phase 8: Step 10 Finalize
- [ ] Update final step to update Vendor Program status
- [ ] Ensure all relationships are properly linked

### Phase 9: Permission Checks
- [ ] Add admin/user permission detection
- [ ] Conditionally show/hide Recipient Group creation UI

---

## Component Changes Required

### New Components
1. `vendorProgramOnboardingRequirementSetOrCreate` - Step 4 (major component)
2. `vendorProgramOnboardingRequirementGroupLinking` - Step 5
3. `vendorProgramOnboardingCommunicationTemplateWithRecipients` - Step 9

### Modified Components
1. `vendorProgramOnboardingVendorProgramSearchOrCreate` - Add Step 2a fields
2. `vendorProgramOnboardingVendorProgramCreate` - Verify Draft status
3. `vendorProgramOnboardingRequiredCredentials` - Add Yes/No prompt
4. `vendorProgramOnboardingStatusRulesEngine` - Add selection/creation logic
5. `vendorProgramOnboardingStatusRuleBuilder` - Link to Step 8

### Removed/Consolidated Components
- Steps 4-5 (Vendor Program Group, Requirement Group) → Consolidated into Step 5
- Steps 6-8 (Recipient Group components) → Moved to Step 9 (admin only)
- Steps 11-12 (Requirement Set/Template) → Consolidated into Step 4

---

## Data Model Considerations

### Naming Conventions
- New Onboarding Requirement Set: `{Vendor_Customization__r.Label__c} - Onboarding Set`
- New Requirement Group Records: `{Vendor_Customization__r.Label__c} - <Object Name> Record`

### Status Fields
- Vendor Program: `Status__c = 'Draft'` initially
- Vendor Program: `Active__c = false` initially
- Final step updates to active status

### Relationships
- Onboarding_Requirement_Set__c → Vendor_Customization__c
- Vendor_Program_Requirement__c → Vendor_Program_Onboarding_Req_Template__c
- Vendor_Program_Requirement_Group_Member__c → Vendor_Program_Requirement__c
- Vendor_Program_Requirement_Group__c → Vendor_Program_Group__c
- Status_Rules_Engine__c → Onboarding_Requirement_Set__c (if using existing)
- Communication_Template__c → Recipient_Group__c

---

## API Methods Needed

### New Methods
1. `getRetailOptionPicklistValues()` - Get Retail Option picklist values
2. `getBusinessVerticalPicklistValues()` - Get Business Vertical picklist values
3. `linkRequirementSetToVendorProgram()` - Link existing Requirement Set
4. `createRequirementSetFromExisting()` - Create new set from existing with changes
5. `getHistoricalRequirementGroupData()` - Get historical data for linking
6. `checkUserIsAdmin()` - Check if current user is admin (already exists)

### Modified Methods
1. `createVendorProgram()` - Accept Label, Retail Option, Business Vertical
2. `createOnboardingRequirementSet()` - Support naming convention
3. `createVendorProgramRequirement()` - Support inline creation

---

## Testing Checklist

### Step 2
- [ ] Search for existing Vendor Program works
- [ ] Create new Vendor Program prompts for Label, Retail Option, Business Vertical
- [ ] All fields are saved correctly
- [ ] Draft status is set

### Step 4
- [ ] Requirement Set selection works
- [ ] Confirmation flow works
- [ ] Change flow creates new set with correct naming
- [ ] Inline template creation works
- [ ] Requirement creation works
- [ ] Confirmation step works

### Step 5
- [ ] Historical linking works (5a)
- [ ] New record creation works (5b)
- [ ] Naming convention is correct
- [ ] All relationships are linked

### Step 6
- [ ] Yes/No prompt displays
- [ ] Yes proceeds to Required Credentials
- [ ] No skips to next step

### Step 8
- [ ] Existing Status Rules Engine selection works
- [ ] Confirmation works
- [ ] Change flow creates new engine
- [ ] Status Rule Builder is created

### Step 9
- [ ] Users see Recipient Group selection only
- [ ] Admins see Recipient Group creation UI
- [ ] Communication Template selection works
- [ ] Trigger condition configuration works
- [ ] Recipient Group linking works

### Step 10
- [ ] Vendor Program status is updated
- [ ] All relationships are finalized

---

## Migration Considerations

### Existing Data
- Existing onboarding processes may need to be updated
- Component library entries need to be updated
- Stage definitions need to be reordered

### Backward Compatibility
- Consider keeping old components for existing processes
- Or migrate existing processes to new flow

---

## Next Steps

1. ✅ Create restructuring plan document
2. ⏳ Update Step 2 with Label, Retail Option, Business Vertical
3. ⏳ Verify Step 3 Draft status
4. ⏳ Build Step 4 major component
5. ⏳ Continue with remaining phases

---

## Notes

- This is a significant restructuring that will require careful testing
- User vs Admin differentiation is critical
- Inline template creation is a key UX improvement
- Naming conventions must be consistent
- All relationships must be properly maintained

