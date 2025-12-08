# Vendor Program Onboarding System - Architecture Summary

## System Overview

The Vendor Program Onboarding System is a metadata-driven wizard that guides users through creating and configuring complete Vendor Programs in Salesforce. The system uses a **Component Library** pattern to dynamically render wizard steps based on configuration stored in custom metadata.

## Key Architectural Patterns

### 1. Strategy Pattern

**Purpose:** Encapsulate algorithms/behaviors that can vary independently, following the Open/Closed Principle.

**Implementation:**
- Strategy interfaces define contracts (`ActivationStrategy`, `EmailSenderStrategy`)
- Concrete strategies implement specific behaviors (`VendorCustomizationActivationStrategy`, `OrgWideSenderStrategy`)
- Strategy factories centralize strategy selection (`ActivationStrategyFactory`, `EmailSenderStrategyFactory`)
- Located in `strategies/` directory

**Benefits:**
- Add new behaviors without modifying existing code (OCP compliant)
- Isolate behavior changes to specific strategy classes
- Improve testability through independent strategy testing
- Eliminate switch/if-else statements that violate OCP

**Examples:**
- **Activation Strategies**: Different activation logic for different object types
- **Email Sender Strategies**: Different email sending configurations (CurrentUser, OrgWide)

### 2. Component Library Pattern

**Purpose:** Allows dynamic component selection without code changes.

**Implementation:**
- `Onboarding_Component_Library__c` custom object stores component metadata
- `Onboarding_Application_Process__c` defines the overall process
- `Onboarding_Application_Stage__c` links stages to components
- `onboardingStageRenderer` uses static conditional rendering to show components

**Benefits:**
- Add new components without modifying renderer code
- Create different processes with different stage sequences
- Reuse components across multiple processes

### 3. Layered Architecture

**Controller Layer** (`VendorOnboardingWizardController`)
- Exposes `@AuraEnabled` methods to LWC
- Handles security (`with sharing`)
- Provides cacheable methods for picklist values

**Service Layer** (`VendorOnboardingWizardService`)
- Business logic and validation
- Default value assignment
- Naming convention application
- Delegates to repository for data access

**Repository Layer** (`VendorOnboardingWizardRepository`)
- SOQL queries
- DML operations
- Data access patterns
- Relationship queries

**Benefits:**
- Separation of concerns
- Testability
- Maintainability
- Reusability

### 4. Context Passing Pattern

**Implementation:**
- `onboardingFlowEngine` maintains `_stepData` Map
- Each step fires `next` event with data
- Data stored in `_stepData` map
- `componentContext` getter passes data to components

**Benefits:**
- Data persistence across steps
- No need to re-query data
- Clean prop passing
- Supports resume functionality

### 5. Static Conditional Rendering

**Implementation:**
- LWC doesn't support dynamic component loading
- `onboardingStageRenderer` has all components statically defined
- Getters determine which component to show
- Only one component renders at a time

**Example:**
```javascript
get showVendorProgramOnboardingRequirementSetOrCreate() {
  return this.componentName === 'vendorProgramOnboardingRequirementSetOrCreate';
}
```

**Benefits:**
- Works within LWC limitations
- Type-safe component references
- Clear component mapping

## Data Flow

### Creation Flow

```
User Action
  ↓
LWC Component
  ↓
VendorOnboardingWizardController (@AuraEnabled)
  ↓
VendorOnboardingWizardService (Business Logic)
  ↓
VendorOnboardingWizardRepository (Data Access)
  ↓
Database (DML)
  ↓
Response back through layers
  ↓
LWC Component (UI Update)
```

### Context Passing Flow

```
Step 1: User completes step
  ↓
Component fires 'next' event with data
  ↓
onboardingFlowEngine receives event
  ↓
Data stored in _stepData map
  ↓
Progress saved to Onboarding_Application_Progress__c
  ↓
Next stage loaded
  ↓
componentContext getter extracts data from _stepData
  ↓
Data passed to next component via props
```

## Key Objects and Relationships

### Core Objects

1. **Vendor__c** - Business partner/supplier
2. **Vendor_Customization__c** - Vendor Program (configured program)
3. **Onboarding_Requirement_Set__c** - Reusable bundle of requirement templates
4. **Vendor_Program_Onboarding_Req_Template__c** - Requirement template definitions
5. **Vendor_Program_Requirement__c** - Requirement instances for specific programs
6. **Vendor_Program_Group__c** - Groups for organizing programs
7. **Vendor_Program_Requirement_Group__c** - Groups for organizing requirements
8. **Vendor_Program_Group_Member__c** - Junction object linking programs to groups
9. **Training_Requirement__c** - Training requirements for programs
10. **Training_System__c** - Training systems
11. **Onboarding_Status_Rules_Engine__c** - Status evaluation rules
12. **Recipient_Group__c** - Groups of users for communications
13. **Recipient_Group_Member__c** - Users in recipient groups
14. **Vendor_Program_Recipient_Group__c** - Links programs to recipient groups
15. **Communication_Template__c** - Email/notification templates

### Key Relationships

- `Vendor_Customization__c` → `Vendor__c` (Lookup)
- `Vendor_Program_Requirement__c` → `Vendor_Customization__c` (Lookup)
- `Vendor_Program_Requirement__c` → `Vendor_Program_Onboarding_Req_Template__c` (Lookup via `Requirement_Template__c`)
- `Vendor_Program_Onboarding_Req_Template__c` → `Onboarding_Requirement_Set__c` (Lookup)
- `Onboarding_Requirement_Set__c` → `Vendor_Customization__c` (Lookup, optional)
- `Vendor_Program_Group_Member__c` → `Vendor_Customization__c` (Lookup via `Required_Program__c`)
- `Vendor_Program_Group_Member__c` → `Vendor_Program_Group__c` (Lookup)
- `Vendor_Program_Group_Member__c` → `Vendor_Program_Requirement_Group__c` (Lookup via `Inherited_Program_Requirement_Group__c`)
- `Training_Requirement__c` → `Vendor_Customization__c` (Master-Detail)
- `Training_Requirement__c` → `Training_System__c` (Lookup)
- `Vendor_Program_Recipient_Group__c` → `Vendor_Customization__c` (Lookup)
- `Vendor_Program_Recipient_Group__c` → `Recipient_Group__c` (Lookup)
- `Recipient_Group_Member__c` → `Recipient_Group__c` (Lookup)
- `Recipient_Group_Member__c` → `User` (Lookup via `Recipient_User__c`)

## Naming Conventions

The system applies automatic naming conventions for new records:

- **Requirement Set:** `"Vendor Program Label - Onboarding Set"`
- **Vendor Program Group:** `"Vendor Program Label - Vendor Program Group"`
- **Requirement Group:** `"Vendor Program Label - Requirement Group"`

These conventions ensure consistent naming and make it easy to identify related records.

## Default Values

The system applies default values for new records:

- **Vendors:** `Active__c = false` (draft)
- **Vendor Programs:** `Status__c = 'Draft'`, `Active__c = false`
- **Requirement Sets:** `Status__c = 'Draft'`
- **Recipient Groups:** `Group_Type__c = 'User'`, `Is_Active__c = true`
- **Recipient Group Members:** `Member_Type__c = 'User'`, `Recipient_Type__c = 'To'`
- **Status Rules Engines:** `Active__c = true`
- **Training Systems:** `Active__c = true` (user-controlled via checkbox)

## Historical Data Reuse

The system supports reusing historical data from existing Requirement Sets:

1. **Group Members:** When a Requirement Set is selected, historical `Vendor_Program_Group_Member__c` records can be reused
2. **Status Rules Engines:** Historical `Onboarding_Status_Rules_Engine__c` records can be reused

This allows users to leverage existing configurations when creating similar Vendor Programs.

## Progress Tracking

The system tracks progress using:

1. **Onboarding_Application_Progress__c** - Stores current stage
2. **Onboarding_Application_Stage_Completion__c** - Audit log of completed stages
3. **_stepData Map** - In-memory storage for context passing

Users can pause and resume the wizard at any time.

## Security Model

- All classes use `with sharing` to respect sharing rules
- Field-level security enforced by Salesforce
- Record-level security based on object sharing rules
- User/Admin differentiation for certain steps (Step 9)

## Performance Optimizations

- **Parallel Loading:** Uses `Promise.all()` for concurrent data loading
- **Cacheable Methods:** Picklist values loaded via `@wire` with `cacheable=true`
- **Single Reloads:** Components reload data once instead of multiple times
- **Local State Updates:** UI updates immediately before API calls complete
- **Bulk Operations:** Service layer supports bulk operations when needed

## Error Handling

- **Centralized Error Parsing:** Reusable `handleError()` function in LWC
- **User-Friendly Messages:** Apex exceptions converted to readable messages
- **Toast Notifications:** All errors displayed via `ShowToastEvent`
- **Graceful Degradation:** Components handle missing data gracefully

## Extension Points

The system is designed for extensibility:

1. **New Components:** Add to Component Library and update `onboardingStageRenderer`
2. **New Processes:** Create new `Onboarding_Application_Process__c` with different stage sequences
3. **New Steps:** Create new LWC components following the established pattern
4. **New Apex Methods:** Add to appropriate layer (Controller → Service → Repository)

## Testing Strategy

- **Unit Tests:** Each layer has corresponding test classes
- **Integration Tests:** Test complete flows end-to-end
- **Test Factories:** Reusable test data factories for all objects
- **Coverage:** Maintain high code coverage for all classes

## Related Documentation

- [Vendor Program Onboarding Flow](./processes/vendor-program-onboarding-flow.md) - Complete flow architecture
- [Vendor Program Onboarding Wizard Components](./components/vendor-program-onboarding-wizard-components.md) - Component documentation
- [Apex Classes](./components/apex-classes.md) - Service layer documentation
- [Vendor Onboarding Wizard API](./api/vendor-onboarding-wizard-api.md) - API reference
- [Data Model](./architecture/data-model.md) - Object relationships

