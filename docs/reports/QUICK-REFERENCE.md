# Vendor Program Onboarding - Quick Reference Guide

## 14-Step Flow Overview

| Step | Component | Purpose | Key Outputs |
|------|-----------|---------|-------------|
| 2 | `vendorProgramOnboardingVendor` | Select/Create Vendor | `vendorId` |
| 3 | `vendorProgramOnboardingVendorProgramSearchOrCreate` | Search/Create Vendor Program | `vendorProgramId` |
| 4 | `vendorProgramOnboardingRequirementSet` | Select/Create Requirement Set | `requirementSetId` |
| 5 | `vendorProgramOnboardingReqTemplate` | Create Requirement Template | `requirementTemplateId`, `requirementGroupId` |
| 6 | `vendorProgramOnboardingVendorProgramRequirements` | Create Vendor Program Requirements | Requirements created |
| 7 | `vendorProgramOnboardingVendorProgramGroup` | Select/Create Vendor Program Group | `programGroupId` |
| 8 | `vendorProgramOnboardingVendorProgramRequirementGroup` | Select/Create Requirement Group | `requirementGroupId` |
| 9 | `vendorProgramOnboardingRequiredCredentials` | Configure Credentials (Conditional) | `credentialsNeeded` |
| 10 | `vendorProgramOnboardingTrainingRequirements` | Configure Training | Training Requirements |
| 11 | `vendorProgramOnboardingVendorProgramSearchOrCreate` | Search/Create Vendor Program | `vendorProgramId` |
| 12 | `vendorProgramOnboardingStatusRulesEngine` | Select/Create Status Rules Engine | `statusRulesEngineId` |
| 13 | `vendorProgramOnboardingVendorProgramCreate` | Finalize Vendor Program | `vendorProgramId` |
| 14 | `vendorProgramOnboardingCommunicationTemplate` | Link Communication Template | Communication Template linked |
| 15 | `vendorProgramOnboardingRecipientGroup` | Create/Manage Recipient Groups (Admin) | `recipientGroupId` |
| 16 | `vendorProgramOnboardingFinalize` | Complete Setup | Navigation to Vendor Program |

**Note:** All step components extend `onboardingStepBase` for consistent navigation, validation, and event handling.

## Component Context Passing

Data flows between steps via `onboardingFlowEngine`'s `_stepData` map:

```javascript
// Step 1 → Step 2
{ vendorId: String }

// Step 2 → Step 4
{ vendorProgramId: String }

// Step 4 → Step 5
{ requirementSetId: String, requirementTemplateId: String }

// Step 5 → Step 8
{ groupMemberId: String }

// Step 8 → Step 9
{ statusRulesEngineId: String }

// Step 9 → Step 10
{ recipientGroupId: String }
```

## Naming Conventions

- **Requirement Set:** `"Vendor Program Label - Onboarding Set"`
- **Vendor Program Group:** `"Vendor Program Label - Vendor Program Group"`
- **Requirement Group:** `"Vendor Program Label - Requirement Group"`

## Default Values

- **Vendors:** `Active__c = false`
- **Vendor Programs:** `Status__c = 'Draft'`, `Active__c = false`
- **Requirement Sets:** `Status__c = 'Draft'`
- **Recipient Groups:** `Group_Type__c = 'User'`, `Is_Active__c = true`
- **Recipient Group Members:** `Member_Type__c = 'User'`, `Recipient_Type__c = 'To'`
- **Status Rules Engines:** `Active__c = true`
- **Training Systems:** `Active__c = true` (user-controlled)

## Key Apex Methods

### Vendor Management
- `VendorOnboardingWizardController.searchVendors()`
- `VendorOnboardingWizardController.createVendor()`

### Vendor Program Management
- `VendorOnboardingWizardController.searchVendorPrograms()`
- `VendorOnboardingWizardController.createVendorProgram()`
- `VendorOnboardingWizardController.getRetailOptionPicklistValues()` (cacheable)
- `VendorOnboardingWizardController.getBusinessVerticalPicklistValues()` (cacheable)

### Requirement Set Management
- `VendorOnboardingWizardController.searchOnboardingRequirementSets()`
- `VendorOnboardingWizardController.linkRequirementSetToVendorProgram()`
- `VendorOnboardingWizardController.createRequirementSetFromExisting()`
- `VendorOnboardingWizardController.getTemplatesForRequirementSet()`
- `VendorOnboardingWizardController.createRequirementFromTemplate()`

### Requirement Group Linking
- `VendorOnboardingWizardController.getHistoricalGroupMembers()`
- `VendorOnboardingWizardController.createRequirementGroupComponents()`

### Status Rules Engine
- `VendorOnboardingWizardController.getHistoricalStatusRulesEngines()`
- `VendorOnboardingWizardController.searchStatusRulesEngines()`
- `VendorOnboardingWizardController.createOnboardingStatusRulesEngine()`

### Recipient Groups
- `VendorOnboardingWizardController.searchRecipientGroups()`
- `VendorOnboardingWizardController.createRecipientGroup()`
- `VendorOnboardingWizardController.createRecipientGroupMember()`
- `VendorOnboardingWizardController.getRecipientGroupsForVendorProgram()`
- `VendorOnboardingWizardController.getRecipientGroupMembers()`
- `VendorOnboardingWizardController.getAssignableUsers()`

### Communication Templates
- `VendorOnboardingWizardController.getCommunicationTemplates()`
- `VendorOnboardingWizardController.createVendorProgramRecipientGroupWithTemplate()`

## Common Patterns

### Base Class Pattern
All step components extend `onboardingStepBase`:
- **Navigation:** `dispatchNextEvent(detail)`, `dispatchBackEvent()`
- **Validation:** `get canProceed()` returns boolean
- **Toast:** `this.showToast(title, message, variant)`
- **Title:** `stepName` property generates card title

### Inline Creation
Many components support inline creation of related records:
- Training Systems (Step 7)
- Training Requirements (Step 7)
- Requirement Templates (Step 4)
- Requirements from Templates (Step 4)
- Recipient Groups (Step 9)
- Recipient Group Members (Step 9)

### Historical Data Reuse
- Group Members (Step 5)
- Status Rules Engines (Step 8)

### Multi-View Components
- `vendorProgramOnboardingRequirementSetOrCreate` (4 views)
- `vendorProgramOnboardingStatusRulesEngine` (4 views)
- `vendorProgramOnboardingRecipientGroup` (3 views)

## User vs Admin Flow

| Step | User | Admin |
|------|------|-------|
| 1-8 | Same | Same |
| 9 | Skip | Create/Manage Recipient Groups |
| 10 | Select Template/Group/Condition | Select Template/Group/Condition |

## Key Objects Created

1. `Vendor__c` (Step 1)
2. `Vendor_Customization__c` (Step 2)
3. `Onboarding_Requirement_Set__c` (Step 4, optional)
4. `Vendor_Program_Onboarding_Req_Template__c` (Step 4)
5. `Vendor_Program_Requirement__c` (Step 4)
6. `Vendor_Program_Group__c` (Step 5)
7. `Vendor_Program_Requirement_Group__c` (Step 5)
8. `Vendor_Program_Group_Member__c` (Step 5)
9. `Required_Credential__c` (Step 6, optional)
10. `Training_System__c` (Step 7, optional)
11. `Training_Requirement__c` (Step 7)
12. `Onboarding_Status_Rules_Engine__c` (Step 8)
13. `Recipient_Group__c` (Step 9, Admin only)
14. `Recipient_Group_Member__c` (Step 9, Admin only)
15. `Vendor_Program_Recipient_Group__c` (Step 9, 10)

## Auto-Number Fields

These fields are auto-number and cannot be set directly:
- `Training_Requirement__c.Name`
- `Required_Credential__c.Name`
- `Onboarding_Requirement_Set__c.Name`
- `Vendor_Program_Requirement__c.Name`

## Related Documentation

- [Vendor Program Onboarding Flow](./processes/vendor-program-onboarding-flow.md) - Complete flow architecture
- [Vendor Program Onboarding Wizard Components](./components/vendor-program-onboarding-wizard-components.md) - Component details
- [Vendor Onboarding Wizard API](./api/vendor-onboarding-wizard-api.md) - API reference
- [Onboarding Workflow Guide](./user-guides/onboarding-workflow.md) - User guide
- [Architecture Summary](./ARCHITECTURE-SUMMARY.md) - System architecture

