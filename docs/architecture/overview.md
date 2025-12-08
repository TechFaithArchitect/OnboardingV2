# System Architecture Overview

## Introduction

The Onboarding V2 system is a comprehensive, metadata-driven onboarding framework built on Salesforce. It provides a flexible, configurable solution for managing vendor program onboarding processes with full auditability, progress tracking, and dynamic flow rendering.

## High-Level Architecture

The system follows a **layered architecture pattern** with three main layers:

┌─────────────────────────────────────────┐
│ APPLICATION LAYER │
│ (Flows, LWC Components, UI) │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ BUSINESS LOGIC LAYER │
│ (Apex Services, Orchestrators) │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ DOMAIN LAYER │
│ (Domain Flows, Data Operations) │
└─────────────────────────────────────────┘


### Application Layer

The Application Layer handles user interactions and orchestrates business processes:

- **Lightning Web Components (LWC)**: Dynamic UI components for onboarding flows
- **Salesforce Flows**: High-level process automation (e.g., `APP_Onboarding.flow`)
- **Record Pages**: Lightning pages that host onboarding components

**Key Components:**
- `onboardingHomeDashboard` - Central home page dashboard for onboarding overview
- `onboardingFlowEngine` - Main flow controller
- `onboardingStageRenderer` - Dynamic component renderer
- `vendorProgramOnboardingFlow` - Vendor-specific wrapper
- `onboardingRequirementsPanel` - Requirements management UI
- `onboardingStatusRulesEngine` - Rules configuration UI

### Business Logic Layer

The Business Logic Layer contains the core business rules and orchestration:

- **Services**: Business logic services (e.g., `OnboardingApplicationService`, `OnboardingRulesService`)
- **Orchestrators**: Coordinate multiple services (e.g., `OnboardingAppActivationOrchestrator`)
- **Controllers**: LWC-facing Apex controllers
- **Handlers**: Trigger and event handlers
- **Evaluators**: Rule evaluation engines (e.g., `OnboardingStatusEvaluator`, `OnboardingRuleEvaluator`)

**Key Classes:**
- `OnboardingApplicationService` - Process and stage management
- `OnboardingRulesService` - Rules engine data access
- `OnboardingStatusEvaluator` - Status evaluation logic
- `OnboardingAppActivationOrchestrator` - Activation workflow orchestration

### Domain Layer

The Domain Layer handles data operations and domain-specific logic:

- **Domain Flows**: Subflows for specific data operations (e.g., `DOMAIN_Onboarding_SFL_*`)
- **Record-Triggered Flows**: Before/after save flows for data validation
- **Data Integrity**: Duplicate prevention, unique key creation

**Naming Convention:**
- `DOMAIN_[Object]_SFL_[Operation]_[Description]` - Subflows
- `DOMAIN_[Object]_RCD_[Trigger]_[Description]` - Record-triggered flows

## Key Design Patterns

### 1. Metadata-Driven Configuration

The system uses Custom Objects to define onboarding processes dynamically:

- `Onboarding_Application_Process__c` - Defines reusable onboarding flows
- `Onboarding_Application_Stage__c` - Defines stages within a process
- `Onboarding_Component_Library__c` - Maps LWC components to metadata
- `Onboarding_Application_Progress__c` - Tracks user progress
- `Onboarding_Application_Stage_Completion__c` - Audit log of completed stages

### 2. Rules Engine Pattern

Status evaluation uses a configurable rules engine:

- `Onboarding_Status_Rules_Engine__c` - Rule definitions
- `Onboarding_Status_Rule__c` - Individual rule conditions
- `OnboardingRuleEvaluator` - Rule evaluation logic
- `OnboardingExpressionEngine` - Expression parsing and evaluation

### 3. Validation Rule Pattern

Activation and validation use a registry pattern:

- `OnboardingAppRuleRegistry` - Central registry of validation rules
- `OnboardingAppValidationRule` - Interface for validation rules
- Rule implementations per object (e.g., `RequireParentVersionOnActivationRule`)

### 4. Campaign/Campaign Member Pattern

The system uses the **Campaign/Campaign Member** pattern (similar to Salesforce Campaigns and Account Engagement) for many-to-many relationships. This pattern is ideal for:

- **Many-to-many relationships** between parent objects and members
- **Collaborative workflows** where multiple users work on different parts
- **Versioning support** with Draft/Active/Deprecated statuses
- **Flexible membership attributes** stored on the junction object

**Example Implementation:**
```
Vendor_Program_Group__c (Parent)    Vendor_Program_Group_Member__c (Junction)
├─ Name                              ├─ Vendor_Program_Group__c (lookup)
├─ Active__c                         ├─ Required_Program__c (lookup to Vendor_Customization__c)
├─ Status__c                         ├─ Inherited_Program_Requirement_Group__c (lookup)
└─ Previous_Version__c               ├─ Is_Target__c (member attribute)
                                     └─ Active__c (member attribute)
```

**Benefits:**
- One Vendor Program can belong to multiple Groups
- One Group can contain multiple Vendor Programs
- Junction object stores relationship-specific attributes
- Supports collaborative workflows with versioning

**Objects Using This Pattern:**
- `Vendor_Program_Group__c` / `Vendor_Program_Group_Member__c`
- `Vendor_Program_Requirement_Group__c` / `Vendor_Program_Requirement_Group_Member__c`
- `Recipient_Group__c` / `Recipient_Group_Member__c`

### 5. Versioning Pattern

The system implements versioning to support collaborative, multi-user workflows where users may start but not finish onboarding processes. This allows:

- **Draft versions** for work-in-progress
- **Active versions** for production use
- **Deprecated versions** for historical tracking
- **Version lineage** through `Previous_Version__c` field

**Versioning Fields:**
- `Status__c` - Draft, Active, Deprecated
- `Previous_Version__c` - Links to parent version (tracks lineage)
- `Active__c` - Boolean flag for active status

**Versioning Rules:**
1. Draft records cannot be Active (auto-corrected)
2. Only one Active version per parent context
3. Version lineage maintained through `Previous_Version__c`

**Objects Supporting Versioning:**
- `Vendor_Customization__c` (Vendor Programs)
- `Vendor_Program_Recipient_Group__c`
- `Vendor_Program_Onboarding_Req_Template__c`
- Other objects with `Status__c`, `Previous_Version__c`, `Active__c` fields

**Use Case:**
Multiple users can work on different parts of onboarding simultaneously:
- User A creates a Draft vendor program
- User B adds requirements to the Draft
- User C configures recipient groups
- When ready, the Draft is activated, becoming the Active version
- Previous Active version is automatically deactivated

### 6. Service Layer Pattern

Business logic is organized into service classes:

- **Services**: Core business logic (`*Service.cls`)
- **Repositories**: Data access layer (`*Repo.cls`)
- **Orchestrators**: Coordinate multiple services (`*Orch.cls`)
- **Controllers**: LWC-facing APIs (`*Ctlr.cls`)

### 7. Base Class Pattern (LWC)

The Vendor Program Onboarding Wizard uses a base class pattern to eliminate code duplication:

- **Base Class**: `onboardingStepBase` - Provides common functionality for all step components
- **Inheritance**: All 14 wizard step components extend `OnboardingStepBase`
- **Benefits**: 
  - Eliminates ~700+ lines of duplicate code
  - Standardizes navigation, validation, and event handling
  - Ensures consistency across all steps
  - Makes adding new steps easier

**Key Features:**
- Footer navigation event handling
- Validation state dispatching
- Toast notification utility
- Dynamic card title generation
- Standardized event dispatching

**Required Overrides:**
- `get canProceed()` - Validation state
- `proceedToNext()` - Next navigation with data
- `stepName` - Step name for card title

## Data Flow

### Onboarding Flow Execution
User Action
↓
vendorProgramOnboardingFlow (LWC)
↓
OnboardingApplicationService.getProcessIdForVendorProgram()
↓
onboardingFlowEngine (LWC)
↓
OnboardingApplicationService.getStagesForProcess()
↓
onboardingStageRenderer (LWC) - Dynamically renders stage components
↓
Stage-specific LWC (e.g., vendorProgramOnboardingVendor)
↓
OnboardingApplicationService.saveProgress() - Persists progress

### Status Evaluation Flow

Onboardingc Record Change
↓
Onboarding_Record_Trigger_Update_Onboarding_Status (Flow)
↓
OnboardingStatusEvaluator.evaluateAndApplyStatus()
↓
OnboardingRulesService.getRulesForGroups()
↓
OnboardingRuleEvaluator.evaluateRule() - For each rule
↓
OnboardingExpressionEngine.evaluate() - Expression evaluation
↓
Update Onboardingc.Onboarding_Status_c

## Technology Stack

- **Platform**: Salesforce Lightning Platform
- **UI Framework**: Lightning Web Components (LWC)
- **Backend**: Apex
- **Automation**: Salesforce Flows
- **Data Model**: Custom Objects

## Scalability Considerations

- **Metadata-Driven**: Processes can be configured without code changes
- **Modular Components**: Stage components are independent and reusable
- **Progress Tracking**: Users can resume onboarding flows
- **Audit Trail**: Complete history of stage completions
- **Rules Engine**: Status evaluation rules are configurable

## Security

- **Sharing Model**: Controlled by parent (Account) for Onboarding records
- **Field-Level Security**: Enforced via profiles and permission sets
- **Apex Sharing**: Uses `with sharing` for data access control
- **Validation Rules**: Prevent invalid data entry

## Related Documentation

- [Data Model](./data-model.md) - Complete object definitions, relationships, and patterns
- [Layered Architecture Details](./layers.md) - Layer responsibilities and communication
- [Apex Patterns](./apex-patterns.md) - Apex class architectural patterns and conventions
- [Component Documentation](../components/lwc-components.md) - LWC component details
