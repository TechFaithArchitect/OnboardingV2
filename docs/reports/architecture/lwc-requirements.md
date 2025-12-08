# LWC Component Requirements Analysis

Based on the architectural overview and data flow, this document identifies which LWC components are needed for user interaction and which ones exist.

## Core Flow Components (Required for Onboarding Flow)

### ✅ Entry Point Components

1. **vendorProgramOnboardingFlow** ✅ EXISTS
   - **Purpose**: Entry point from Vendor Program record page
   - **User Interaction**: User clicks to start onboarding
   - **Location**: `force-app/main/default/lwc/vendorProgramOnboardingFlow/`
   - **Status**: ✅ Complete

2. **onboardingFlowEngine** ✅ EXISTS
   - **Purpose**: Main flow controller with progress tracking
   - **User Interaction**: Manages stage navigation, saves progress
   - **Location**: `force-app/main/default/lwc/onboardingFlowEngine/`
   - **Status**: ✅ Complete

3. **onboardingApplicationFlow** ✅ EXISTS
   - **Purpose**: Alternative flow controller (standalone, no progress tracking)
   - **User Interaction**: Manages stage navigation
   - **Location**: `force-app/main/default/lwc/onboardingApplicationFlow/`
   - **Status**: ✅ Complete

4. **onboardingStageRenderer** ✅ EXISTS
   - **Purpose**: Dynamically renders stage components
   - **User Interaction**: Displays appropriate stage component
   - **Location**: `force-app/main/default/lwc/onboardingStageRenderer/`
   - **Status**: ✅ Complete

### ✅ Stage Components (All Required - All Exist)

All 10 stage components mentioned in the architecture exist:

1. **vendorProgramOnboardingVendor** ✅ EXISTS
   - **Purpose**: Select/create vendor
   - **User Interaction**: Search/select vendor, create new vendor
   - **Status**: ✅ Complete

2. **vendorProgramOnboardingVendorProgramSearchOrCreate** ✅ EXISTS
   - **Purpose**: Search or create vendor program
   - **User Interaction**: Search existing programs, create new
   - **Status**: ✅ Complete

3. **vendorProgramOnboardingVendorProgramCreate** ✅ EXISTS
   - **Purpose**: Create new vendor program
   - **User Interaction**: Form to create vendor program
   - **Status**: ✅ Complete

4. **vendorProgramOnboardingVendorProgramGroup** ✅ EXISTS
   - **Purpose**: Assign program group
   - **User Interaction**: Select program group
   - **Status**: ✅ Complete

5. **vendorProgramOnboardingVendorProgramRequirementGroup** ✅ EXISTS
   - **Purpose**: Assign requirement group
   - **User Interaction**: Select requirement group
   - **Status**: ✅ Complete

6. **vendorProgramOnboardingVendorProgramRecipientGroup** ✅ EXISTS
   - **Purpose**: Assign recipient group
   - **User Interaction**: Select recipient group
   - **Status**: ✅ Complete

7. **vendorProgramOnboardingRecipientGroup** ✅ EXISTS
   - **Purpose**: Configure recipient group details
   - **User Interaction**: Edit recipient group configuration
   - **Status**: ✅ Complete

8. **vendorProgramOnboardingRecipientGroupMembers** ✅ EXISTS
   - **Purpose**: Add members to recipient group
   - **User Interaction**: Add/remove members
   - **Status**: ✅ Complete

9. **vendorProgramOnboardingRequiredCredentials** ✅ EXISTS
   - **Purpose**: Manage required credentials
   - **User Interaction**: Configure credential requirements
   - **Status**: ✅ Complete

10. **vendorProgramOnboardingTrainingRequirements** ✅ EXISTS
    - **Purpose**: Manage training requirements
    - **User Interaction**: Configure training assignments
    - **Status**: ✅ Complete

## Management Components (Required for Admin/User Management)

### ✅ Requirements Management

1. **onboardingRequirementsPanel** ✅ EXISTS
   - **Purpose**: View and manage onboarding requirements
   - **User Interaction**: View requirements, update status, trigger evaluation
   - **Location**: `force-app/main/default/lwc/onboardingRequirementsPanel/`
   - **Status**: ✅ Complete
   - **Usage**: Add to Onboarding record page

### ✅ Rules Configuration (Admin)

1. **onboardingStatusRulesEngine** ✅ EXISTS
   - **Purpose**: Admin UI for configuring status rules
   - **User Interaction**: Select groups, edit rules, save changes
   - **Location**: `force-app/main/default/lwc/onboardingStatusRulesEngine/`
   - **Status**: ✅ Complete

2. **onboardingStatusRuleList** ✅ EXISTS
   - **Purpose**: Display list of status rules
   - **User Interaction**: View rules, filter by group
   - **Location**: `force-app/main/default/lwc/onboardingStatusRuleList/`
   - **Status**: ✅ Complete

3. **onboardingStatusRulesManager** ✅ EXISTS
   - **Purpose**: Manager/wrapper for rules components
   - **User Interaction**: Container component
   - **Location**: `force-app/main/default/lwc/onboardingStatusRulesManager/`
   - **Status**: ✅ Complete

4. **onboardingRuleModal** ✅ EXISTS
   - **Purpose**: Modal for creating/editing rules
   - **User Interaction**: Create/edit rule in modal
   - **Location**: `force-app/main/default/lwc/onboardingRuleModal/`
   - **Status**: ✅ Complete

5. **requirementConditionsList** ✅ EXISTS
   - **Purpose**: Display requirement conditions for rules
   - **User Interaction**: View/edit rule conditions
   - **Location**: `force-app/main/default/lwc/requirementConditionsList/`
   - **Status**: ✅ Complete

### ✅ ECC Management

1. **onboardingAppVendorProgramECCManager** ✅ EXISTS
   - **Purpose**: Manage External Contact Credentials
   - **User Interaction**: Link credential types, create new types
   - **Location**: `force-app/main/default/lwc/onboardingAppVendorProgramECCManager/`
   - **Status**: ✅ Complete
   - **Usage**: Add to Vendor Program record page

### ✅ Header/Activation Components

1. **onboardingAppHeaderBar** ✅ EXISTS
   - **Purpose**: Header bar with activation/deactivation
   - **User Interaction**: Activate/deactivate records, view status
   - **Location**: `force-app/main/default/lwc/onboardingAppHeaderBar/`
   - **Status**: ✅ Complete

### ✅ Wizard Components

1. **onboardingAppRequirementSetupWizard** ✅ EXISTS
   - **Purpose**: Wizard for setting up requirement sets and templates
   - **User Interaction**: Multi-step wizard for requirement setup
   - **Location**: `force-app/main/default/lwc/onboardingAppRequirementSetupWizard/`
   - **Status**: ✅ Complete

### ✅ Utility Components

1. **vendorProgramHighlights** ✅ EXISTS
   - **Purpose**: Display vendor program highlights/summary
   - **User Interaction**: View summary information
   - **Location**: `force-app/main/default/lwc/vendorProgramHighlights/`
   - **Status**: ✅ Complete

2. **vendorSelector** ✅ EXISTS
   - **Purpose**: Reusable vendor selector component
   - **User Interaction**: Search/select vendors
   - **Location**: `force-app/main/default/lwc/vendorSelector/`
   - **Status**: ✅ Complete

## Potential Missing Components (Based on Architecture)

### ❓ Onboarding Record View/Management

**Potential Need**: A component to view and manage Onboarding records

**Analysis**:
- The architecture mentions `Onboarding__c` records are created and managed
- Users need to view onboarding status, requirements, and progress
- **Current State**: `onboardingRequirementsPanel` exists for requirements, but there may be a need for:
  - **onboardingRecordView** or **onboardingDashboard** - View onboarding record details, status, progress
  - **onboardingStatusViewer** - Display current onboarding status and history

**Recommendation**: 
- If users primarily interact with Onboarding records via record pages, standard Lightning record pages may be sufficient
- If custom UI is needed, consider creating:
  - `onboardingRecordDashboard` - Comprehensive view of onboarding record
  - `onboardingProgressTracker` - Visual progress indicator

### ❓ Vendor Onboarding Wizard (Complete Flow)

**Potential Need**: A complete wizard for vendor onboarding setup

**Analysis**:
- Architecture mentions vendor onboarding wizard operations
- `VendorOnboardingWizardController` exists with many methods
- **Current State**: Individual stage components exist, but there may be a need for:
  - **vendorOnboardingWizard** - Complete wizard that orchestrates all vendor setup steps
  - This would be different from the flow-based approach

**Recommendation**:
- If the flow-based approach (`vendorProgramOnboardingFlow` → `onboardingFlowEngine`) is the primary method, this may not be needed
- If a standalone wizard is preferred, consider creating:
  - `vendorOnboardingWizard` - Multi-step wizard component

### ❓ Order Status Viewer

**Status**: ⚠️ EXISTS IN UNPACKAGED
- **Location**: `force-app/unpackaged/lwc/onboardingOrderStatusViewer/`
- **Recommendation**: Move to main/default if it's part of core functionality

### ❓ Status Rule Form

**Status**: ⚠️ EXISTS IN UNPACKAGED
- **Location**: `force-app/unpackaged/lwc/onboardingStatusRuleForm/`
- **Recommendation**: Move to main/default if it's part of core functionality

### ❓ ECC Component (Unpackaged)

**Status**: ⚠️ EXISTS IN UNPACKAGED
- **Location**: `force-app/unpackaged/lwc/onboardingECC/`
- **Recommendation**: Determine if this is duplicate of `onboardingAppVendorProgramECCManager` or serves different purpose

## Summary

### ✅ All Core Components Exist

**Flow Components**: 4/4 ✅
- Entry point, flow engine, stage renderer all exist

**Stage Components**: 10/10 ✅
- All stage components mentioned in architecture exist

**Management Components**: 8/8 ✅
- Requirements panel, rules engine, ECC manager, header bar all exist

**Utility Components**: 2/2 ✅
- Highlights and vendor selector exist

### ⚠️ Components in Unpackaged (Need Review)

1. `onboardingOrderStatusViewer` - Move to main/default if needed
2. `onboardingStatusRuleForm` - Move to main/default if needed
3. `onboardingECC` - Review if duplicate or different purpose

### ❓ Potential Missing Components (Based on User Needs)

1. **Onboarding Record Dashboard** - If custom UI needed for Onboarding records
2. **Onboarding Progress Tracker** - Visual progress indicator
3. **Vendor Onboarding Wizard** - If standalone wizard needed (vs flow-based)

## Recommendations

### High Priority
1. ✅ **All core components exist** - No action needed
2. ⚠️ **Review unpackaged components** - Determine if they should be moved to main/default

### Medium Priority
1. ❓ **Onboarding Record Dashboard** - Create if users need custom UI for viewing onboarding records
2. ❓ **Onboarding Progress Tracker** - Create if visual progress indicator is needed

### Low Priority
1. ❓ **Vendor Onboarding Wizard** - Only needed if standalone wizard approach is preferred over flow-based

## User Interaction Flow Summary

### Primary User Flow (All Components Exist ✅)

```
1. User navigates to Vendor Program record
   ↓
2. vendorProgramOnboardingFlow component loads
   ↓
3. onboardingFlowEngine manages flow
   ↓
4. onboardingStageRenderer displays stage components
   ↓
5. User completes stages (10 stage components available)
   ↓
6. Progress saved automatically
   ↓
7. User can view requirements via onboardingRequirementsPanel
   ↓
8. Status evaluated automatically via flows
```

### Admin Flow (All Components Exist ✅)

```
1. Admin navigates to rules configuration
   ↓
2. onboardingStatusRulesEngine for rule management
   ↓
3. onboardingStatusRuleList for viewing rules
   ↓
4. onboardingRuleModal for creating/editing
   ↓
5. requirementConditionsList for managing conditions
```

## Conclusion

**All required LWC components for user interaction based on the architectural overview exist and are properly organized.**

The only gaps are:
1. Components in `unpackaged/` that may need to be moved to `main/default/`
2. Potential additional components for enhanced UX (dashboard, progress tracker) that are not strictly required by the architecture

