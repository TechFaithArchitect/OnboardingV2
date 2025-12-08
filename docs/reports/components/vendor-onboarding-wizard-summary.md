# Vendor Onboarding Wizard - New Methods and Components Summary

This document summarizes the new methods and LWC components added to the Vendor Onboarding Wizard system.

## Overview

The Vendor Onboarding Wizard provides a multi-step workflow for setting up vendor programs, including vendors, vendor programs, groups, requirement sets, recipient groups, and related entities. The system follows a layered architecture:

- **Controller Layer**: `VendorOnboardingWizardController` - AuraEnabled methods for LWC components
- **Service Layer**: `VendorOnboardingWizardService` - Business logic and validation
- **Repository Layer**: `VendorOnboardingWizardRepository` - Data access operations

## New Apex Methods

### VendorOnboardingWizardRepository

**New Methods Added:**

1. **Vendor Program Requirement Operations:**
   - `searchVendorProgramRequirements(String)` - Searches vendor program requirements with extended field selection
   - `insertVendorProgramRequirement(Vendor_Program_Requirement__c)` - Inserts vendor program requirement

2. **Onboarding Status Rules Engine Operations:**
   - `searchStatusRulesEngines(String)` - Searches status rules engines with group relationships
   - `insertOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c)` - Inserts status rules engine

3. **Onboarding Status Rules Operations:**
   - `insertStatusRule(Onboarding_Status_Rule__c)` - Inserts status rule
   - `searchStatusRules(String)` - Searches status rules with parent and requirement relationships

4. **Communication Templates Operations:**
   - `fetchCommunicationTemplates()` - Fetches all communication templates
   - `linkCommunicationTemplate(Id, Id)` - Links template to vendor program

5. **Onboarding Requirement Set Operations:**
   - `insertOnboardingRequirementSet(Onboarding_Requirement_Set__c)` - Inserts requirement set
   - `fetchOnboardingRequirementSets()` - Fetches all requirement sets with status

6. **Onboarding Requirement Templates Operations:**
   - `insertOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c)` - Inserts requirement template
   - `fetchOnboardingRequirementTemplates(Id)` - Fetches templates for a requirement set
   - `assignRequirementTemplatesToRequirementGroup(Id, List<Id>)` - Assigns templates to requirement group

7. **Recipient Groups Operations:**
   - `searchRecipientGroups(String)` - Searches recipient groups
   - `insertRecipientGroup(Recipient_Group__c)` - Inserts recipient group
   - `insertRecipientGroupMember(Recipient_Group_Member__c)` - Inserts recipient group member

8. **Vendor Program Recipient Groups Operations:**
   - `searchVendorProgramRecipientGroups(String)` - Searches vendor program recipient groups
   - `insertVendorProgramRecipientGroupLink(Id, Id)` - Creates link between vendor program and recipient group

9. **Miscellaneous Operations:**
   - `getTerritoryRoleAssignments()` - Gets territory role assignments
   - `getAssignableUsers()` - Gets active users
   - `getPublicGroups()` - Gets public groups

### VendorOnboardingWizardService

**New Methods Added:**

All repository methods have corresponding service methods that add business logic:
- Default status values (Draft, Active = false)
- Field assignments before DML
- Delegation to repository layer

**Key Service Logic:**
- `createVendor()` - Sets `Active__c = false` (draft)
- `createVendorProgram()` - Sets `Vendor__c`, `Active__c = false`, `Status__c = 'Draft'`
- `createOnboardingRequirementSet()` - Sets `Status__c = 'Draft'`
- `createVendorProgramRecipientGroupLink()` - Sets `Status__c = 'Draft'` on link record
- `finalizeVendorProgram()` - Links vendor program to all related entities

### VendorOnboardingWizardController

**New Methods Added:**

All service methods have corresponding AuraEnabled controller methods:
- Search methods are `@AuraEnabled(cacheable=true)`
- Create/update methods are not cacheable (perform DML)

## New LWC Components

### vendorProgramOnboardingVendorProgramSearchOrCreate

**Purpose:** Step 2 in the wizard - Search or create vendor program

**Features:**
- Search existing vendor programs
- Create new vendor programs
- Radio button selection
- Dispatches vendor program ID to next step

**Key Methods:**
- `searchVendorPrograms()` - Searches via Apex
- `createProgram()` - Creates new program
- `proceedNext()` - Advances to next step

### vendorProgramOnboardingVendorProgramCreate

**Purpose:** Step 5 in the wizard - Finalize vendor program setup

**Features:**
- Finalizes vendor program by linking all entities
- Uses lightning-record-form for editing
- Links vendor, program group, and requirement group

**Key Methods:**
- `finalizeProgram()` - Calls Apex to link all entities

### vendorProgramOnboardingVendorProgramRequirementGroup

**Purpose:** Step 4 in the wizard - Select or create requirement group

**Features:**
- Search existing requirement groups
- Create new requirement groups
- Radio button selection
- Dispatches requirement group ID to next step

**Key Methods:**
- `searchGroups()` - Searches via Apex
- `createGroup()` - Creates new group
- `proceedNext()` - Advances to next step

### vendorProgramOnboardingRecipientGroup

**Purpose:** Select or create recipient group

**Features:**
- Search existing recipient groups
- Create new recipient groups
- Radio button selection
- Requires vendorProgramId for creation
- Dispatches recipient group ID to next step

**Key Methods:**
- `searchGroups()` - Searches via Apex
- `createGroup()` - Creates new group (requires vendorProgramId)
- `proceedNext()` - Advances to next step

## Wizard Flow

The vendor onboarding wizard follows this flow:

1. **Step 1**: `vendorProgramOnboardingVendor` - Select/create vendor
2. **Step 2**: `vendorProgramOnboardingVendorProgramSearchOrCreate` - Select/create vendor program
3. **Step 3**: `vendorProgramOnboardingVendorProgramGroup` - Select/create program group
4. **Step 4**: `vendorProgramOnboardingVendorProgramRequirementGroup` - Select/create requirement group
5. **Step 5**: `vendorProgramOnboardingVendorProgramCreate` - Finalize vendor program

## Data Flow

```
LWC Component
    ↓ (Apex call)
VendorOnboardingWizardController
    ↓ (delegates to)
VendorOnboardingWizardService
    ↓ (business logic)
VendorOnboardingWizardRepository
    ↓ (DML/SOQL)
Salesforce Database
```

## Key Patterns

1. **Search and Create Pattern**: All wizard components follow a consistent pattern:
   - Search input field
   - Search button
   - Radio group for existing records
   - Input field for new record
   - Create button
   - Next button (disabled until selection/creation)

2. **Draft Status Pattern**: New records are created with draft/inactive status:
   - Vendors: `Active__c = false`
   - Vendor Programs: `Active__c = false`, `Status__c = 'Draft'`
   - Requirement Sets: `Status__c = 'Draft'`
   - Recipient Group Links: `Status__c = 'Draft'`

3. **Event-Driven Navigation**: Components communicate via custom events:
   - `next` event with detail object containing IDs
   - Parent components handle navigation

## Notes

- **VendorOnboardingWizardOrchestrator**: No orchestrator class was found. The orchestration logic appears to be handled directly in the service layer or through the wizard flow components.

- **Sharing**: All classes use `with sharing` to enforce sharing rules.

- **Error Handling**: Components include try-catch blocks for Apex calls and console error logging.

## Related Documentation

- [Apex Classes](./apex-classes.md) - Detailed method documentation
- [LWC Components](./lwc-components.md) - Detailed component documentation
- [Architecture Overview](../architecture/overview.md) - System architecture
- [Apex Patterns](../architecture/apex-patterns.md) - Architectural patterns

