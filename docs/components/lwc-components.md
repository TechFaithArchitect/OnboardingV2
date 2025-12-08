# Lightning Web Components

## Core Flow Components

### onboardingApplicationFlow

**Location:** `force-app/main/default/lwc/onboardingApplicationFlow/`

**Purpose:** Main controller for the onboarding flow engine. Dynamically loads and manages onboarding stages based on metadata.

**Key Features:**
- Loads stages from `Onboarding_Application_Process__c`
- Tracks current stage index
- Handles navigation (next/back)
- Parallel loading of stages and process details
- Computed properties for current stage, component name, and context

**API:**
- `@api processId` - ID of the onboarding process
- `@api vendorProgramId` - ID of the vendor program being onboarded

**Computed Properties:**
- `currentComponentName` - Component API name from current stage
- `currentStage` - Current stage record
- `componentContext` - Context object with vendorProgramId and stageId
- `currentStageLabel` - Display label for current stage
- `isFirst` - Whether on first stage
- `isLast` - Whether on last stage

**Methods:**
- `loadProcess()` - Loads stages and process details in parallel
- `handleNext()` - Advances to next stage
- `handleBack()` - Returns to previous stage

**Dependencies:**
- `OnboardingApplicationService.getStagesForProcess()`
- `OnboardingApplicationService.getProcessDetails()`

**Note:** This is a standalone flow engine component. The `onboardingFlowEngine` component is used by `vendorProgramOnboardingFlow` and includes progress persistence.

### onboardingFlowEngine

**Location:** `force-app/main/default/lwc/onboardingFlowEngine/`

**Purpose:** Alternative/legacy flow engine implementation with progress tracking.

**Key Features:**
- Similar to `onboardingApplicationFlow` but includes progress persistence
- Resumes from saved progress
- Tracks completion status
- **Status Display**: Uses `getUserFacingStage()` to display simplified Vendor Program statuses for end users
  - ⚠️ **ONLY for Vendor_Customization__c.Status__c** - NOT for Dealer Onboarding statuses
  - Maps technical statuses (Draft, In Process) to user-friendly stages (In Progress, Review Pending, Completed)
  - Admins see technical statuses unchanged

**API:**
- `@api processId` - ID of the onboarding process
- `@api vendorProgramId` - ID of the vendor program being onboarded

**Properties:**
- `userFacingStatus` - User-friendly status label (simplified for end users, technical for admins)

**Dependencies:**
- `OnboardingApplicationService.getStagesForProcess()`
- `OnboardingApplicationService.getProgress()`
- `OnboardingApplicationService.saveProgress()`
- `OnboardingApplicationService.getUserFacingStage()` - For Vendor Program status simplification

### onboardingStageRenderer

**Location:** `force-app/main/default/lwc/onboardingStageRenderer/`

**Purpose:** Dynamically renders stage-specific LWC components based on metadata.

**Key Features:**
- Dynamically instantiates components by API name using static conditional rendering
- Extracts individual props from context object for cleaner prop passing
- Handles navigation events from child components
- Supports 10+ different stage component types

**API:**
- `@api componentName` - API name of component to render
- `@api context` - Context object with vendorProgramId and stageId (extracted via getters)

**Computed Properties:**
- `vendorProgramId` - Extracted from context
- `stageId` - Extracted from context
- `showVendorProgramOnboardingVendor` - Boolean for vendor selection component
- `showVendorProgramOnboardingVendorProgramCreate` - Boolean for vendor program creation
- `showVendorProgramOnboardingVendorProgramGroup` - Boolean for program group component
- `showVendorProgramOnboardingVendorProgramRequirementGroup` - Boolean for requirement group component
- `showVendorProgramOnboardingVendorProgramRecipientGroup` - Boolean for recipient group component
- `showVendorProgramOnboardingRecipientGroup` - Boolean for recipient group management
- `showVendorProgramOnboardingRecipientGroupMembers` - Boolean for recipient group members
- `showVendorProgramOnboardingTrainingRequirements` - Boolean for training requirements
- `showVendorProgramOnboardingRequiredCredentials` - Boolean for required credentials
- `showVendorProgramOnboardingVendorProgramSearchOrCreate` - Boolean for search/create component
- `showVendorProgramOnboardingVendorProgramRequirements` - Boolean for vendor program requirements component
- `showVendorProgramOnboardingStatusRulesEngine` - Boolean for status rules engine component
- `showVendorProgramOnboardingStatusRuleBuilder` - Boolean for status rule builder component
- `showVendorProgramOnboardingCommunicationTemplate` - Boolean for communication template component
- `hasValidComponent` - Whether component name matches any known component

**Events:**
- `next` - Fired when child component requests next stage (passes event detail through)
- `back` - Fired when child component requests previous stage (passes event detail through)

**Supported Components:**
- `vendorProgramOnboardingVendor`
- `vendorProgramOnboardingVendorProgramCreate`
- `vendorProgramOnboardingVendorProgramGroup`
- `vendorProgramOnboardingVendorProgramRequirementGroup`
- `vendorProgramOnboardingVendorProgramRecipientGroup`
- `vendorProgramOnboardingRecipientGroup`
- `vendorProgramOnboardingRecipientGroupMembers`
- `vendorProgramOnboardingTrainingRequirements`
- `vendorProgramOnboardingRequiredCredentials`
- `vendorProgramOnboardingVendorProgramSearchOrCreate`
- `vendorProgramOnboardingVendorProgramRequirements`
- `vendorProgramOnboardingStatusRulesEngine`
- `vendorProgramOnboardingStatusRuleBuilder`
- `vendorProgramOnboardingCommunicationTemplate`

### vendorProgramOnboardingFlow

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingFlow/`

**Purpose:** Vendor-specific wrapper that resolves the onboarding process for a vendor program and initializes the flow engine.

**Key Features:**
- Accepts `recordId` from Lightning record page (Vendor Program)
- Queries for associated onboarding process
- Injects process ID into flow engine
- Handles loading and error states

**API:**
- `@api recordId` - Vendor Program ID (from record page context)

**Dependencies:**
- `OnboardingApplicationService.getProcessIdForVendorProgram()`

**Usage:**
Add to a Vendor Program record page:
```xml
<c-vendor-program-onboarding-flow record-id={recordId}></c-vendor-program-onboarding-flow>
```

## Dashboard Components

### onboardingHomeDashboard

**Location:** `force-app/main/default/lwc/onboardingHomeDashboard/`

**Purpose:** Central home page dashboard for the Vendor Onboarding application. Provides a comprehensive command center with KPI summaries, work queues, analytics, and quick access to start new onboarding processes.

**Key Features:**
- **Tabbed Layout**: My Active Onboarding, Eligible Dealers, Vendor Programs, Team/Org Queue, Insights
- **KPI Summary Cards**: Active Dealer Onboarding, Completed This Period, Active Vendor Programs, Dealers Onboarded, Blocked/At Risk
- **Global Filters**: Time Range, Vendor, Vendor Program, View (My View, My Team, Org Wide)
- **Work Queue**: Reusable datatable with row highlighting (Red: Blocked, Yellow: At-Risk, Blue: Normal)
- **Vendor Program Grid**: Card layout showing program health metrics
- **Recent Activity Sidebar**: Timeline-style activity feed
- **Insights Tab**: Analytics and visualizations
- **Admin Shortcuts**: Permission-gated configuration shortcuts
- Quick action buttons to start new onboarding
- Modal for selecting an account to start onboarding
- Row actions for viewing, resuming, and viewing requirements
- Refresh functionality to reload data

**Child Components:**
- `onboardingKpiRow` - KPI summary cards
- `onboardingFilterChips` - Global filters
- `onboardingWorkQueue` - Reusable work queue table
- `onboardingVendorProgramGrid` - Vendor program card grid
- `onboardingRecentActivity` - Activity feed sidebar
- `onboardingInsights` - Analytics and charts

**Status Handling:**
- **Dealer Onboarding Status** (`OnboardingDTO.Status`): Displayed as-is from `Onboarding__c.Onboarding_Status__c` - no simplification
- **Vendor Program Status** (`vp.Status__c`): Shown in dropdown labels for vendor program selection (technical status)

**Targets:**
- `lightning__HomePage` - Can be added to Lightning Home pages
- `lightning__AppPage` - Can be added to Lightning App pages

**Data Sources:**
- `OnboardingHomeDashboardController.getMyActiveOnboarding(timeFilter, vendorIds, programIds, viewFilter)` - Active onboarding with filters
- `OnboardingHomeDashboardController.getOnboardingSummary(timeFilter, vendorIds, programIds, viewFilter)` - Summary statistics with filters
- `OnboardingHomeDashboardController.getEligibleAccounts(timeFilter, vendorIds, programIds)` - Accounts that can start new onboarding
- `OnboardingHomeDashboardController.getRecentActivity(recordLimit, timeFilter, vendorIds, programIds)` - Recent activity with filters
- `OnboardingHomeDashboardController.getVendorProgramMetrics(timeFilter, vendorIds)` - Vendor program health metrics
- `OnboardingHomeDashboardController.getBlockedOnboardingCount(timeFilter, vendorIds, programIds)` - Blocked/at-risk count
- `OnboardingHomeDashboardController.getTeamOnboarding(viewFilter, timeFilter, vendorIds, programIds)` - Team/org queue
- `OnboardingHomeDashboardController.getOnboardingWithBlockingInfo(onboardingIds)` - Onboarding with blocking info
- `OnboardingHomeDashboardController.getVendors()` - Vendor list for filters
- `OnboardingHomeDashboardController.getVendorPrograms()` - Vendor program list for filters

**Design Decisions:**
- **Ownership Model**: Uses `OnboardingAccessService` to resolve ownership based on Account Owner and Territory Assignments
- **View Filters**: Supports MY_VIEW (current user), MY_TEAM (role hierarchy), ORG_WIDE (all accessible)
- **Filter State**: Centralized filter state object (`filters`) that applies across all tabs
- **Sharing**: Controlled by Account parent (ControlledByParent), so all users with Account access can see onboarding records
- **Blocking Detection**: Uses `OnboardingBlockingDetectionService` to identify blocked/at-risk records
- Respects Account sharing rules through `with sharing` class

**Column Definitions:**
- **Active Onboarding Table:** Account, Vendor Program, Status, Last Modified, Created By, Actions (View, Resume)
- **Eligible Accounts Table:** Account Name, Territory, Region, Eligible Vendor Count, Actions (Start Onboarding, View Account)

**Methods:**
- `handleStartNewOnboarding()` - Opens modal to select account for new onboarding
- `handleActiveOnboardingRowAction(event)` - Handles row actions (View, Resume)
- `handleEligibleAccountsRowAction(event)` - Handles row actions (Start Onboarding, View Account)
- `navigateToRecord(recordId)` - Navigates to record detail page
- `startOnboardingForAccount(accountId)` - Navigates to account record with Quick Action to start onboarding
- `handleRefresh()` - Refreshes dashboard data

**Dependencies:**
- `OnboardingHomeDashboardController` - Apex controller for dashboard data
- `VendorOnboardingService` - Service for determining eligible vendors (used indirectly)

**Usage:**
1. Create a Lightning Home Page in Setup → Lightning App Builder
2. Add the `onboardingHomeDashboard` component to the page
3. Save and activate the home page
4. Set as default home page in your app settings

**Example:**
The component automatically loads data when added to a home page. Filters can be applied via the `onboardingFilterChips` component, and all tabs will update accordingly.

### onboardingKpiRow

**Location:** `force-app/main/default/lwc/onboardingKpiRow/`

**Purpose:** Displays KPI summary cards in a grid layout.

**Key Features:**
- 5-6 KPI cards: Active Dealer Onboarding, Completed This Period, Active Vendor Programs, Dealers Onboarded, Blocked/At Risk
- Each card shows value, label, optional trend indicator
- Clickable cards dispatch `tileclick` event with metric key
- Uses SLDS styling with color-coded themes

**API Properties:**
- `@api summary` - Onboarding summary map
- `@api vendorSummary` - Vendor program summary
- `@api blockedCount` - Blocked/at-risk count

**Events:**
- `tileclick` - Dispatched when a KPI card is clicked (detail.metricKey contains the metric identifier)

### onboardingFilterChips

**Location:** `force-app/main/default/lwc/onboardingFilterChips/`

**Purpose:** Global filter component for the dashboard.

**Key Features:**
- Time Range filter (Last 30 Days, Last 90 Days, Year to Date, All Time)
- Vendor single-select combobox
- Vendor Program single-select combobox
- View filter (My View, My Team, Org Wide) - permission-gated
- Dispatches `filterchange` event when filters change

**API Properties:**
- `@api timeFilter` - Current time filter value
- `@api vendorFilter` - Current vendor filter values
- `@api programFilter` - Current program filter values
- `@api viewFilter` - Current view filter
- `@api showTeamView` - Whether to show team/org view options

**Wire Methods:**
- `@wire(getVendors)` - Load vendor options
- `@wire(getVendorPrograms)` - Load vendor program options

**Events:**
- `filterchange` - Dispatched when any filter changes (detail contains all filter values)

### onboardingWorkQueue

**Location:** `force-app/main/default/lwc/onboardingWorkQueue/`

**Purpose:** Reusable datatable component for displaying onboarding records with visual indicators.

**Key Features:**
- Row highlighting: Red border for blocked, Yellow for at-risk, Blue for normal
- Columns: Account, Vendor Program, Status, Age (days), Last Modified, Actions
- Action buttons: View, Resume, Requirements
- Shows blocking indicators and tooltips

**API Properties:**
- `@api records` - Array of onboarding records
- `@api showBlockingIndicators` - Whether to show blocking info
- `@api columns` - Column definitions (optional, has defaults)

**Events:**
- `view` - Dispatched when View action clicked
- `resume` - Dispatched when Resume action clicked
- `viewrequirements` - Dispatched when Requirements action clicked

### onboardingVendorProgramGrid

**Location:** `force-app/main/default/lwc/onboardingVendorProgramGrid/`

**Purpose:** Card grid layout for displaying vendor program health metrics.

**Key Features:**
- Card grid layout for vendor programs
- Each card shows: Program name, Vendor, Status badge, Dealer counts, Requirement progress bar
- Health indicators: Rules Engine status, Dependencies status
- Action buttons: View Program, Launch Wizard

**API Properties:**
- `@api programs` - Array of vendor program metrics

**Events:**
- `viewprogram` - Dispatched when View Program clicked
- `launchwizard` - Dispatched when Launch Wizard clicked

### onboardingRecentActivity

**Location:** `force-app/main/default/lwc/onboardingRecentActivity/`

**Purpose:** Timeline-style activity feed component.

**Key Features:**
- Timeline-style activity feed
- Shows: Time ago, Actor, Activity summary, Link to record
- Color-coded: Green (completions), Orange (blocks), Blue (neutral)
- Vertical timeline with connecting lines

**API Properties:**
- `@api activities` - Array of activity records

### onboardingInsights

**Location:** `force-app/main/default/lwc/onboardingInsights/`

**Purpose:** Analytics and visualization component.

**Key Features:**
- Status distribution chart (donut or stacked bar)
- Funnel visualization (Not Started → In Progress → Pending → Complete)
- Vendor program metrics chart
- Uses `lightning-chart` or custom SVG

**API Properties:**
- `@api summary` - Onboarding summary data
- `@api vendorProgramMetrics` - Vendor program metrics

## Management Components

### onboardingAppHeaderBar

**Location:** `force-app/main/default/lwc/onboardingAppHeaderBar/`

**Purpose:** Generic header bar component for versioned records with activation/deactivation capabilities.

**Key Features:**
- Displays record status and active state
- Provides activate/deactivate functionality
- Shows last modified date
- Menu for clone and create new actions
- Accessible keyboard navigation
- Form change tracking

**API:**
- `@api recordId` - Record ID
- `@api objectApiName` - Object API name (e.g., 'Vendor_Customization__c')
- `@api statusFieldApiName` - Status field API name (default: 'Status__c')
- `@api isActiveFieldApiName` - Active field API name (default: 'Active__c')
- `@api lastModifiedFieldApiName` - Last modified field (default: 'LastModifiedDate')

**Methods:**
- `handleSave()` - Saves record via lightning-record-edit-form
- `handleActivate()` - Activates record via OnboardingAppActivationController
- `handleDeactivate()` - Deactivates record
- `handleFormChange()` - Tracks unsaved changes
- `toggleMenu()` - Opens/closes action menu

**Dependencies:**
- `OnboardingAppActivationController.activate()`
- Lightning UI Record API (`getRecord`, `updateRecord`)

### onboardingAppVendorProgramECCManager

**Location:** `force-app/main/default/lwc/onboardingAppVendorProgramECCManager/`

**Purpose:** Manages External Contact Credentials (ECC) for vendor programs.

**Key Features:**
- Displays required credentials in data table
- Links credential types to required credentials
- Creates new credential types
- Modal for credential type creation

**API:**
- `@api recordId` - Vendor_Customization__c ID

**Methods:**
- `loadData()` - Loads required credentials and available credential types in parallel
- `handleRowAction()` - Handles manage action from data table
- `handleLinkCredential()` - Links credential type to required credential
- `handleCreateCredentialType()` - Creates new credential type

**Dependencies:**
- `OnboardingAppECCController.getRequiredCredentials()`
- `OnboardingAppECCController.getAvailableCredentialTypes()`
- `OnboardingAppECCController.createCredentialType()`
- `OnboardingAppECCController.linkCredentialTypeToRequiredCredential()`

### onboardingAppRequirementSetupWizard

**Location:** `force-app/main/default/lwc/onboardingAppRequirementSetupWizard/`

**Purpose:** Wizard for setting up onboarding requirements.

### onboardingStatusRulesManager

**Location:** `force-app/main/default/lwc/onboardingStatusRulesManager/`

**Purpose:** Manages status rules configuration (currently minimal implementation).

### onboardingStatusRuleList

**Location:** `force-app/main/default/lwc/onboardingStatusRuleList/`

**Purpose:** Displays list of status rules.

### requirementConditionsList

**Location:** `force-app/main/default/lwc/requirementConditionsList/`

**Purpose:** Displays requirement conditions for rules.

### vendorProgramHighlights

**Location:** `force-app/main/default/lwc/vendorProgramHighlights/`

**Purpose:** Displays highlights/summary information for vendor programs.

## Vendor Program Onboarding Wizard Components

**📖 See [Vendor Program Onboarding Wizard Components](./vendor-program-onboarding-wizard-components.md) for comprehensive documentation of all wizard components.**

### onboardingStepBase (Base Class)

**Location:** `force-app/main/default/lwc/onboardingStepBase/`

**Purpose:** Base class that provides common functionality for all onboarding step components, eliminating code duplication and standardizing patterns.

**Key Features:**
- Footer navigation event listeners (`footernavnext`, `footernavback`)
- Validation state dispatching (`validationchanged` event)
- Toast notification utility (`showToast`)
- Dynamic card title generation (`cardTitle` getter)
- Standardized event dispatching (`dispatchNextEvent`, `dispatchBackEvent`)

**API:**
- `@api stepNumber` - Step number for card title generation

**Properties:**
- `stepName` - Step name for card title (must be set in child components)

**Methods:**
- `connectedCallback()` - Sets up event listeners and dispatches initial validation state
- `setupFooterNavigation()` - Configures footer navigation listeners
- `handleFooterNextClick()` - Handles footer Next button clicks
- `handleFooterBackClick()` - Handles footer Back button clicks
- `dispatchValidationState()` - Dispatches validation state to flow engine
- `showToast(title, message, variant)` - Shows toast notifications
- `dispatchNextEvent(detail)` - Dispatches next event with proper configuration
- `dispatchBackEvent()` - Dispatches back event with proper configuration

**Required Overrides:**
- `get canProceed()` - Must return boolean indicating if step can proceed
- `proceedToNext()` - Must dispatch next event with appropriate data

**Computed Properties:**
- `cardTitle` - Automatically generates "Step {N}: {stepName}"

**Usage:**
All 14 wizard step components extend this base class. See individual component documentation for implementation details.

**Benefits:**
- Eliminates ~700+ lines of duplicate code
- Standardizes navigation, validation, and event handling patterns
- Ensures consistency across all steps
- Makes adding new steps easier

The Vendor Program Onboarding Wizard consists of 14 steps, each implemented as a separate LWC component that extends `onboardingStepBase`:

1. **vendorProgramOnboardingVendor** - Select or create vendor
2. **vendorProgramOnboardingVendorProgramSearchOrCreate** - Search or create vendor program with Label, Retail Option, Business Vertical
3. **vendorProgramOnboardingRequirementSetOrCreate** - Select Requirement Set or create requirements with inline templates
4. **vendorProgramOnboardingRequirementGroupLinking** - Link Requirement Group components
5. **vendorProgramOnboardingRequiredCredentials** - Configure required credentials (conditional)
6. **vendorProgramOnboardingTrainingRequirements** - Configure training requirements
7. **vendorProgramOnboardingStatusRulesEngine** - Select or create Status Rules Engine
8. **vendorProgramOnboardingRecipientGroup** - Create/manage Recipient Groups (Admin only)
9. **vendorProgramOnboardingCommunicationTemplate** - Link Communication Template with Recipient Group and trigger condition
10. **vendorProgramOnboardingFinalize** - Complete onboarding setup

All components follow a consistent pattern and are dynamically rendered by `onboardingStageRenderer`.

## Stage Components (Legacy/Other)

### vendorProgramOnboardingVendor

**Purpose:** Stage component for selecting/creating a vendor.

**Context:**
- `vendorProgramId` - Current vendor program ID
- `stageId` - Current stage ID

**Note:** See [Vendor Program Onboarding Wizard Components](./vendor-program-onboarding-wizard-components.md) for full documentation.

### vendorProgramOnboardingVendorProgramSearchOrCreate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramSearchOrCreate/`

**Purpose:** Stage component for searching or creating a vendor program. Step 2 in the vendor onboarding wizard flow.

**Key Features:**
- Search for existing vendor programs by name
- Create new vendor program records
- Radio button selection for existing programs
- Input field for creating new programs
- Dispatches 'next' event with selected/created vendor program ID

**API:**
- `@api vendorId` - Vendor ID from previous step (required for creating new programs)

**Properties:**
- `searchText` - Search input text for vendor programs
- `programs` - List of search results
- `selectedProgramId` - Currently selected program ID
- `newProgramName` - Name for new program being created
- `nextDisabled` - Controls Next button state (disabled until program selected/created)

**Methods:**
- `handleSearchChange(event)` - Updates search text from input
- `handleNewProgramChange(event)` - Updates new program name from input
- `searchVendorPrograms()` - Calls Apex to search for vendor programs
- `handleProgramSelect(event)` - Handles radio button selection of existing program
- `createProgram()` - Creates new vendor program via Apex
- `proceedNext()` - Dispatches 'next' event with vendor program ID

**Computed Properties:**
- `programOptions` - Maps programs array to radio group options format

**Dependencies:**
- `VendorOnboardingWizardController.searchVendorPrograms()`
- `VendorOnboardingWizardController.createVendorProgram()`

**Events:**
- Fires `next` event with `detail: { vendorProgramId: String }`

### vendorProgramOnboardingVendorProgramCreate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramCreate/`

**Purpose:** Stage component for finalizing vendor program setup. Step 5 in the vendor onboarding wizard flow. Links the vendor program to vendor, program group, and requirement group.

**Key Features:**
- Finalizes vendor program by linking all related entities
- Uses lightning-record-form for editing vendor program details
- Dispatches 'next' event after finalization

**API:**
- `@api vendorProgramId` - Vendor program ID to finalize
- `@api vendorId` - Vendor ID to link
- `@api programGroupId` - Program group ID to link
- `@api requirementGroupId` - Requirement group ID to link

**Properties:**
- `nextDisabled` - Controls button state during finalization

**Methods:**
- `finalizeProgram()` - Calls Apex to finalize vendor program by linking all entities. Disables button during operation, then dispatches 'next' event

**Dependencies:**
- `VendorOnboardingWizardController.finalizeVendorProgram()`

**Events:**
- Fires `next` event with `detail: { vendorProgramId: String }` after successful finalization

**Note:** This component uses a lightning-record-form for editing, but the actual finalization (linking entities) happens via the `finalizeProgram()` method which calls the Apex controller.

### vendorProgramOnboardingVendorProgramGroup

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramGroup/`

**Purpose:** Stage component for selecting or creating a vendor program group. Step 3 in the vendor onboarding wizard flow.

**Key Features:**
- Search for existing vendor program groups by name
- Create new vendor program group records with required fields visible
- Radio button selection for existing groups
- Toggle button to show/hide create form
- Form validation ensuring all required fields are filled
- Compact information box with context and naming best practices

**Required Fields (for Create):**
- `Name` - Text input (required)
- `Label__c` - Text input (required, auto-filled from Name if empty)
- `Logic_Type__c` - Combobox with picklist values dynamically fetched from Salesforce (required)

**Properties:**
- `searchText` - Search input text for vendor program groups
- `groups` - List of search results
- `selectedGroupId` - Currently selected vendor program group ID
- `newGroupName` - Name for new group being created
- `newGroupLabel` - Label for new group being created
- `newGroupLogicType` - Logic type for new group being created
- `logicTypeOptions` - Picklist options for Logic Type (loaded via @wire)
- `nextDisabled` - Controls Next button state (disabled until group selected/created)
- `showCreateForm` - Controls create form visibility

**Methods:**
- `handleSearchChange(event)` - Updates search text from input
- `handleNewGroupChange(event)` - Updates new group name and auto-fills label
- `handleNewGroupLabelChange(event)` - Updates new group label
- `handleLogicTypeChange(event)` - Updates logic type selection
- `searchGroups()` - Calls Apex to search for vendor program groups
- `handleGroupSelect(event)` - Handles radio button selection of existing group
- `createGroup()` - Creates new vendor program group via Apex with all required fields
- `proceedNext()` - Dispatches 'next' event with vendor program group ID (validates selection first)
- `toggleCreateForm()` - Shows/hides create form
- `validateCreateForm()` - Validates create form and enables/disables Next button
- `showToast(title, message, variant)` - Displays toast notifications

**Computed Properties:**
- `groupOptions` - Maps groups array to radio group options format
- `createButtonLabel` - Dynamic button label based on form state (uses getter instead of ternary expression)

**Dependencies:**
- `VendorOnboardingWizardController.searchVendorProgramGroups()`
- `VendorOnboardingWizardController.createVendorProgramGroup()`
- `VendorOnboardingWizardController.getLogicTypePicklistValues()` (cacheable @wire)

**Events:**
- Fires `next` event with `detail: { programGroupId: String }`

**Validation:**
- Service layer validates required fields and throws exceptions if missing
- Client-side validation ensures all fields are filled before creation

### vendorProgramOnboardingVendorProgramRequirementGroup

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramRequirementGroup/`

**Purpose:** Stage component for selecting or creating a vendor program requirement group.

**Key Features:**
- Search for existing requirement groups by name
- Create new requirement group records with required fields visible
- Radio button selection for existing groups
- Toggle button to show/hide create form
- Form validation ensuring all required fields are filled
- Compact information box with context and naming best practices

**Required Fields (for Create):**
- `Name` - Text input (required)
- `Status__c` - Combobox with picklist values dynamically fetched from Salesforce (required)

**Properties:**
- `searchText` - Search input text for requirement groups
- `groups` - List of search results
- `selectedGroupId` - Currently selected requirement group ID
- `newGroupName` - Name for new group being created
- `newGroupStatus` - Status for new group being created (defaults to 'Active')
- `statusOptions` - Picklist options for Status (loaded via @wire)
- `nextDisabled` - Controls Next button state
- `showCreateForm` - Controls create form visibility
- `templatesToLink` - Templates to link (passed via @api)

**Methods:**
- `handleSearchChange(event)` - Updates search text from input
- `handleNewGroupChange(event)` - Updates new group name
- `handleStatusChange(event)` - Updates status selection
- `searchGroups()` - Calls Apex to search for requirement groups
- `handleGroupSelect(event)` - Handles radio button selection
- `createGroup()` - Creates new requirement group with Name and Status
- `proceedNext()` - Dispatches 'next' event with requirement group ID
- `toggleCreateForm()` - Shows/hides create form
- `validateCreateForm()` - Validates create form
- `showToast(title, message, variant)` - Displays toast notifications

**Computed Properties:**
- `groupOptions` - Maps groups array to radio group options format
- `createButtonLabel` - Dynamic button label based on form state

**Dependencies:**
- `VendorOnboardingWizardController.searchVendorProgramRequirementGroups()`
- `VendorOnboardingWizardController.createVendorProgramRequirementGroup()`
- `VendorOnboardingWizardController.getStatusPicklistValues()` (cacheable @wire) Step 4 in the vendor onboarding wizard flow.

**Key Features:**
- Search for existing requirement groups by name
- Create new requirement group records
- Radio button selection for existing groups
- Input field for creating new groups
- Dispatches 'next' event with selected/created requirement group ID

**API:**
- `@api templatesToLink` - Array of template IDs to link (optional, for future use)

**Properties:**
- `searchText` - Search input text for requirement groups
- `groups` - List of search results
- `selectedGroupId` - Currently selected group ID
- `newGroupName` - Name for new group being created
- `nextDisabled` - Controls Next button state (disabled until group selected/created)

**Methods:**
- `handleSearchChange(event)` - Updates search text from input
- `handleNewGroupChange(event)` - Updates new group name from input
- `searchGroups()` - Calls Apex to search for requirement groups
- `handleGroupSelect(event)` - Handles radio button selection of existing group
- `createGroup()` - Creates new requirement group via Apex
- `proceedNext()` - Dispatches 'next' event with requirement group ID

**Computed Properties:**
- `groupOptions` - Maps groups array to radio group options format

**Dependencies:**
- `VendorOnboardingWizardController.searchVendorProgramRequirementGroups()`
- `VendorOnboardingWizardController.createVendorProgramRequirementGroup()`

**Events:**
- Fires `next` event with `detail: { requirementGroupId: String }`

### vendorProgramOnboardingVendorProgramRecipientGroup

**Purpose:** Stage component for assigning a recipient group.

### vendorProgramOnboardingRecipientGroup

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRecipientGroup/`

**Purpose:** Stage component for selecting or creating a recipient group. Used in the vendor onboarding wizard flow for recipient group configuration.

**Key Features:**
- Search for existing recipient groups by name
- Create new recipient group records with required fields visible
- Radio button selection for existing groups
- Toggle button to show/hide create form
- Form validation ensuring all required fields are filled
- Compact information box with context and naming best practices

**Required Fields (for Create):**
- `Name` - Text input (required)
- `Group_Type__c` - Combobox with picklist values dynamically fetched from Salesforce (required)

**API:**
- `@api vendorProgramId` - Vendor program ID (required for creating new groups)

**Properties:**
- `searchText` - Search input text for recipient groups
- `recipientGroups` - List of search results
- `selectedRecipientGroupId` - Currently selected recipient group ID
- `newGroupName` - Name for new group being created
- `newGroupType` - Group type for new group being created (defaults to 'User')
- `groupTypeOptions` - Picklist options for Group Type (loaded via @wire)
- `nextDisabled` - Controls Next button state (disabled until group selected/created)
- `showCreateForm` - Controls create form visibility

**Methods:**
- `handleSearchChange(event)` - Updates search text from input
- `handleNewGroupChange(event)` - Updates new group name from input
- `handleGroupTypeChange(event)` - Updates group type selection
- `searchGroups()` - Calls Apex to search for recipient groups
- `handleGroupSelect(event)` - Handles radio button selection of existing group
- `createGroup()` - Creates new recipient group via Apex with Name and Group Type
- `proceedNext()` - Dispatches 'next' event with recipient group ID
- `toggleCreateForm()` - Shows/hides create form
- `validateCreateForm()` - Validates create form
- `showToast(title, message, variant)` - Displays toast notifications

**Computed Properties:**
- `groupOptions` - Maps recipient groups array to radio group options format
- `createButtonLabel` - Dynamic button label based on form state

**Dependencies:**
- `VendorOnboardingWizardController.searchRecipientGroups()`
- `VendorOnboardingWizardController.createRecipientGroup()`
- `VendorOnboardingWizardController.getGroupTypePicklistValues()` (cacheable @wire)

**Events:**
- Fires `next` event with `detail: { recipientGroupId: String }`

### vendorProgramOnboardingRecipientGroupMembers

**Purpose:** Stage component for adding members to a recipient group.

### vendorProgramOnboardingRequiredCredentials

**Purpose:** Stage component for managing required credentials.

### vendorProgramOnboardingTrainingRequirements

**Purpose:** Stage component for managing training requirements.

### vendorProgramOnboardingVendorProgramRequirements

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramRequirements/`

**Purpose:** Stage component for searching and selecting vendor program requirements. Allows users to search for existing requirements and select them for the vendor program.

**Key Features:**
- Search for vendor program requirements by name
- Display search results in data table
- Select requirement from results
- Dispatches 'next' event with selected requirement ID

**API:**
- `@api vendorProgramId` - Vendor program ID
- `@api stageId` - Current stage ID

**Dependencies:**
- `VendorOnboardingWizardController.searchVendorProgramRequirements()`

**Events:**
- Fires `next` event with `detail: { selectedRequirementId: String, vendorProgramId: String }`

### vendorProgramOnboardingStatusRulesEngine

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingStatusRulesEngine/`

**Purpose:** Stage component for searching, selecting, or creating status rules engines.

**Key Features:**
- Search for existing status rules engines
- Create new status rules engine records with all required fields visible
- Data table display of search results
- Toggle button to show/hide create form
- Form validation ensuring all required fields are filled
- Compact information box with context and naming best practices

**Required Fields (for Create):**
- `Name` - Text input (required)
- `Evaluation_Logic__c` - Combobox with picklist values (ALL, ANY, CUSTOM) (required)
- `Required_Status__c` - Combobox with picklist values (required)
- `Target_Onboarding_Status__c` - Combobox with picklist values (required)

**Optional Fields:**
- `Vendor_Program_Requirement_Group__c` - Text input
- `Vendor_Program_Group__c` - Text input

**Properties:**
- `searchText` - Search input text
- `searchResults` - List of search results
- `showCreateForm` - Controls create form visibility
- `newName` - Name for new rules engine
- `newRequirementGroupId` - Vendor program requirement group ID (optional)
- `newProgramGroupId` - Vendor program group ID (optional)
- `newEvaluationLogic` - Evaluation logic (defaults to 'ALL')
- `newRequiredStatus` - Required status (defaults to 'New')
- `newTargetOnboardingStatus` - Target onboarding status (defaults to 'In Process')
- `evaluationLogicOptions` - Picklist options for Evaluation Logic (loaded via @wire)
- `requiredStatusOptions` - Picklist options for Required Status (loaded via @wire)
- `targetOnboardingStatusOptions` - Picklist options for Target Onboarding Status (loaded via @wire)
- `columns` - Data table column definitions

**Methods:**
- `handleSearchTextChange(event)` - Updates search text
- `handleSearch()` - Calls Apex to search for rules engines
- `handleRowAction(event)` - Handles row action (select)
- `handleInputChange(event)` - Updates input field values
- `handleEvaluationLogicChange(event)` - Updates evaluation logic selection
- `handleRequiredStatusChange(event)` - Updates required status selection
- `handleTargetOnboardingStatusChange(event)` - Updates target onboarding status selection
- `handleCreateClick()` - Creates new rules engine with all required fields
- `toggleCreateForm()` - Shows/hides create form
- `showToast(title, message, variant)` - Displays toast notifications

**Computed Properties:**
- `hasSearchResults` - Whether search results exist
- `createButtonLabel` - Dynamic button label based on form state

**Dependencies:**
- `VendorOnboardingWizardController.searchStatusRulesEngines()`
- `VendorOnboardingWizardController.createOnboardingStatusRulesEngine()`
- `VendorOnboardingWizardController.getEvaluationLogicPicklistValues()` (cacheable @wire)
- `VendorOnboardingWizardController.getRequiredStatusPicklistValues()` (cacheable @wire)
- `VendorOnboardingWizardController.getTargetOnboardingStatusPicklistValues()` (cacheable @wire)

**Purpose:** Stage component for searching, creating, and selecting status rules engines. Allows users to search for existing rules engines or create new ones.

**Key Features:**
- Search for status rules engines by name
- Create new status rules engine records
- Display search results in data table
- Select rules engine from results
- Dispatches 'next' event with selected rules engine ID

**API:**
- `@api vendorProgramId` - Vendor program ID
- `@api stageId` - Current stage ID

**Properties:**
- `newName` - Name for new rules engine
- `newRequirementGroupId` - Requirement group ID for new rules engine
- `newProgramGroupId` - Program group ID for new rules engine

**Dependencies:**
- `VendorOnboardingWizardController.searchStatusRulesEngines()`
- `VendorOnboardingWizardController.createOnboardingStatusRulesEngine()`

**Events:**
- Fires `next` event with `detail: { rulesEngineId: String, vendorProgramId: String }`

### vendorProgramOnboardingStatusRuleBuilder

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingStatusRuleBuilder/`

**Purpose:** Stage component for building and configuring status rules. Provides UI for creating rule conditions and configuring rule evaluation logic.

**API:**
- `@api vendorProgramId` - Vendor program ID
- `@api stageId` - Current stage ID

### vendorProgramOnboardingCommunicationTemplate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingCommunicationTemplate/`

**Purpose:** Stage component for selecting and linking communication templates to vendor programs. Allows users to choose from available communication templates and link them to the vendor program.

**Key Features:**
- Loads all available communication templates
- Select template from dropdown
- Link selected template to vendor program
- Dispatches 'next' event after linking

**API:**
- `@api vendorProgramId` - Vendor program ID

**Dependencies:**
- `VendorOnboardingWizardController.getCommunicationTemplates()`
- `VendorOnboardingWizardController.linkCommunicationTemplateToVendorProgram()`

**Events:**
- Fires `next` event with `detail: { vendorProgramId: String, communicationTemplateId: String }`

## Management Components

### onboardingRequirementsPanel

**Location:** `force-app/main/default/lwc/onboardingRequirementsPanel/`

**Purpose:** Displays and manages onboarding requirements for an onboarding record.

**Key Features:**
- Lists all requirements for an onboarding
- Allows status updates via combobox
- Triggers status re-evaluation after updates
- Displays requirement details

**API:**
- `@api recordId` - Onboarding record ID (from record page context)

**Dependencies:**
- `OnboardingRequirementsPanelController.getRequirements()`
- `OnboardingRequirementsPanelController.updateRequirementStatuses()`
- `OnboardingRequirementsPanelController.runRuleEvaluation()`

**Usage:**
Add to an Onboarding record page:
```xml
<c-onboarding-requirements-panel record-id={recordId}></c-onboarding-requirements-panel>
```

### onboardingStatusRulesEngine

**Location:** `force-app/main/default/lwc/onboardingStatusRulesEngine/`

**Purpose:** Admin UI for configuring onboarding status rules.

**Key Features:**
- Select vendor program group and requirement group
- Load existing rules
- Edit rules in datatable
- Save rule changes

**Dependencies:**
- `OnboardingStatusRulesEngineController.getVendorProgramGroups()`
- `OnboardingStatusRulesEngineController.getRequirementGroups()`
- `OnboardingStatusRulesEngineController.getRules()`
- `OnboardingStatusRulesEngineController.saveRules()`

### onboardingStatusRuleList

**Location:** `force-app/main/default/lwc/onboardingStatusRuleList/`

**Purpose:** Displays a list of onboarding status rules.

**Key Features:**
- Filters by vendor program group
- Displays rules in datatable
- Edit button for each rule

**Dependencies:**
- `OnboardingStatusRuleController.getRules()`

### onboardingStatusRulesManager

**Location:** `force-app/main/default/lwc/onboardingStatusRulesManager/`

**Purpose:** Manager component for onboarding status rules (wrapper/container).

### onboardingRuleModal

**Location:** `force-app/main/default/lwc/onboardingRuleModal/`

**Purpose:** Modal dialog for creating/editing onboarding rules.

### requirementConditionsList

**Location:** `force-app/main/default/lwc/requirementConditionsList/`

**Purpose:** Displays and manages requirement conditions for rules.

## Utility Components

### vendorProgramHighlights

**Location:** `force-app/main/default/lwc/vendorProgramHighlights/`

**Purpose:** Displays highlights/summary information for a vendor program.

**Key Features:**
- Displays Vendor Program status (`Vendor_Customization__c.Status__c`)
- Shows version and active state
- **Note**: Currently displays technical status directly - could be enhanced to use `getUserFacingStage()` for consistency with other components

**Status Display:**
- Shows `Vendor_Customization__c.Status__c` value directly
- ⚠️ **Future Enhancement**: Consider using `OnboardingApplicationService.getUserFacingStage()` to show simplified statuses for end users

### vendorSelector

**Location:** `force-app/main/default/lwc/vendorSelector/`

**Purpose:** Reusable component for selecting vendors.

### onboardingAppHeaderBar

**Location:** `force-app/main/default/lwc/onboardingAppHeaderBar/`

**Purpose:** Header bar component for onboarding applications.

**Configuration:**
- `isActiveFieldApiName` - API name of the active field (default: "Active__c")

### onboardingApplicationFlow

**Location:** `force-app/main/default/lwc/onboardingApplicationFlow/`

**Purpose:** Generic onboarding application flow component.

### onboardingAppRequirementSetupWizard

**Location:** `force-app/main/default/lwc/onboardingAppRequirementSetupWizard/`

**Purpose:** Wizard component for setting up onboarding requirement sets and templates. Guides users through creating requirement sets and adding requirement templates.

**Key Features:**
- Creates onboarding requirement sets
- Adds requirement templates to sets
- Displays list of created templates
- Fires 'next' event when setup is complete

**API:**
- None (standalone wizard component)

**Properties:**
- `requirementSetName` - Name for new requirement set
- `newTemplateName` - Name for new requirement template
- `newRequirementType` - Type of requirement template
- `requirementTemplates` - List of templates in current set
- `requirementSetId` - ID of created requirement set
- `requirementSetCreated` - Boolean flag indicating if set was created
- `requirementTypeOptions` - Picklist options for requirement types

**Methods:**
- `createRequirementSet()` - Creates a new requirement set
- `addRequirementTemplate()` - Adds a template to the current set
- `finalizeSetup()` - Fires 'next' event to proceed to next step

**Dependencies:**
- `VendorOnboardingWizardController.createOnboardingRequirementSet()`
- `VendorOnboardingWizardController.createOnboardingRequirementTemplate()`
- `VendorOnboardingWizardController.getRequirementTemplatesForSet()`

**Usage:**
Used in vendor onboarding wizard workflows for requirement setup.

### onboardingAppVendorProgramECCManager

**Location:** `force-app/main/default/lwc/onboardingAppVendorProgramECCManager/`

**Purpose:** Manages External Contact Credential (ECC) types for vendor programs. Allows linking credential types to required credentials and creating new credential types.

**Key Features:**
- Displays required credentials for a vendor program in datatable
- Links credential types to required credentials
- Creates new credential types via modal
- Shows linked credential type for each required credential

**API:**
- `@api recordId` - Vendor Program ID (Vendor_Customization__c) from record page context

**Properties:**
- `requiredCredentials` - List of required credentials for the vendor program
- `credentialTypeOptions` - Options for credential type combobox
- `selectedRequiredCredentialId` - Currently selected required credential
- `selectedCredentialTypeId` - Selected credential type for linking
- `showModal` - Controls visibility of create credential type modal
- `newCredentialTypeName` - Name for new credential type

**Methods:**
- `loadData()` - Loads required credentials and credential types
- `handleRowAction(event)` - Handles datatable row actions (Manage button)
- `handleCredentialTypeChange(event)` - Updates selected credential type
- `handleLinkCredential()` - Links selected credential type to required credential
- `handleShowModal()` - Opens create credential type modal
- `handleCloseModal()` - Closes modal
- `handleCreateCredentialType()` - Creates new credential type
- `showToast(message)` - Displays success toast
- `showError(title, error)` - Displays error toast

**Dependencies:**
- `OnboardingAppECCController.getRequiredCredentials()`
- `OnboardingAppECCController.getAvailableCredentialTypes()`
- `OnboardingAppECCController.createCredentialType()`
- `OnboardingAppECCController.linkCredentialTypeToRequiredCredential()`

**Usage:**
Add to a Vendor Program record page:
```xml
<c-onboarding-app-vendor-program-e-c-c-manager record-id={recordId}></c-onboarding-app-vendor-program-e-c-c-manager>
```

### onboardingOrderStatusViewer

**Location:** `force-app/unpackaged/lwc/onboardingOrderStatusViewer/`

**Purpose:** Displays order status for onboarding records.

### onboardingStatusRuleForm

**Location:** `force-app/unpackaged/lwc/onboardingStatusRuleForm/`

**Purpose:** Form for creating/editing status rules.

### onboardingECC

**Location:** `force-app/unpackaged/lwc/onboardingECC/`

**Purpose:** External Contact Credential management component.

## Component Communication

### Event Flow

Stage Components

vendorProgramOnboardingVendor
Purpose: Stage component for selecting/creating a vendor.

Context:
vendorProgramId - Current vendor program ID
stageId - Current stage ID
vendorProgramOnboardingVendorProgramSearchOrCreate
Purpose: Stage component for searching or creating a vendor program.

vendorProgramOnboardingVendorProgramCreate
Purpose: Stage component for creating a new vendor program.

vendorProgramOnboardingVendorProgramGroup
Purpose: Stage component for assigning a program group.

vendorProgramOnboardingVendorProgramRequirementGroup
Purpose: Stage component for assigning a requirement group.

vendorProgramOnboardingVendorProgramRecipientGroup
Purpose: Stage component for assigning a recipient group.

vendorProgramOnboardingRecipientGroup
Purpose: Stage component for configuring recipient group details.

vendorProgramOnboardingRecipientGroupMembers
Purpose: Stage component for adding members to a recipient group.

vendorProgramOnboardingRequiredCredentials
Purpose: Stage component for managing required credentials.

vendorProgramOnboardingTrainingRequirements
Purpose: Stage component for managing training requirements.

Management Components
onboardingRequirementsPanel
Location: force-app/main/default/lwc/onboardingRequirementsPanel/
Purpose: Displays and manages onboarding requirements for an onboarding record.
Key Features:
Lists all requirements for an onboarding
Allows status updates via combobox
Triggers status re-evaluation after updates
Displays requirement details

API:
@api recordId - Onboarding record ID (from record page context)

Dependencies:
OnboardingRequirementsPanelController.getRequirements()
OnboardingRequirementsPanelController.updateRequirementStatuses()
OnboardingRequirementsPanelController.runRuleEvaluation()

Usage:
Add to an Onboarding record page:
<c-onboarding-requirements-panel record-id={recordId}></c-onboarding-requirements-panel>: String,
  stageId: String
}### Navigation Events

Stage components fire custom events:
- `next` - Request to advance to next stage
- `back` - Request to return to previous stage

## Best Practices

1. **Stage Components**: Should be self-contained and handle their own data operations
2. **Error Handling**: All components should handle errors gracefully
3. **Loading States**: Show loading indicators during async operations
4. **Progress Persistence**: Stage components should trigger progress saves
5. **Event Communication**: Use custom events for parent-child communication

## Related Documentation

- [Onboarding Process Flow](../processes/onboarding-process.md)
- [Application Flow Engine](../processes/application-flow-engine.md)
- [Apex Classes](./apex-classes.md)

onboardingStatusRulesEngine
Location: force-app/main/default/lwc/onboardingStatusRulesEngine/
Purpose: Admin UI for configuring onboarding status rules.
Key Features:
Select vendor program group and requirement group
Load existing rules
Edit rules in datatable
Save rule changes
Dependencies:
OnboardingStatusRulesEngineController.getVendorProgramGroups()
OnboardingStatusRulesEngineController.getRequirementGroups()
OnboardingStatusRulesEngineController.getRules()
OnboardingStatusRulesEngineController.saveRules()
onboardingStatusRuleList
Location: force-app/main/default/lwc/onboardingStatusRuleList/
Purpose: Displays a list of onboarding status rules.
Key Features:
Filters by vendor program group
Displays rules in datatable
Edit button for each rule
Dependencies:
OnboardingStatusRuleController.getRules()
onboardingStatusRulesManager
Location: force-app/main/default/lwc/onboardingStatusRulesManager/
Purpose: Manager component for onboarding status rules (wrapper/container).
onboardingRuleModal
Location: force-app/main/default/lwc/onboardingRuleModal/
Purpose: Modal dialog for creating/editing onboarding rules.
requirementConditionsList
Location: force-app/main/default/lwc/requirementConditionsList/
Purpose: Displays and manages requirement conditions for rules.
Utility Components
vendorProgramHighlights
Location: force-app/main/default/lwc/vendorProgramHighlights/
Purpose: Displays highlights/summary information for a vendor program.
vendorSelector
Location: force-app/main/default/lwc/vendorSelector/
Purpose: Reusable component for selecting vendors.
onboardingAppHeaderBar
Location: force-app/main/default/lwc/onboardingAppHeaderBar/
Purpose: Header bar component for onboarding applications.
Configuration:
isActiveFieldApiName - API name of the active field (default: "Activec")
onboardingApplicationFlow
Location: force-app/main/default/lwc/onboardingApplicationFlow/
Purpose: Generic onboarding application flow component.
onboardingOrderStatusViewer
Location: force-app/unpackaged/lwc/onboardingOrderStatusViewer/
Purpose: Displays order status for onboarding records.
onboardingStatusRuleForm
Location: force-app/unpackaged/lwc/onboardingStatusRuleForm/
Purpose: Form for creating/editing status rules.
onboardingECC
Location: force-app/unpackaged/lwc/onboardingECC/
Purpose: External Contact Credential management component.
Component Communication
Event Flow
vendorProgramOnboardingFlow
    ↓ (processId)
onboardingFlowEngine
    ↓ (componentName, context)
onboardingStageRenderer
    ↓ (dynamic component)
Stage Component (e.g., vendorProgramOnboardingVendor)
    ↓ (next/back events)
onboardingStageRenderer
    ↓ (next/back events)
onboardingFlowEngine
    ↓ (progress update)
OnboardingApplicationServicey order
- `getProcessDetails(Id processId)` - Returns process details
- `saveProgress(Id processId, Id vendorProgramId, Id stageId)` - Saves progress and logs stage completion
- `getProgress(Id vendorProgramId, Id processId)` - Retrieves saved progress
- `getProcessIdForVendorProgram(Id vendorProgramId)` - Resolves process ID for a vendor program

**Usage:**
Primary service used by `onboardingFlowEngine` LWC component.

### OnboardingRulesService

**Location:** `force-app/main/default/classes/OnboardingRulesService.cls`

**Purpose:** Service for managing onboarding status rules and requirements.

**Key Methods:**
- `getRulesEngineRecords(Id engineId)` - Returns rules for a rules engine
- `createOrUpdateRule(Onboarding_Status_Rule__c rule)` - Creates or updates a rule
- `deleteRule(Id ruleId)` - Deletes a rule
- `getRequirementsByVPR(Id onboardingId)` - Returns requirements mapped by Vendor Program Requirement ID
- `getVendorProgramId(Id onboardingId)` - Gets vendor program ID from onboarding
- `getVendorProgramGroupIds(Id vendorProgramId)` - Gets group IDs for a vendor program
- `getRulesForGroups(List<Id> groupIds)` - Gets rules for vendor program groups

**Usage:**
Used by status evaluation engine and rules management UI.

### OnboardingStatusEvaluator

**Location:** `force-app/main/default/classes/OnboardingStatusEvaluator.cls`

**Purpose:** Evaluates onboarding status based on rules engine configuration.

**Key Methods:**
- `evaluateAndApplyStatus(Onboarding__c onboarding)` - Evaluates rules and updates onboarding status

**Flow:**
1. Gets requirements for onboarding
2. Gets vendor program ID
3. Gets vendor program group IDs
4. Gets rules for groups
5. Evaluates each rule
6. Updates onboarding status when rule passes

**Usage:**
Called from flows when onboarding records change.

### OnboardingRuleEvaluator

**Location:** `force-app/main/default/classes/OnboardingRuleEvaluator.cls`

**Purpose:** Evaluates individual rules against requirement statuses.

**Key Methods:**
- `evaluateRule(Onboarding_Status_Rules_Engine__c rule, Map<Id, Onboarding_Requirement__c> reqByVPR)` - Evaluates a rule

**Logic:**
- Supports AND, OR, and Custom evaluation logic
- Uses `OnboardingExpressionEngine` for custom expressions

### OnboardingExpressionEngine

**Location:** `force-app/main/default/classes/OnboardingExpressionEngine.cls`

**Purpose:** Parses and evaluates custom expression logic for rules.

**Key Methods:**
- `evaluate(String expression, Map<Id, Onboarding_Requirement__c> reqByVPR)` - Evaluates a custom expression

**Expression Syntax:**
Supports logical operators and requirement status checks.

## Controllers

### OnboardingRequirementsPanelController

**Location:** `force-app/main/default/classes/OnboardingRequirementsPanelController.cls`

**Purpose:** Controller for the onboarding requirements panel LWC.

**Key Methods:**
- `getRequirements(Id onboardingId)` - Returns requirements for an onboarding
- `updateRequirementStatuses(List<Onboarding_Requirement__c> updates)` - Updates requirement statuses
- `runRuleEvaluation(Id onboardingId)` - Triggers status re-evaluation

**Usage:**
Used by `onboardingRequirementsPanel` LWC.

### OnboardingStatusRulesEngineController

**Location:** `force-app/main/default/classes/OnboardingStatusRulesEngineController.cls`

**Purpose:** Controller for the status rules engine management UI.

**Key Methods:**
- `getVendorProgramGroups()` - Returns vendor program groups for picklist
- `getRequirementGroups()` - Returns requirement groups for picklist
- `getRules(Id vendorProgramGroupId, Id requirementGroupId)` - Returns rules for selected groups
- `saveRules(List<Onboarding_Status_Rule__c> rules)` - Saves rule changes

**Usage:**
Used by `onboardingStatusRulesEngine` LWC.

### OnboardingStatusRuleController

**Location:** `force-app/main/default/classes/OnboardingStatusRuleController.cls`

**Purpose:** Controller for status rule list component.

**Key Methods:**
- `getRules(Id vendorProgramGroupId)` - Returns rules for a vendor program group

**Usage:**
Used by `onboardingStatusRuleList` LWC.

### OnboardingAppActivationController

**Location:** `force-app/main/default/classes/controllers/OnboardingAppActivationController.cls`

**Purpose:** Controller for activation actions.

**Key Methods:**
- Activation-related methods for onboarding application objects

## Orchestrators

### OnboardingAppActivationOrchestrator

**Location:** `force-app/main/default/classes/orchestrators/OnboardingAppActivationOrchestrator.cls`

**Purpose:** Orchestrates the activation workflow for onboarding application objects.

**Key Methods:**
- `activate(Id recordId, String objectApiName)` - Activates a record with validation

**Flow:**
1. Validates record using `OnboardingAppRuleRegistry`
2. Calls activation service
3. Handles errors

### OnboardingAppVendorProgramReqOrch

**Location:** `force-app/main/default/classes/orchestrators/OnboardingAppVendorProgramReqOrch.cls`

**Purpose:** Orchestrates vendor program requirement operations.

## Services

### OnboardingAppActivationService

**Location:** `force-app/main/default/classes/services/OnboardingAppActivationService.cls`

**Purpose:** Service for activating onboarding application records.

**Key Methods:**
- Activation logic for various object types

### VendorOnboardingWizardService

**Location:** `force-app/main/default/classes/services/VendorOnboardingWizardService.cls`

**Purpose:** Service for vendor onboarding wizard operations.

## Handlers

### OnboardingAppRuleEngineHandler

**Location:** `force-app/main/default/classes/OnboardingAppRuleEngineHandler.cls`

**Purpose:** Handler for rule engine events and triggers.

### OnboardingAppVendorProgramReqHdlr

**Location:** `force-app/main/default/classes/handlers/OnboardingAppVendorProgramReqHdlr.cls`

**Purpose:** Handler for vendor program requirement events.

### OnboardingStatusTrackerHandler

**Location:** `force-app/main/default/classes/handlers/OnboardingStatusTrackerHandler.cls`

**Purpose:** Tracks onboarding status changes.

## Validation Rules

### OnboardingAppRuleRegistry

**Location:** `force-app/main/default/classes/OnboardingAppRuleRegistry.cls`

**Purpose:** Central registry of validation rules for onboarding application objects.

**Key Methods:**
- `getRules()` - Returns map of object API names to validation rule lists

**Registered Rules:**
- `Vendor_Program_Recipient_Group__c`:
  - `RequireParentVersionOnActivationRule`
  - `OnlyOneActiveRecGrpPerPrgrmRule`
  - `RecipientAndProgramMustBeActiveRule`
  - `PreventDupRecGrpAssignmentRule`

### OnboardingAppValidationRule

**Location:** `force-app/main/default/classes/OnboardingAppValidationRule.cls`

**Purpose:** Interface for validation rules.

**Key Methods:**
- `validate(SObject record)` - Validates a record
- `getErrorMessage()` - Returns error message

### Rule Implementations

- **RequireParentVersionOnActivationRule** - Requires parent version on activation
- **OnlyOneActiveRecGrpPerPrgrmRule** - Ensures only one active recipient group per program
- **RecipientAndProgramMustBeActiveRule** - Validates recipient and program are active
- **PreventDupRecGrpAssignmentRule** - Prevents duplicate recipient group assignments

## Actions

### OnboardingAppActivationAction

**Location:** `force-app/main/default/classes/actions/OnboardingAppActivationAction.cls`

**Purpose:** Action class for activating records.

**Key Methods:**
- `activate(List<Request> requestList)` - Activates multiple records

**Request Class:**
- `recordId` - Record ID to activate
- `objectApiName` - Object API name

## Repositories

Repository classes follow the pattern `*Repo.cls` and handle data access operations:

- `OnboardingAppVendorProgramReqRepo` - Vendor program requirement data access

## DTOs (Data Transfer Objects)

DTO classes in `dto/` package provide structured data transfer:

- Various DTO classes for data transfer between layers

## Helpers

Helper classes in `helpers/` package provide utility functions:

- Various helper classes for common operations

## Jobs

Scheduled and batch job classes in `jobs/` package:

- Various job classes for background processing

## Test Classes

Test classes follow naming convention `*Test.cls`:

- `OnboardingRulesServiceTest`
- `OnboardingStatusEvaluatorTest`
- `OnlyOneActiveRecGrpPerPrgrmRuleTest`
- `PreventDupRecGrpAssignmentRuleTest`
- `RecipientAndProgramMustBeActiveRuleTest`
- `RequireParentVersionOnActivationRuleTest`
- And many more...

## Class Organization
Context Object
Stage components receive a context object:

{
  vendorProgramId: String,
  stageId: String
}ss logic in service classes
2. **Controllers**: Thin controllers that delegate to services
3. **Orchestrators**: Coordinate multiple services
4. **Repositories**: Data access abstraction
5. **Sharing**: Use `with sharing` for security
6. **Error Handling**: Proper exception handling
7. **Testing**: Comprehensive test coverage

## Related Documentation

- [LWC Components](./lwc-components.md)
- [API Reference](../api/apex-api.md)
- [Architecture Overview](../architecture/overview.md)

Navigation Events
Stage components fire custom events:
next - Request to advance to next stage
back - Request to return to previous stage
Best Practices
Stage Components: Should be self-contained and handle their own data operations
Error Handling: All components should handle errors gracefully
Loading States: Show loading indicators during async operations
Progress Persistence: Stage components should trigger progress saves
Event Communication: Use custom events for parent-child communication
Related Documentation
Onboarding Process Flow
Application Flow Engine
Apex Classes

## 6. Create docs/components/apex-classes.md

Create `docs/components/apex-classes.md`:

# Apex Classes

## Service Layer

### OnboardingApplicationService

**Location:** `force-app/main/default/classes/OnboardingApplicationService.cls`

**Purpose:** Core service for managing onboarding application processes, stages, and progress.

**Key Methods:**
- `getStagesForProcess(Id processId)` - Returns stages for a process, ordered by display order
- `getProcessDetails(Id processId)` - Returns process details
- `saveProgress(Id processId, Id vendorProgramId, Id stageId)` - Saves progress and logs stage completion
- `getProgress(Id vendorProgramId, Id processId)` - Retrieves saved progress
- `getProcessIdForVendorProgram(Id vendorProgramId)` - Resolves process ID for a vendor program

**Usage:**
Primary service used by `onboardingFlowEngine` LWC component.

### OnboardingRulesService

**Location:** `force-app/main/default/classes/OnboardingRulesService.cls`

**Purpose:** Service for managing onboarding status rules and requirements.

**Key Methods:**
- `getRulesEngineRecords(Id engineId)` - Returns rules for a rules engine
- `createOrUpdateRule(Onboarding_Status_Rule__c rule)` - Creates or updates a rule
- `deleteRule(Id ruleId)` - Deletes a rule
- `getRequirementsByVPR(Id onboardingId)` - Returns requirements mapped by Vendor Program Requirement ID
- `getVendorProgramId(Id onboardingId)` - Gets vendor program ID from onboarding
- `getVendorProgramGroupIds(Id vendorProgramId)` - Gets group IDs for a vendor program
- `getRulesForGroups(List<Id> groupIds)` - Gets rules for vendor program groups

**Usage:**
Used by status evaluation engine and rules management UI.

### OnboardingStatusEvaluator

**Location:** `force-app/main/default/classes/OnboardingStatusEvaluator.cls`

**Purpose:** Evaluates onboarding status based on rules engine configuration.

**Key Methods:**
- `evaluateAndApplyStatus(Onboarding__c onboarding)` - Evaluates rules and updates onboarding status

**Flow:**
1. Gets requirements for onboarding
2. Gets vendor program ID
3. Gets vendor program group IDs
4. Gets rules for groups
5. Evaluates each rule
6. Updates onboarding status when rule passes

**Usage:**
Called from flows when onboarding records change.

### OnboardingRuleEvaluator

**Location:** `force-app/main/default/classes/OnboardingRuleEvaluator.cls`

**Purpose:** Evaluates individual rules against requirement statuses.

**Key Methods:**
- `evaluateRule(Onboarding_Status_Rules_Engine__c rule, Map<Id, Onboarding_Requirement__c> reqByVPR)` - Evaluates a rule

**Logic:**
- Supports AND, OR, and Custom evaluation logic
- Uses `OnboardingExpressionEngine` for custom expressions

### OnboardingExpressionEngine

**Location:** `force-app/main/default/classes/OnboardingExpressionEngine.cls`

**Purpose:** Parses and evaluates custom expression logic for rules.

**Key Methods:**
- `evaluate(String expression, Map<Id, Onboarding_Requirement__c> reqByVPR)` - Evaluates a custom expression

**Expression Syntax:**
Supports logical operators and requirement status checks.

## Controllers

### OnboardingRequirementsPanelController

**Location:** `force-app/main/default/classes/OnboardingRequirementsPanelController.cls`

**Purpose:** Controller for the onboarding requirements panel LWC.

**Key Methods:**
- `getRequirements(Id onboardingId)` - Returns requirements for an onboarding
- `updateRequirementStatuses(List<Onboarding_Requirement__c> updates)` - Updates requirement statuses
- `runRuleEvaluation(Id onboardingId)` - Triggers status re-evaluation

**Usage:**
Used by `onboardingRequirementsPanel` LWC.

### OnboardingStatusRulesEngineController

**Location:** `force-app/main/default/classes/OnboardingStatusRulesEngineController.cls`

**Purpose:** Controller for the status rules engine management UI.

**Key Methods:**
- `getVendorProgramGroups()` - Returns vendor program groups for picklist
- `getRequirementGroups()` - Returns requirement groups for picklist
- `getRules(Id vendorProgramGroupId, Id requirementGroupId)` - Returns rules for selected groups
- `saveRules(List<Onboarding_Status_Rule__c> rules)` - Saves rule changes

**Usage:**
Used by `onboardingStatusRulesEngine` LWC.

### OnboardingStatusRuleController

**Location:** `force-app/main/default/classes/OnboardingStatusRuleController.cls`

**Purpose:** Controller for status rule list component.

**Key Methods:**
- `getRules(Id vendorProgramGroupId)` - Returns rules for a vendor program group

**Usage:**
Used by `onboardingStatusRuleList` LWC.

### OnboardingAppActivationController

**Location:** `force-app/main/default/classes/controllers/OnboardingAppActivationController.cls`

**Purpose:** Controller for activation actions.

**Key Methods:**
- Activation-related methods for onboarding application objects

## Orchestrators

### OnboardingAppActivationOrchestrator

**Location:** `force-app/main/default/classes/orchestrators/OnboardingAppActivationOrchestrator.cls`

**Purpose:** Orchestrates the activation workflow for onboarding application objects.

**Key Methods:**
- `activate(Id recordId, String objectApiName)` - Activates a record with validation

**Flow:**
1. Validates record using `OnboardingAppRuleRegistry`
2. Calls activation service
3. Handles errors

### OnboardingAppVendorProgramReqOrch

**Location:** `force-app/main/default/classes/orchestrators/OnboardingAppVendorProgramReqOrch.cls`

**Purpose:** Orchestrates vendor program requirement operations.

## Services

### OnboardingAppActivationService

**Location:** `force-app/main/default/classes/services/OnboardingAppActivationService.cls`

**Purpose:** Service for activating onboarding application records.

**Key Methods:**
- Activation logic for various object types

### VendorOnboardingWizardService

**Location:** `force-app/main/default/classes/services/VendorOnboardingWizardService.cls`

**Purpose:** Service for vendor onboarding wizard operations.

## Handlers

### OnboardingAppRuleEngineHandler

**Location:** `force-app/main/default/classes/OnboardingAppRuleEngineHandler.cls`

**Purpose:** Handler for rule engine events and triggers.

### OnboardingAppVendorProgramReqHdlr

**Location:** `force-app/main/default/classes/handlers/OnboardingAppVendorProgramReqHdlr.cls`

**Purpose:** Handler for vendor program requirement events.

### OnboardingStatusTrackerHandler

**Location:** `force-app/main/default/classes/handlers/OnboardingStatusTrackerHandler.cls`

**Purpose:** Tracks onboarding status changes.

## Validation Rules

### OnboardingAppRuleRegistry

**Location:** `force-app/main/default/classes/OnboardingAppRuleRegistry.cls`

**Purpose:** Central registry of validation rules for onboarding application objects.

**Key Methods:**
- `getRules()` - Returns map of object API names to validation rule lists

**Registered Rules:**
- `Vendor_Program_Recipient_Group__c`:
  - `RequireParentVersionOnActivationRule`
  - `OnlyOneActiveRecGrpPerPrgrmRule`
  - `RecipientAndProgramMustBeActiveRule`
  - `PreventDupRecGrpAssignmentRule`

### OnboardingAppValidationRule

**Location:** `force-app/main/default/classes/OnboardingAppValidationRule.cls`

**Purpose:** Interface for validation rules.

**Key Methods:**
- `validate(SObject record)` - Validates a record
- `getErrorMessage()` - Returns error message

### Rule Implementations

- **RequireParentVersionOnActivationRule** - Requires parent version on activation
- **OnlyOneActiveRecGrpPerPrgrmRule** - Ensures only one active recipient group per program
- **RecipientAndProgramMustBeActiveRule** - Validates recipient and program are active
- **PreventDupRecGrpAssignmentRule** - Prevents duplicate recipient group assignments

## Actions

### OnboardingAppActivationAction

**Location:** `force-app/main/default/classes/actions/OnboardingAppActivationAction.cls`

**Purpose:** Action class for activating records.

**Key Methods:**
- `activate(List<Request> requestList)` - Activates multiple records

**Request Class:**
- `recordId` - Record ID to activate
- `objectApiName` - Object API name

## Repositories

Repository classes follow the pattern `*Repo.cls` and handle data access operations:

- `OnboardingAppVendorProgramReqRepo` - Vendor program requirement data access

## DTOs (Data Transfer Objects)

DTO classes in `dto/` package provide structured data transfer:

- Various DTO classes for data transfer between layers

## Helpers

Helper classes in `helpers/` package provide utility functions:

- Various helper classes for common operations

## Jobs

Scheduled and batch job classes in `jobs/` package:

- Various job classes for background processing

## Test Classes

Test classes follow naming convention `*Test.cls`:

- `OnboardingRulesServiceTest`
- `OnboardingStatusEvaluatorTest`
- `OnlyOneActiveRecGrpPerPrgrmRuleTest`
- `PreventDupRecGrpAssignmentRuleTest`
- `RecipientAndProgramMustBeActiveRuleTest`
- `RequireParentVersionOnActivationRuleTest`
- And many more...

## Class Organization
classes/
├── actions/ # Action classes
├── controllers/ # LWC controllers
├── dto/ # Data transfer objects
├── handlers/ # Event/trigger handlers
├── helpers/ # Utility helpers
├── jobs/ # Scheduled/batch jobs
├── orchestrators/ # Orchestration logic
├── repository/ # Data access layer
├── resolver/ # Resolution logic
├── services/ # Business logic services
├── test/ # Test data factories
├── util/ # Utilities
└── wrappers/ # Wrapper classes


## Best Practices

1. **Service Layer**: Business logic in service classes
2. **Controllers**: Thin controllers that delegate to services
3. **Orchestrators**: Coordinate multiple services
4. **Repositories**: Data access abstraction
5. **Sharing**: Use `with sharing` for security
6. **Error Handling**: Proper exception handling
7. **Testing**: Comprehensive test coverage

## Related Documentation

- [LWC Components](./lwc-components.md)
- [API Reference](../api/apex-api.md)
- [Architecture Overview](../architecture/overview.md)

