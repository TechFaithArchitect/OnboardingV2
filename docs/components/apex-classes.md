# Apex Classes

## Service Layer

### FollowUpFatigueService

**Location:** `force-app/main/default/classes/services/FollowUpFatigueService.cls`

**Purpose:** Handles follow-up fatigue and suppression logic so dealers are not over-contacted.

**Key Methods:**
- `shouldSuppressDueToFatigue(onboardingRequirementId, followUpRuleDeveloperName)` — checks recent follow-up volume, fatigue rule metadata, and active suppression windows.
- `applyFatigueSuppression(followUpQueueId, reason)` / `removeSuppression(followUpQueueId)` — toggles suppression on queue records.
- `updateAttemptTracking(followUpQueueId, wasSuccessful)` — increments attempt counts and consecutive failures.
- `isSuppressedAccount(accountId)` — evaluates active suppression windows (timezone-aware).

### OnboardingApplicationService

**Location:** `force-app/main/default/classes/OnboardingApplicationService.cls`

**Purpose:** Core service for managing onboarding application processes, stages, and progress.

**Key Methods:**
- `getStagesForProcess(Id processId)` - Returns stages for a process, ordered by display order (includes Label__c, Next_Stage__c, Required__c)
- `getProcessDetails(Id processId)` - Returns process details
- `saveProgress(Id processId, Id vendorProgramId, Id stageId)` - Upserts progress record and creates stage completion log (uses upsert for progress, insert for completion)
- `getProgress(Id vendorProgramId, Id processId)` - Retrieves saved progress
- `getProcessIdForVendorProgram(Id vendorProgramId)` - Resolves process ID for a vendor program
- `getUserFacingStage(String technicalStatus)` - Maps Vendor Program technical status to user-friendly stage
  - ⚠️ **ONLY for Vendor_Customization__c.Status__c** - NOT for Onboarding__c.Onboarding_Status__c
  - Delegates to `VendorProgramStatusMapper.getUserFacingStageForCurrentUser()`
- `isCurrentUserAdmin()` - Checks if current user is an admin

**Usage:**
Primary service used by `onboardingFlowEngine` and `onboardingApplicationFlow` LWC components.

### OnboardingRulesService

**Location:** `force-app/main/default/classes/OnboardingRulesService.cls`

**Purpose:** Service for managing onboarding status rules and requirements.

**Key Methods:**
- `getRulesEngineRecords(Id engineId)` - Returns rules for a rules engine
- `createOrUpdateRule(Onboarding_Status_Rule__c rule)` - Creates or updates a rule
- `deleteRule(Id ruleId)` - Deletes a rule
- `getEvaluationContext(Id onboardingId)` - Returns evaluation context with requirements, vendor program ID, and group IDs
- `getRequirementsByVPRBulk(Set<Id> onboardingIds)` - Returns requirements mapped by Vendor Program Requirement ID for multiple onboardings (bulk)
- `getVendorProgramIdsBulk(Set<Id> onboardingIds)` - Gets vendor program IDs for multiple onboardings (bulk)
- `getVendorProgramGroupIdsBulk(Set<Id> vendorProgramIds)` - Gets group IDs for multiple vendor programs (bulk)
- `getVendorProgramGroupIds(Id vendorProgramId)` - Gets group IDs by querying Vendor_Program_Group_Member__c where Required_Program__c matches (single)
- `getRulesForGroups(List<Id> groupIds)` - Gets rules engines with child rules populated via Onboarding_Status_Rules__r relationship

**Usage:**
Used by status evaluation engine and rules management UI.

### OnboardingStatusEvaluator

**Location:** `force-app/main/default/classes/services/OnboardingStatusEvaluator.cls`

**Purpose:** Evaluates onboarding status based on rules engine configuration.

**Key Methods:**
- `evaluateAndApplyStatus(Onboarding__c onboarding)` - Evaluates rules and updates onboarding status (single record)
- `evaluateAndApplyStatus(List<Onboarding__c> onboardings)` - Evaluates rules and updates onboarding status (bulk)

**Flow:**
1. Gets requirements for onboarding(s) using bulk methods
2. Gets vendor program IDs in bulk
3. Gets vendor program group IDs in bulk
4. Gets rules for groups
5. Evaluates each rule
6. Updates onboarding status when rule passes

**Performance:**
- Uses bulk methods from `OnboardingRulesService` for efficient processing
- Optimized for processing multiple onboarding records simultaneously

**Usage:**
Called from flows when onboarding records change. Supports both single record and bulk processing.

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

### OnboardingAccessService

**Location:** `force-app/main/default/classes/services/OnboardingAccessService.cls`

**Purpose:** Service for resolving "ownership" and visibility for Onboarding__c records. Encapsulates all ownership and view-filter logic, including handling Territory_Assignments__c.

**Key Methods:**
- `getUserIdsForViewFilter(String viewFilter)` - Returns set of User IDs for a view filter (MY_VIEW, MY_TEAM, ORG_WIDE)
- `getAccountIdsForOwners(Set<Id> userIds)` - Resolves Account IDs based on Account ownership and Territory Assignments (avoids nested subquery issues)
- `buildOwnerClauseForOnboarding(Set<Id> userIds)` - **@deprecated** - Builds SOQL WHERE clause (use getAccountIdsForOwners instead to avoid subquery issues)

**Ownership Model:**
- Account Owner: `Account__r.OwnerId` is always considered an owner
- Onboarding Reps via Territory_Assignments__c: Users in `Onboarding_Rep__c` or `Base_App_OB_Rep__c` fields
- Territory_Assignments__c links to Account via Zip Code Territory junction

**View Filters:**
- MY_VIEW: Only the current user
- MY_TEAM: Current user + all users in their role hierarchy subtree
- ORG_WIDE: No owner filter; caller sees all records allowed by sharing

**Design Decisions:**
- Pre-resolves Account IDs to avoid SOQL subquery limitations
- Separates ownership logic from controller for reusability
- Respects role hierarchy for team views

**Usage:**
Used by `OnboardingHomeDashboardController` and `OnboardingRepository` for ownership resolution.

### OnboardingDashboardFilterService

**Location:** `force-app/main/default/classes/services/OnboardingDashboardFilterService.cls`

**Purpose:** Centralizes filter logic and date range calculations for the dashboard.

**Key Methods:**
- `getDateRangeFilter(String timeFilter)` - Converts time filter to Date range
- `getViewFilterClause(String viewFilter, Id currentUserId)` - Builds WHERE clause for view filter
- `buildFilterClause(String timeFilter, List<Id> vendorIds, List<Id> programIds, String viewFilter)` - Builds complete WHERE clause with all filters
- `buildLastModifiedFilterClause(String timeFilter, List<Id> vendorIds, List<Id> programIds, String viewFilter)` - Builds WHERE clause for LastModifiedDate filters

**Time Filters:**
- LAST_30_DAYS: Records from last 30 days
- LAST_90_DAYS: Records from last 90 days (default)
- YEAR_TO_DATE: Records from January 1st of current year
- ALL_TIME: No time restriction

**Usage:**
Used by `OnboardingHomeDashboardController` for filter logic.

### OnboardingBlockingDetectionService

**Location:** `force-app/main/default/classes/services/OnboardingBlockingDetectionService.cls`

**Purpose:** Detects blocked/at-risk onboarding records.

**Key Methods:**
- `getBlockedOnboardingIds(List<Id> onboardingIds)` - Returns IDs of blocked onboarding records
- `getBlockingReasons(Id onboardingId)` - Returns list of blocking reasons
- `isAtRisk(Id onboardingId, Integer daysThreshold)` - Checks if onboarding is at risk
- `getBlockingInfoBulk(List<Id> onboardingIds)` - Gets blocking info for multiple records (returns Map<Id, BlockingInfo>)

**Blocking Detection:**
- Uses `OnboardingStatusEvaluator` to check requirement status
- Uses `OnboardingStageDependencyService` to check stage dependencies
- Combines both sources for comprehensive blocking detection

**Usage:**
Used by `OnboardingHomeDashboardController` for identifying blocked/at-risk records.

## Controllers

### RequirementFieldValueController

**Location:** `force-app/main/default/classes/controllers/RequirementFieldValueController.cls`

**Purpose:** Saves requirement field values (plain or encrypted) and updates the related `Onboarding_Requirement__c` status.

**Key Methods:**
- `saveFieldValue(requirementFieldValueId, requirementFieldId, onboardingRequirementId, fieldApiName, value, isEncrypted)` — upserts a field value, triggers sync validation and async enqueue, then recalculates requirement status.

### OnboardingHomeDashboardController

**Location:** `force-app/main/default/classes/controllers/OnboardingHomeDashboardController.cls`

**Purpose:** Controller for the onboarding home dashboard LWC component. Provides methods for retrieving dashboard data including active onboarding records, summary statistics, eligible accounts, and recent activity.

**Key Methods:**
- `getMyActiveOnboarding(timeFilter, vendorIds, programIds, viewFilter)` - Returns active onboarding records with filters
  - Filters by ownership (via `OnboardingAccessService`) and time range
  - Supports view filters: MY_VIEW, MY_TEAM, ORG_WIDE
  - Excludes Complete, Denied, and Expired statuses
  - Limits to 20 most recently modified records
  - Returns as `List<OnboardingDTO>`

- `getOnboardingSummary(timeFilter, vendorIds, programIds, viewFilter)` - Returns summary statistics grouped by onboarding status
  - Aggregates counts by status with filters applied
  - Supports view filters: MY_VIEW, MY_TEAM, ORG_WIDE
  - Returns `Map<String, Integer>` with status counts
  - Includes Total count

- `getEligibleAccounts(timeFilter, vendorIds, programIds)` - Returns accounts that can start new onboarding
  - Uses `OnboardingEligibilityService.getEligibleVendorCountsByAccount()` to determine eligibility
  - Returns accounts that have eligible vendor programs not yet onboarded
  - Includes Account details (Name, Territory, Region) and eligible vendor count
  - Returns as `List<AccountDTO>`

- `getRecentActivity(recordLimit, timeFilter, vendorIds, programIds)` - Returns recent onboarding activity with filters
  - Shows records with filters applied
  - Ordered by LastModifiedDate descending
  - Default limit of 10 records (configurable)
  - Returns as `List<OnboardingDTO>`

- `getVendorProgramMetrics(timeFilter, vendorIds)` - Returns vendor program health metrics
  - Includes dealer counts, requirement progress, health indicators
  - Returns as `List<VendorProgramMetricsDTO>`

- `getBlockedOnboardingCount(timeFilter, vendorIds, programIds)` - Returns count of blocked/at-risk records
  - Uses `OnboardingBlockingDetectionService` for detection
  - Returns integer count

- `getTeamOnboarding(viewFilter, timeFilter, vendorIds, programIds)` - Returns team/org queue data
  - Supports MY_TEAM and ORG_WIDE view filters
  - Returns as `List<OnboardingDTO>`

- `getOnboardingWithBlockingInfo(onboardingIds)` - Returns onboarding records with blocking information
  - Adds blocking reasons and at-risk indicators
  - Returns as `List<OnboardingWithBlockingDTO>`

- `getVendors()` - Returns list of vendors for filter dropdown
  - Returns as `List<Map<String, String>>` with label/value pairs

- `getVendorPrograms()` - Returns list of vendor programs for filter dropdown
  - Returns as `List<Map<String, String>>` with label/value pairs

- `getAllActiveOnboarding()` - Returns all active onboarding records (not filtered by creator)
  - Useful for admins/managers
  - Excludes Complete, Denied, and Expired statuses
  - Limited to 50 most recently modified records
  - Returns as `List<OnboardingDTO>`

**DTOs (Data Transfer Objects):**
- `OnboardingDTO` - Represents an onboarding record with related data (Dealer Onboarding)
  - Fields: Id, Name, Status, AccountId, AccountName, VendorProgramId, VendorProgramName, CreatedDate, LastModifiedDate, CreatedById, CreatedByName, RecordUrl
  - Note: Uses `CreatedById`/`CreatedByName` instead of `OwnerId`/`OwnerName` because `Onboarding__c` doesn't have Owner field
  - ⚠️ **Important**: The `Status` field contains `Onboarding__c.Onboarding_Status__c` (Dealer Onboarding status) and should be displayed AS-IS without simplification. Do NOT use `VendorProgramStatusMapper` for this status.
  - **Note**: Class is now `virtual` to allow extension by `OnboardingWithBlockingDTO`

- `OnboardingWithBlockingDTO` - Extends OnboardingDTO with blocking information
  - Extends `OnboardingDTO` (which is now `virtual`)
  - Additional Fields: IsBlocked, IsAtRisk, BlockingReasons, AgeInDays
  - Used by blocking detection service to provide comprehensive blocking information

- `AccountDTO` - Represents an account eligible for onboarding
  - Fields: Id, Name, Territory, Region, EligibleVendorCount, RecordUrl

- `VendorProgramMetricsDTO` - Contains vendor program health metrics
  - Fields: Id, Name, Label, VendorId, VendorName, Status, Active, RecordUrl
  - Metrics: DealersOnboarded, InProgressCount, BlockedCount, TotalRequirements, CompleteRequirements
  - Health Indicators: RulesEngineValid, DependenciesValid
  - GroupNames: List of associated group names

**Design Decisions:**
- **Ownership Model:** Uses `OnboardingAccessService` to resolve ownership based on Account Owner and Territory Assignments. Ownership is determined by:
  1. Account Owner (`Account__r.OwnerId`)
  2. Onboarding Reps via `Territory_Assignments__c` (Onboarding_Rep__c, Base_App_OB_Rep__c)
- **Account-Based Sharing:** Access to onboarding records is controlled by Account sharing rules. The `with sharing` keyword ensures proper security.
- **View Filters:** Supports MY_VIEW (current user), MY_TEAM (role hierarchy), ORG_WIDE (all accessible records)

**Security:**
- Uses `with sharing` to respect Account sharing rules
- Only returns records accessible to the current user based on Account access
- Ownership resolution respects role hierarchy for team views

**Performance:**
- All methods are `@AuraEnabled(cacheable=true)` for client-side caching
- Limits are applied to prevent large result sets
- Bulk queries where possible (e.g., eligible accounts checks multiple accounts at once)
- Ownership resolution uses pre-resolved Account IDs to avoid nested subqueries

**Dependencies:**
- `OnboardingAccessService` - Ownership and view filter resolution
- `OnboardingRepository` - Data access layer
- `OnboardingDashboardFilterService` - Filter logic
- `OnboardingBlockingDetectionService` - Blocking detection

**Usage:**
Used by `onboardingHomeDashboard` LWC component. All methods are called via `@wire` for automatic data loading and refresh.

### OnboardingRequirementsPanelController

**Location:** `force-app/main/default/classes/OnboardingRequirementsPanelController.cls`

**Purpose:** Controller for the onboarding requirements panel LWC.

**Key Methods:**
- `getRequirements(Id onboardingId)` - Returns requirements as RequirementDTO objects
- `updateRequirementStatuses(List<RequirementDTO> updates)` - Updates requirement statuses using DTOs and automatically triggers status re-evaluation for affected onboardings
- `runRuleEvaluation(Id onboardingId)` - Triggers status re-evaluation for a single onboarding

**RequirementDTO Class:**
- Inner class used for data transfer
- Fields: `Id`, `Name`, `Status`

**RequirementDTO Class:**
- Inner class used for data transfer
- Fields: `Id`, `Name`, `Status`

**Usage:**
Used by `onboardingRequirementsPanel` LWC.

### OnboardingStatusRulesEngineController

**Location:** `force-app/main/default/classes/OnboardingStatusRulesEngineController.cls`

**Purpose:** Controller for the status rules engine management UI.

**Key Methods:**
- `getVendorProgramGroups()` - Returns vendor program groups for picklist (returns List<Map<String, String>> with 'value' and 'label' keys)
- `getRequirementGroups()` - Returns Vendor_Program_Requirement_Group__c records for picklist (returns List<Map<String, String>> with 'value' and 'label' keys)
- `getRules(Id vendorProgramGroupId, Id requirementGroupId)` - Returns rules engines filtered by both vendor program group and requirement group (includes Id, Required_Status__c, Target_Onboarding_Status__c, Evaluation_Logic__c, Custom_Evaluation_Logic__c)
- `saveRules(List<Onboarding_Status_Rules_Engine__c> rules)` - Saves rules engine changes

**Note:** `getRequirementGroups()` queries `Vendor_Program_Requirement_Group__c` object, not a generic requirement group.

**Usage:**
Used by `onboardingStatusRulesEngine` LWC.

### OnboardingStatusRuleController

**Location:** `force-app/main/default/classes/OnboardingStatusRuleController.cls`

**Purpose:** Controller for status rule list and management components.

**Key Methods:**
- `getRules(Id vendorProgramGroupId)` - Returns rules engines for a vendor program group
- `getRule(Id ruleId)` - Returns a single rules engine by ID
- `getConditions(Id ruleId)` - Returns rule conditions for a rules engine
- `saveRule(Onboarding_Status_Rules_Engine__c rule)` - Saves a rules engine
- `saveConditions(List<Onboarding_Status_Rule__c> conditions)` - Saves rule conditions
- `deleteCondition(Id conditionId)` - Deletes a rule condition

**Usage:**
Used by `onboardingStatusRuleList` and related LWC components.

### OnboardingAppECCController

**Location:** `force-app/main/default/classes/OnboardingAppECCController.cls`

**Purpose:** Controller for External Contact Credential (ECC) management.

**Key Methods:**
- `getRequiredCredentials(Id vendorProgramId)` - Returns required credentials for a vendor program
- `getAvailableCredentialTypes()` - Returns available credential types
- `createCredentialType(String name)` - Creates a new credential type
- `linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId)` - Links credential type to required credential

**Usage:**
Used by `onboardingAppVendorProgramECCManager` LWC component.

**Dependencies:**
- `OnboardingAppECCService` - Business logic layer
- `OnboardingAppECCRepository` - Data access layer

### OnboardingAppActivationController

**Location:** `force-app/main/default/classes/controllers/OnboardingAppActivationController.cls`

**Purpose:** Controller for activating versioned records (vendor programs, etc.).

**Key Methods:**
- `activate(Id recordId, String objectApiName)` - Activates a record via orchestrator

**Usage:**
Used by `onboardingAppHeaderBar` LWC component.

### VendorOnboardingWizardController

**Location:** `force-app/main/default/classes/controllers/VendorOnboardingWizardController.cls`

**Purpose:** Primary controller for the Vendor Program Onboarding Wizard. Exposes all Apex methods needed by wizard components.

**Key Methods:**

#### Vendor Management
- `searchVendors(String vendorNameSearchText)` - Searches for vendors by name
- `createVendor(Vendor__c vendor)` - Creates new vendor record

#### Vendor Program Management
- `searchVendorPrograms(String vendorProgramNameSearchText)` - Searches for vendor programs by name
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates new draft vendor program
- `getRecentVendorPrograms(Integer limitCount)` - Gets recent vendor programs
- `getRetailOptionPicklistValues()` - Gets Retail Option picklist values (cacheable)
- `getBusinessVerticalPicklistValues()` - Gets Business Vertical picklist values (cacheable)
- `getVendorProgramLabel(Id vendorProgramId)` - Gets Vendor Program Label

#### Requirement Set Management
- `searchOnboardingRequirementSets(String searchText, Id vendorProgramId)` - Searches for requirement sets
- `linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)` - Links existing requirement set to vendor program
- `createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId, String vendorProgramLabel)` - Creates new requirement set by copying existing one
- `getTemplatesForRequirementSet(Id requirementSetId)` - Gets templates for a requirement set
- `createRequirementFromTemplate(Id templateId, Id vendorProgramId)` - Creates Vendor_Program_Requirement__c from template

#### Requirement Group Linking
- `getHistoricalGroupMembers(Id requirementSetId)` - Gets historical group members from requirement set
- `createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical)` - Creates and links all requirement group components

#### Status Rules Engine
- `getHistoricalStatusRulesEngines(Id requirementSetId)` - Gets historical status rules engines from requirement set
- `searchStatusRulesEngines(String nameSearchText)` - Searches for status rules engines
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Creates new status rules engine
- `getEvaluationLogicPicklistValues()` - Gets Evaluation Logic picklist values (cacheable)
- `getRequiredStatusPicklistValues()` - Gets Required Status picklist values (cacheable)
- `getTargetOnboardingStatusPicklistValues()` - Gets Target Onboarding Status picklist values (cacheable)

#### Recipient Groups
- `searchRecipientGroups(String recipientGroupNameSearchText)` - Searches for recipient groups
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates new recipient group
- `createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Creates recipient group member
- `getRecipientGroupsForVendorProgram(Id vendorProgramId)` - Gets recipient groups for vendor program
- `getRecipientGroupMembers(Id recipientGroupId)` - Gets members for a recipient group
- `getAssignableUsers()` - Gets assignable users for recipient group members
- `getGroupTypePicklistValues()` - Gets Group Type picklist values (cacheable)

#### Communication Templates
- `getCommunicationTemplates()` - Gets all communication templates
- `createVendorProgramRecipientGroupWithTemplate(Id vendorProgramId, Id recipientGroupId, Id communicationTemplateId, String triggerCondition)` - Creates link with template and trigger condition

#### Component Library
- `syncRendererComponents()` - Syncs component library (InvocableMethod for Flow/Process Builder)

**Dependencies:**
- `VendorOnboardingWizardService` - Business logic layer
- `VendorOnboardingWizardRepository` - Data access layer

**Usage:**
Used by all Vendor Program Onboarding Wizard LWC components.

**Security:**
- Uses `with sharing` to respect sharing rules
- All methods are `@AuraEnabled` for LWC access

## Vendor Onboarding Wizard Service Layer

### VendorOnboardingWizardService (Facade)

**Location:** `force-app/main/default/classes/services/VendorOnboardingWizardService.cls`

**Purpose:** Facade service that delegates to domain-specific services. Maintains backward compatibility while improving code organization. **Note:** This service is deprecated - use domain-specific services directly.

**Architecture:** This service acts as a facade pattern, delegating all calls to domain-specific services:
- `VendorService` - Vendor operations
- `VendorProgramService` - Vendor Program operations
- `VendorProgramGroupService` - Vendor Program Group operations
- `VendorProgramRequirementGroupService` - Requirement Group operations
- `VendorProgramRequirementService` - Requirement operations
- `OnboardingRequirementSetService` - Requirement Set operations
- `RecipientGroupService` - Recipient Group operations
- `StatusRulesEngineService` - Status Rules Engine operations
- `CommunicationTemplateService` - Communication Template operations

**Key Methods:** All methods delegate to corresponding domain services (see individual service documentation below).


#### Vendor Operations
- `searchVendors(String vendorName)` - Searches vendors
- `createVendor(Vendor__c vendor)` - Creates vendor (sets Active__c = false)

#### Vendor Program Operations
- `searchVendorPrograms(String vendorProgramName)` - Searches vendor programs
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates draft vendor program (Status__c = 'Draft', Active__c = false)
- `getRecentVendorPrograms(Integer limitCount)` - Gets recent vendor programs

#### Requirement Set Operations
- `searchOnboardingRequirementSets(String searchText, Id vendorProgramId)` - Searches requirement sets
- `linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)` - Links requirement set to vendor program
- `createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId, String vendorProgramLabel)` - Creates new requirement set with naming convention
- `getTemplatesForRequirementSet(Id requirementSetId)` - Gets templates for requirement set
- `createRequirementFromTemplate(Id templateId, Id vendorProgramId)` - Creates requirement from template

#### Requirement Group Operations
- `getHistoricalGroupMembers(Id requirementSetId)` - Gets historical group members
- `createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical)` - Creates and links all requirement group components with naming conventions

#### Status Rules Engine Operations
- `getHistoricalStatusRulesEngines(Id requirementSetId)` - Gets historical status rules engines
- `searchStatusRulesEngines(String onboardingStatusRulesEngine)` - Searches status rules engines
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Creates status rules engine with defaults

#### Recipient Group Operations
- `searchRecipientGroups(String recipientGroupName)` - Searches recipient groups
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates recipient group with defaults
- `createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Creates recipient group member with defaults
- `getRecipientGroupsForVendorProgram(Id vendorProgramId)` - Gets recipient groups for vendor program
- `getRecipientGroupMembers(Id recipientGroupId)` - Gets members for recipient group
- `createVendorProgramRecipientGroupWithTemplate(Id vendorProgramId, Id recipientGroupId, Id communicationTemplateId, String triggerCondition)` - Creates link with template and condition

#### Component Library
- `syncComponentLibrary()` - Syncs component library with all wizard components

**Naming Conventions:**
- Requirement Set: `"Vendor Program Label - Onboarding Set"`
- Vendor Program Group: `"Vendor Program Label - Vendor Program Group"`
- Requirement Group: `"Vendor Program Label - Requirement Group"`

**Default Values:**
- New vendors: `Active__c = false`
- New vendor programs: `Status__c = 'Draft'`, `Active__c = false`
- New requirement sets: `Status__c = 'Draft'`
- New recipient groups: `Group_Type__c = 'User'`, `Is_Active__c = true`
- New recipient group members: `Member_Type__c = 'User'`, `Recipient_Type__c = 'To'`

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access layer

**Security:**
- Uses `with sharing` to respect sharing rules

## Vendor Onboarding Wizard Repository Layer

### VendorOnboardingWizardRepository

**Location:** `force-app/main/default/classes/repository/VendorOnboardingWizardRepository.cls`

**Purpose:** Data access layer for Vendor Program Onboarding Wizard operations. Handles all SOQL queries and DML operations.

**Key Methods:**

#### Vendor Operations
- `searchVendors(String vendorName)` - SOQL query for vendors
- `insertVendor(Vendor__c vendor)` - DML insert for vendor

#### Vendor Program Operations
- `searchVendorPrograms(String vendorProgramName)` - SOQL query for vendor programs
- `insertVendorProgram(Vendor_Customization__c vendorProgram)` - DML insert for vendor program
- `getRecentVendorPrograms(Integer limitCount)` - SOQL query for recent vendor programs
- `getVendorProgramLabel(Id vendorProgramId)` - Gets Label__c from Vendor_Customization__c

#### Requirement Set Operations
- `searchOnboardingRequirementSets(String searchText, Id vendorProgramId)` - SOQL query for requirement sets
- `linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)` - DML update to link requirement set
- `getRequirementSetWithTemplates(Id requirementSetId)` - Gets requirement set with child templates
- `getRequirementTemplate(Id templateId)` - Gets single template record
- `insertOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - DML insert for requirement set
- `insertVendorProgramRequirement(Vendor_Program_Requirement__c requirement)` - DML insert for requirement

#### Requirement Group Operations
- `getHistoricalGroupMembers(Id requirementSetId)` - Gets historical group members with related data
- `insertVendorProgramGroup(Vendor_Program_Group__c group)` - DML insert for vendor program group
- `insertVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c group)` - DML insert for requirement group
- `insertVendorProgramGroupMember(Vendor_Program_Group_Member__c member)` - DML insert for group member

#### Status Rules Engine Operations
- `getHistoricalStatusRulesEngines(Id requirementSetId)` - Gets historical engines with related data
- `searchStatusRulesEngines(String onboardingStatusRulesEngine)` - SOQL query for status rules engines
- `insertOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c engine)` - DML insert for status rules engine

#### Recipient Group Operations
- `searchRecipientGroups(String recipientGroupName)` - SOQL query for recipient groups
- `insertRecipientGroup(Recipient_Group__c group)` - DML insert for recipient group
- `insertRecipientGroupMember(Recipient_Group_Member__c member)` - DML insert for recipient group member
- `getRecipientGroupsForVendorProgram(Id vendorProgramId)` - Gets recipient groups for vendor program
- `getRecipientGroupMembers(Id recipientGroupId)` - Gets members for recipient group
- `insertVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - DML insert for vendor program recipient group link

#### Communication Template Operations
- `getCommunicationTemplates()` - SOQL query for communication templates

#### User Operations
- `getAssignableUsers()` - SOQL query for assignable users

**Query Patterns:**
- Uses `LIKE` with wildcards for search operations
- Includes related object fields via relationship queries (e.g., `Recipient_Group__r.Name`)
- Applies limits to prevent large result sets
- Uses `ORDER BY` for consistent sorting

**DML Patterns:**
- Single record inserts for new records
- Updates for linking operations
- No bulk operations (handled by service layer if needed)

**Security:**
- Uses `with sharing` to respect sharing rules
- All queries respect field-level security

**Error Handling:**
- Repository methods throw exceptions that are caught by service layer
- Service layer provides user-friendly error messages

**Dependencies:**
- `OnboardingAppActivationOrchestrator` - Orchestrates activation process

### OnboardingAppECCController

**Location:** `force-app/main/default/classes/OnboardingAppECCController.cls`

**Purpose:** Controller for External Contact Credential (ECC) management.

**Key Methods:**
- `getRequiredCredentials(Id vendorProgramId)` - Returns required credentials for a vendor program (cacheable)
- `getAvailableCredentialTypes()` - Returns all available credential types (cacheable)
- `createCredentialType(String name)` - Creates a new credential type
- `linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId)` - Links a credential type to a required credential

**Usage:**
Used by `onboardingAppVendorProgramECCManager` LWC component.

**Dependencies:**
- `OnboardingAppECCService` - Business logic layer
- `OnboardingAppECCRepository` - Data access layer

## Orchestrators

### OnboardingAppActivationOrchestrator

**Location:** `force-app/main/default/classes/orchestrators/OnboardingAppActivationOrchestrator.cls`

**Purpose:** Orchestrates the activation workflow for onboarding application objects. Routes activation requests to appropriate service based on object type.

**Key Methods:**
- `activate(Id recordId, String objectApiName)` - Activates a record with validation

**Flow:**
1. Validates input parameters
2. Routes to specialized service for `Vendor_Customization__c` (calls `VendorProgramActivationService`)
3. Routes to generic service for other objects (calls `OnboardingAppActivationService`)
4. Note: Activation rules are executed by the services, not by the orchestrator

**Routing Logic:**
- `Vendor_Customization__c` → `VendorProgramActivationService.activate()`
- `Communication_Template__c` → `OnboardingAppActivationService.activateRecord()`
- All other objects → `OnboardingAppActivationService.activateRecord()`

**Note:** Orchestrator does not execute activation rules directly - this is handled by the services. Both `VendorProgramActivationService` and `OnboardingAppActivationService` execute activation rules before activation.

### OnboardingAppVendorProgramReqOrch

**Location:** `force-app/main/default/classes/orchestrators/OnboardingAppVendorProgramReqOrch.cls`

**Purpose:** Orchestrates vendor program requirement operations.

## Services

### OnboardingAppActivationService

**Location:** `force-app/main/default/classes/services/OnboardingAppActivationService.cls`

**Purpose:** Generic activation service that handles activation for any object type with versioning support.

**Key Methods:**
- `activateRecord(String objectApiName, Id recordId)` - Activates a record with validation

**Activation Flow:**
1. Executes activation rules from `OnboardingAppRuleRegistry.getActivationRulesForObject()`
2. Prevents re-activation (checks if already active)
3. Deactivates sibling versions if versioning is supported
4. Sets record to active status

**Guards Implemented:**
- ✅ Executes activation rules before activation
- ✅ Prevents re-activation
- ✅ Handles versioning (deactivates siblings)
- ✅ Supports both `Active__c` and `Is_Active__c` fields

### VendorProgramActivationService

**Location:** `force-app/main/default/classes/services/VendorProgramActivationService.cls`

**Purpose:** Specialized activation service for `Vendor_Customization__c` records.

**Key Methods:**
- `activate(Id recordId)` - Activates a vendor program record
- `activateBulk(Set<Id> recordIds)` - Activates multiple vendor programs in bulk

**Activation Flow:**
1. Executes activation rules from `OnboardingAppRuleRegistry.getActivationRulesForObject('Vendor_Customization__c')`
2. Prevents re-activation (checks if already active)
3. Deactivates sibling versions
4. Sets record to active status
5. Executes post-activation hooks

**Guards Implemented:**
- ✅ Executes activation rules before activation
- ✅ Prevents re-activation
- ✅ Handles versioning (deactivates siblings)
- ✅ Supports bulk activation for better performance

### OnboardingAppECCService

**Location:** `force-app/main/default/classes/OnboardingAppECCService.cls`

**Purpose:** Service for External Contact Credential (ECC) operations. Provides business logic for managing required credentials and credential types.

**Key Methods:**
- `getRequiredCredentials(Id vendorProgramId)` - Gets required credentials for a vendor program
- `getAvailableCredentialTypes()` - Gets all available credential types
- `createCredentialType(String name)` - Creates a new credential type
- `linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId)` - Links a credential type to a required credential

**Usage:**
Used by `OnboardingAppECCController` for ECC management operations.

### VendorOnboardingWizardService

**Location:** `force-app/main/default/classes/services/VendorOnboardingWizardService.cls`

**Purpose:** Service for vendor onboarding wizard operations. Provides business logic for creating and managing vendor onboarding entities including vendors, vendor programs, groups, requirement sets, recipient groups, status rules engines, and communication templates.

**Key Methods:**

**Vendor Operations:**
- `searchVendors(String vendorName)` - Searches for vendors by name (delegates to repository)
- `createVendor(Vendor__c vendor)` - Creates a new vendor record. Sets `Active__c = false` to save as draft before inserting via repository

**Vendor Program Operations:**
- `searchVendorPrograms(String vendorProgramName)` - Searches for vendor programs by name
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates a new vendor program. Sets `Vendor__c`, `Active__c = false`, and `Status__c = 'Draft'` before inserting
- `finalizeVendorProgram(Id vendorProgramId, Id vendorId, Id vendorProgramGroupId, Id vendorProgramRequirementGroupId)` - Links vendor program to vendor, program group, and requirement group. This is the final step in the vendor program setup wizard

**Vendor Program Group Operations:**
- `searchVendorProgramGroups(String vendorProgramGroupName)` - Searches for vendor program groups by name
- `createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup)` - Creates a new vendor program group

**Vendor Program Requirement Group Operations:**
- `searchVendorProgramRequirementGroups(String requirementGroupName)` - Searches for requirement groups by name
- `createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup)` - Creates a new requirement group

**Vendor Program Requirement Operations:**
- `searchVendorProgramRequirements(String vendorProgramRequirements)` - Searches for vendor program requirements by name
- `createVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement)` - Creates a new vendor program requirement

**Onboarding Status Rules Engine Operations:**
- `searchStatusRulesEngines(String onboardingStatusRulesEngine)` - Searches for status rules engines by name
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Creates a new status rules engine

**Onboarding Status Rules Operations:**
- `createStatusRule(Onboarding_Status_Rule__c rule)` - Creates a new status rule
- `searchStatusRules(String nameSearchText)` - Searches for status rules by name

**Communication Templates Operations:**
- `getCommunicationTemplates()` - Retrieves all communication templates (ordered by Name, limit 100)
- `linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId)` - Links a communication template to a vendor program

**Onboarding Requirement Set Operations:**
- `createOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - Creates a new requirement set. Sets `Status__c = 'Draft'` before inserting
- `getOnboardingRequirementSets()` - Retrieves all requirement sets (ordered by CreatedDate DESC, limit 100)

**Onboarding Requirement Templates Operations:**
- `createOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template)` - Creates a new requirement template
- `getRequirementTemplatesForSet(Id requirementSetId)` - Gets all templates for a specific requirement set
- `assignTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds)` - Assigns multiple templates to a requirement group by updating the `Category_Group__c` field

**Recipient Groups Operations:**
- `searchRecipientGroups(String recipientGroupName)` - Searches for recipient groups by name
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates a new recipient group
- `createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Creates a recipient group member

**Vendor Program Recipient Groups Operations:**
- `searchVendorProgramRecipientGroups(String vprgName)` - Searches for vendor program recipient groups by name
- `createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - Creates a link between vendor program and recipient group. Sets `Status__c = 'Draft'` on the link record

**Miscellaneous Operations:**
- `getTerritoryRoleAssignments()` - Gets all territory role assignments (ordered by Name)
- `getAssignableUsers()` - Gets all active users (ordered by Name)
- `getPublicGroups()` - Gets all public groups (ordered by Name)

**Usage:**
Used by `VendorOnboardingWizardController` and wizard LWC components for vendor onboarding setup workflows. All methods delegate to `VendorOnboardingWizardRepository` for data access operations.

### VendorOnboardingWizardController

**Location:** `force-app/main/default/classes/controllers/VendorOnboardingWizardController.cls`

**Purpose:** Controller for vendor onboarding wizard LWC components. Provides AuraEnabled methods for vendor, vendor program, groups, requirement sets, recipient groups, status rules, and communication templates operations. All methods delegate to `VendorOnboardingWizardService`.

**Key Methods:**

**Vendor Operations:**
- `searchVendors(String vendorNameSearchText)` - Searches vendors by name. Cacheable method that delegates to service layer
- `createVendor(Vendor__c vendor)` - Creates a vendor record. Delegates to service which sets vendor as draft before creating

**Vendor Program Operations:**
- `searchVendorPrograms(String vendorProgramNameSearchText)` - Searches vendor programs by name. Cacheable method
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates a vendor program linked to a vendor. Delegates to service which sets status to 'Draft' and active to false
- `finalizeVendorProgram(Id vendorProgramId, Id vendorId, Id vendorProgramGroupId, Id vendorProgramRequirementGroupId)` - Finalizes vendor program setup by linking it to vendor, program group, and requirement group. This is called from the final step of the wizard

**Vendor Program Group Operations:**
- `searchVendorProgramGroups(String vendorProgramGroupNameSearchText)` - Searches vendor program groups by name. Cacheable method
- `createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup)` - Creates a vendor program group. **Note:** Service layer now validates that `Label__c` and `Logic_Type__c` are provided (no auto-filling). Throws exception if missing.

**Vendor Program Requirement Group Operations:**
- `searchVendorProgramRequirementGroups(String requirementGroupNameSearchText)` - Searches requirement groups by name. Cacheable method
- `createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup)` - Creates a requirement group

**Vendor Program Requirement Operations:**
- `searchVendorProgramRequirements(String vendorProgramRequirements)` - Searches vendor program requirements by name. Cacheable method
- `createVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement)` - Creates a vendor program requirement

**Onboarding Status Rules Engine Operations:**
- `searchStatusRulesEngines(String nameSearchText)` - Searches status rules engines by name. Cacheable method
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Creates a status rules engine

**Onboarding Status Rules Operations:**
- `createStatusRule(Onboarding_Status_Rule__c rule)` - Creates a status rule
- `searchStatusRules(String nameSearchText)` - Searches status rules by name. Cacheable method

**Communication Templates Operations:**
- `getCommunicationTemplates()` - Gets all communication templates. Cacheable method
- `linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId)` - Links a communication template to a vendor program

**Onboarding Requirement Set Operations:**
- `createOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - Creates a requirement set. Service sets status to 'Draft'
- `getOnboardingRequirementSets()` - Gets all requirement sets. Cacheable method

**Onboarding Requirement Templates Operations:**
- `createOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template)` - Creates a requirement template
- `getRequirementTemplatesForSet(Id requirementSetId)` - Gets templates for a specific requirement set. Cacheable method
- `assignTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds)` - Assigns multiple templates to a requirement group

**Recipient Groups Operations:**
- `searchRecipientGroups(String recipientGroupNameSearchText)` - Searches recipient groups by name. Cacheable method
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates a recipient group
- `createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Creates a recipient group member

**Vendor Program Recipient Groups Operations:**
- `searchVendorProgramRecipientGroups(String vprgNameSearchText)` - Searches vendor program recipient groups by name. Cacheable method
- `createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - Creates a link between vendor program and recipient group. Service sets status to 'Draft'

**Miscellaneous Operations:**
- `getTerritoryRoleAssignments()` - Gets all territory role assignments. Cacheable method
- `getAssignableUsers()` - Gets all active users. Cacheable method
- `getPublicGroups()` - Gets all public groups. Cacheable method

**Picklist Value Methods (New):**
These methods provide picklist values for form dropdowns in the wizard, ensuring users see the correct options from Salesforce. All are cacheable for performance.

- `getLogicTypePicklistValues()` - Returns picklist values for `Logic_Type__c` on `Vendor_Program_Group__c`. Returns list of maps with 'label' and 'value' keys
- `getStatusPicklistValues()` - Returns picklist values for `Status__c` on `Vendor_Program_Requirement_Group__c`
- `getGroupTypePicklistValues()` - Returns picklist values for `Group_Type__c` on `Recipient_Group__c`
- `getEvaluationLogicPicklistValues()` - Returns picklist values for `Evaluation_Logic__c` on `Onboarding_Status_Rules_Engine__c` (ALL, ANY, CUSTOM)
- `getRequiredStatusPicklistValues()` - Returns picklist values for `Required_Status__c` on `Onboarding_Status_Rules_Engine__c`
- `getTargetOnboardingStatusPicklistValues()` - Returns picklist values for `Target_Onboarding_Status__c` on `Onboarding_Status_Rules_Engine__c`
- `getPicklistValues(String objectName, String fieldName, List<String> fallbackValues)` - Private helper method that dynamically fetches picklist values from Salesforce schema. Includes fallback values if schema describe fails

**Validation Changes:**
- All create methods now use `ValidationHelper` for consistent input validation
- `createVendorProgramGroup()` - Validates that `Label__c` and `Logic_Type__c` are provided using `ValidationHelper.requireFieldForObject()`

**Usage:**
Used by vendor onboarding wizard LWC components for multi-step vendor setup workflows. All search methods are cacheable for better performance. All create/finalize methods are not cacheable as they perform DML operations. Picklist methods enable dynamic form dropdowns with proper Salesforce values.

### VendorOnboardingWizardRepository

**Location:** `force-app/main/default/classes/repository/VendorOnboardingWizardRepository.cls`

**Purpose:** Repository for vendor onboarding wizard data access operations. Handles all database queries and DML for vendor onboarding entities. This is the data access layer that performs all SOQL queries and DML operations.

**Key Methods:**

**Vendor Operations:**
- `searchVendors(String vendorName)` - Queries vendors by name using LIKE pattern (`'%' + vendorName + '%'`). Returns `Id` and `Name` fields, limit 10
- `insertVendor(Vendor__c vendor)` - Inserts a vendor record and returns the new record ID

**Vendor Program Operations:**
- `searchVendorPrograms(String vendorProgramName)` - Queries `Vendor_Customization__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertVendorProgram(Vendor_Customization__c vendorProgram)` - Inserts a vendor program record and returns the new record ID
- `linkVendorProgramToGroups(Id vendorProgramId, Id vendorId, Id vendorProgramGroupId, Id vendorProgramRequirementGroupId)` - Updates a vendor program record to link it to vendor, program group, and requirement group. Queries the vendor program first, then updates the lookup fields

**Vendor Program Group Operations:**
- `searchVendorProgramGroups(String vendorProgramGroupName)` - Queries `Vendor_Program_Group__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup)` - Inserts a vendor program group record and returns the new record ID

**Vendor Program Requirement Group Operations:**
- `searchVendorProgramRequirementGroups(String requirementGroupName)` - Queries `Vendor_Program_Requirement_Group__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup)` - Inserts a requirement group record and returns the new record ID

**Vendor Program Requirement Operations:**
- `searchVendorProgramRequirements(String vendorProgramRequirements)` - Queries `Vendor_Program_Requirement__c` records by name using LIKE pattern. Returns `Id`, `Name`, `Vendor_Program__c` (lookup to `Vendor_Customization__c`), `Inherited_From_Group__c`, `Requirement_Group_Member__c`, and `Requirement_Template__c` fields, limit 10
- `insertVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement)` - Inserts a vendor program requirement record and returns the new record ID

**Onboarding Status Rules Engine Operations:**
- `searchStatusRulesEngines(String nameSearchText)` - Queries `Onboarding_Status_Rules_Engine__c` records by name using LIKE pattern. Returns `Id`, `Name`, `Requirement_Group__c`, and `Vendor_Program_Group__c` fields, limit 10
- `insertOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Inserts a status rules engine record and returns the new record ID

**Onboarding Status Rules Operations:**
- `insertStatusRule(Onboarding_Status_Rule__c rule)` - Inserts a status rule record and returns the new record ID
- `searchStatusRules(String nameSearchText)` - Queries `Onboarding_Status_Rule__c` records by name using LIKE pattern. Returns `Id`, `Name`, `Parent_Rule__c`, and `Requirement__c` fields, limit 10

**Communication Templates Operations:**
- `fetchCommunicationTemplates()` - Queries all `Communication_Template__c` records. Returns `Id` and `Name` fields, ordered by Name, limit 100
- `linkCommunicationTemplate(Id vendorProgramId, Id templateId)` - Updates a communication template to link it to a vendor program. Queries the template first, then updates the `Vendor_Program__c` field (lookup to `Vendor_Customization__c`)

**Onboarding Requirement Set Operations:**
- `insertOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - Inserts a requirement set record and returns the new record ID
- `fetchOnboardingRequirementSets()` - Queries all `Onboarding_Requirement_Set__c` records. Returns `Id`, `Name`, and `Status__c` fields, ordered by CreatedDate DESC, limit 100

**Onboarding Requirement Templates Operations:**
- `insertOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template)` - Inserts a requirement template record and returns the new record ID
- `fetchOnboardingRequirementTemplates(Id requirementSetId)` - Queries `Vendor_Program_Onboarding_Req_Template__c` records filtered by `Onboarding_Requirement_Set__c`. Returns `Id`, `Name`, and `Requirement_Type__c` fields
- `assignRequirementTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds)` - Updates multiple requirement templates to assign them to a requirement group. Queries templates by IDs, then updates the `Category_Group__c` field on each template

**Recipient Groups Operations:**
- `searchRecipientGroups(String recipientGroupName)` - Queries `Recipient_Group__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertRecipientGroup(Recipient_Group__c recipientGroup)` - Inserts a recipient group record and returns the new record ID
- `insertRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Inserts a recipient group member record and returns the new record ID

**Vendor Program Recipient Groups Operations:**
- `searchVendorProgramRecipientGroups(String vprgName)` - Queries `Vendor_Program_Recipient_Group__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - Creates and inserts a new `Vendor_Program_Recipient_Group__c` record linking a vendor program to a recipient group. Sets `Vendor_Program__c` (lookup to `Vendor_Customization__c`), `Recipient_Group__c`, and `Status__c = 'Draft'` on the new record

**Miscellaneous Operations:**
- `getTerritoryRoleAssignments()` - Queries all `Territory_Role_Assignment__c` records. Returns `Id`, `Name`, and `Role__c` fields, ordered by Name
- `getAssignableUsers()` - Queries all active `User` records (`IsActive = true`). Returns `Id` and `Name` fields, ordered by Name
- `getPublicGroups()` - Queries all `Group` records. Returns `Id` and `Name` fields, ordered by Name

**Usage:**
Used by `VendorOnboardingWizardService` for all data access operations. All methods use `with sharing` to enforce sharing rules.

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

**Location:** `force-app/main/default/classes/rules/OnboardingAppRuleRegistry.cls`

**Purpose:** Central registry of validation rules and activation rules for onboarding application objects.

**Key Methods:**
- `getValidationRules()` - Returns map of object API names to validation rule lists (for trigger-based validation)
- `getActivationRulesForObject(String objectApiName)` - Returns list of activation rules for a specific object (for activation-time validation)

**Validation Rules (Trigger-Based):**
- `Vendor_Program_Recipient_Group__c`:
  - `RequireParentVersionOnActivationRule` - Non-draft versions must have parent
  - `OnlyOneActiveRecGrpPerPrgrmRule` - Only one active version per parent
  - `RecipientAndProgramMustBeActiveRule` - Related records must be active
  - `PreventDupRecGrpAssignmentRule` - No duplicate assignments

**Activation Rules (Activation-Time):**
- `Vendor_Customization__c` (Vendor Program):
  - `AllRequirementGroupsMustBeActiveRule` - Requirement group must be active
- Legacy registry key `Vendor_Program__c`:
  - `AllChildRequirementsMustBeActiveRule` - All child requirements must be active
  - `AllTemplatesInReqSetMustBeActiveRule` - All requirement templates must be active
- `Onboarding_Status_Rule__c`:
  - `AllLinkedEngineMustBeActiveRule` - Parent rules engine must be active
- `Onboarding_Status_Rules_Engine__c`:
  - `AllStatusRulesMustBeActiveRule` - All child status rules must be active
  - `AllStatusRuleGroupMustBeActiveRule` - Related groups must be active

### OnboardingAppValidationRule

**Location:** `force-app/main/default/classes/OnboardingAppValidationRule.cls`

**Purpose:** Interface for validation rules that run on record save (via triggers).

**Key Methods:**
- `validate(List<SObject> newList, Map<Id, SObject> oldMap)` - Validates records before save

### OnboardingAppActivationRule

**Location:** `force-app/main/default/classes/rules/OnboardingAppActivationRule.cls`

**Purpose:** Interface for activation rules that run during activation (not on save).

**Key Methods:**
- `apply(Id recordId, String objectApiName)` - Executes activation rule logic, throws `AuraHandledException` if activation should be blocked

**Note:** Activation rules are separate from validation rules. They are executed by activation services before setting records to active status.

### Validation Rule Implementations (Trigger-Based)

- **RequireParentVersionOnActivationRule** - Requires parent version on activation
- **OnlyOneActiveRecGrpPerPrgrmRule** - Ensures only one active recipient group per program
- **RecipientAndProgramMustBeActiveRule** - Validates recipient and program are active
- **PreventDupRecGrpAssignmentRule** - Prevents duplicate recipient group assignments

### Activation Rule Implementations (Activation-Time)

- **AllChildRequirementsMustBeActiveRule** - Ensures all child requirements are active before activating vendor program
- **AllTemplatesInReqSetMustBeActiveRule** - Ensures all requirement templates are active
- **AllRequirementGroupsMustBeActiveRule** - Ensures requirement group is active before activating vendor customization
- **AllLinkedEngineMustBeActiveRule** - Ensures parent rules engine and requirement are active
- **AllStatusRulesMustBeActiveRule** - Ensures all child status rules are active before activating rules engine
- **AllStatusRuleGroupMustBeActiveRule** - Ensures related groups are active before activating rules engine
- **AllRequirementSetMustBeActiveRule** - Ensures requirement set is active (not currently registered)
- **AllTemplatesInGroupMustBeActiveRule** - Ensures all templates in group are active (not currently registered)

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

Repository classes follow the pattern `*Repo.cls` or `*Repository.cls` and handle data access operations:

- `OnboardingAppVendorProgramReqRepo` - Vendor program requirement data access
- `FollowUpRuleRepository` - Follow-up fatigue metadata and queue access
- `OnboardingMetricsRepository` - Admin dashboard metrics

### FollowUpRuleRepository

**Location:** `force-app/main/default/classes/repository/FollowUpRuleRepository.cls`

**Purpose:** Centralizes data access for fatigue suppression logic.

**Key Methods:**
- `getRuleByDeveloperName(developerName)` - Retrieves fatigue rule metadata.
- `getActiveSuppressions()` - Returns active suppression windows.
- `getRecentFollowUps(onboardingRequirementId, thresholdDateTime)` - Gets recent queue activity for fatigue checks.
- `getFollowUpQueue` / `getFollowUpQueueForTracking` - Loads queue records for suppression/attempt tracking flows.

### OnboardingMetricsRepository

**Location:** `force-app/main/default/classes/repository/OnboardingMetricsRepository.cls`

**Purpose:** Encapsulates dashboard metric queries and validation failure retrieval.

**Key Methods:**
- `getValidationFailureCount`, `getMessageFailureCount`, `getWebhookFailureCount`, `getPlatformEventVolume`, `getActiveFollowUpQueueCount`, `getOverrideOperationCount`
- `getValidationFailures(startDate, filters)` - Returns validation failures with optional type filtering.

### OnboardingRepository

**Location:** `force-app/main/default/classes/repository/OnboardingRepository.cls`

**Purpose:** Repository layer for Onboarding__c data access operations. Centralizes all SOQL queries for onboarding records.

**Key Methods:**
- `getActiveOnboardingWithFilters(ownerUserIds, startDate, vendorIds, programIds, limitCount)` - Returns active onboarding with filters
  - Uses pre-resolved Account IDs from `OnboardingAccessService` to avoid nested subqueries
  - Supports time, vendor, program, and ownership filters
  - Returns `List<Onboarding__c>`

- `getOnboardingSummaryWithFilters(ownerUserIds, startDate, vendorIds, programIds)` - Returns status counts with filters
  - Aggregate query grouped by Onboarding_Status__c
  - Returns `Map<String, Integer>` with status counts

- `getRecentOnboardingWithFilters(ownerUserIds, startDate, vendorIds, programIds, limitCount)` - Returns recent onboarding with filters
  - Uses LastModifiedDate for time filtering
  - Returns `List<Onboarding__c>`

- `getActiveOnboardingByCreatedBy(userId, limitCount)` - Legacy method for backward compatibility
- `getAllActiveOnboarding(limitCount)` - Returns all active onboarding (no ownership filter)
- `getRecentOnboardingByCreatedBy(userId, limitCount)` - Legacy method for backward compatibility
- `getOnboardingSummaryByCreatedBy(userId)` - Legacy method for backward compatibility
- `fetchOnboardingById(onboardingId)` - Fetches single onboarding record
- `fetchOnboardingsByIds(onboardingIds)` - Bulk fetch by IDs
- `updateOnboardings(onboardings)` - Updates onboarding records

**Design Decisions:**
- **Pre-resolved Account IDs:** Methods accept `Set<Id> accountIds` instead of building subqueries to avoid SOQL limitations
- **Filter Support:** All new methods support comprehensive filtering (time, vendor, program, ownership)
- **Early Returns:** Returns empty results when ownership filter is applied but no accounts match (avoids invalid SOQL)

**Dependencies:**
- `OnboardingAccessService` - For ownership resolution (called by controller, not repository)

**Usage:**
Used by `OnboardingHomeDashboardController` for all onboarding data access. Repository methods are called with pre-resolved Account IDs to avoid nested subquery issues.

### OnboardingAppECCRepository

**Location:** `force-app/main/default/classes/OnboardingAppECCRepository.cls`

**Purpose:** Repository for External Contact Credential (ECC) data access operations. Handles database queries and DML for required credentials and credential types.

**Key Methods:**
- `fetchRequiredCredentials(Id vendorProgramId)` - Queries required credentials for a vendor program with credential type relationship
- `fetchCredentialTypes()` - Queries all credential types (ordered by Name ASC)
- `insertCredentialType(String name)` - Inserts a new credential type record
- `updateRequiredCredential(Id requiredCredentialId, Id credentialTypeId)` - Updates a required credential with credential type link

**Usage:**
Used by `OnboardingAppECCService` for all ECC data access operations.

## DTOs (Data Transfer Objects)

DTO classes in `dto/` package provide structured data transfer:

- Various DTO classes for data transfer between layers

## Domain-Specific Services

The Vendor Onboarding Wizard service layer has been refactored into domain-specific services following the Single Responsibility Principle. Each service handles operations for a specific domain.

### VendorService

**Location:** `force-app/main/default/classes/services/VendorService.cls`

**Purpose:** Service for Vendor domain operations.

**Key Methods:**
- `searchVendors(String vendorName)` - Searches vendors by name
- `createVendor(Vendor__c vendor)` - Creates vendor with validation and default values
- `getVendorsWithPrograms()` - Gets all vendors with associated programs
- `searchVendorsWithPrograms(String searchText)` - Searches vendors with programs

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### VendorProgramService

**Location:** `force-app/main/default/classes/services/VendorProgramService.cls`

**Purpose:** Service for Vendor Program domain operations.

**Key Methods:**
- `searchVendorPrograms(String vendorProgramName)` - Searches vendor programs
- `getRecentVendorPrograms(Integer limitCount)` - Gets recent vendor programs
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates vendor program
- `getVendorProgramGroupForVendorProgram(Id vendorProgramId)` - Gets program group
- `getVendorProgramRequirementGroupForVendorProgram(Id vendorProgramId)` - Gets requirement group
- `finalizeVendorProgram(Id vendorProgramId, Id vendorId, Id vendorProgramGroupId, Id vendorProgramRequirementGroupId)` - Finalizes vendor program setup

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### VendorProgramGroupService

**Location:** `force-app/main/default/classes/services/VendorProgramGroupService.cls`

**Purpose:** Service for Vendor Program Group domain operations.

**Key Methods:**
- `searchVendorProgramGroups(String vendorProgramGroupName)` - Searches program groups
- `getAllVendorProgramGroups()` - Gets all program groups
- `createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup)` - Creates program group
- `getDefaultLogicType()` - Gets default Logic_Type__c value

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation

### VendorProgramRequirementGroupService

**Location:** `force-app/main/default/classes/services/VendorProgramRequirementGroupService.cls`

**Purpose:** Service for Vendor Program Requirement Group domain operations.

**Key Methods:**
- `searchVendorProgramRequirementGroups(String requirementGroupName)` - Searches requirement groups
- `getAllVendorProgramRequirementGroups()` - Gets all requirement groups
- `createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup)` - Creates requirement group

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### VendorProgramRequirementService

**Location:** `force-app/main/default/classes/services/VendorProgramRequirementService.cls`

**Purpose:** Service for Vendor Program Requirement domain operations.

**Key Methods:**
- `searchVendorProgramRequirements(String requirementName)` - Searches requirements
- `createVendorProgramRequirement(Vendor_Program_Requirement__c requirement)` - Creates requirement
- `bulkCreateRequirementsFromTemplates(List<Id> templateIds, Id vendorProgramId)` - Bulk creates requirements from templates
- `updateRequirementSequences(List<Vendor_Program_Requirement__c> requirements)` - Updates requirement sequences
- `getRecentVendorProgramRequirements(Id vendorProgramId)` - Gets recent requirements
- `getRequirementsByGroup(Id requirementGroupId)` - Gets requirements by group
- `getTemplatesByGroup(Id requirementGroupId)` - Gets templates by group
- `deleteVendorProgramRequirement(Id requirementId)` - Deletes requirement

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation

### OnboardingRequirementSetService

**Location:** `force-app/main/default/classes/services/OnboardingRequirementSetService.cls`

**Purpose:** Service for Onboarding Requirement Set and Template domain operations.

**Key Methods:**
- `createOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - Creates requirement set
- `getOnboardingRequirementSets()` - Gets all requirement sets
- `searchOnboardingRequirementSets(String searchText, Id vendorProgramId)` - Searches requirement sets
- `getRequirementSetsWithTemplates()` - Gets requirement sets with templates
- `searchRequirementSetsWithTemplates(String searchText)` - Searches requirement sets with templates
- `linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)` - Links requirement set to vendor program
- `createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId, String vendorProgramLabel)` - Creates requirement set from existing
- `getTemplatesForRequirementSet(Id requirementSetId)` - Gets templates for requirement set
- `createRequirementFromTemplate(Id templateId, Id vendorProgramId)` - Creates requirement from template
- `getHistoricalGroupMembers(Id requirementSetId)` - Gets historical group members
- `getHistoricalStatusRulesEngines(Id requirementSetId)` - Gets historical status rules engines
- `createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical)` - Creates requirement group components
- `createOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template)` - Creates requirement template
- `getRequirementTemplatesForSet(Id requirementSetId)` - Gets templates for requirement set
- `updateRequirementTemplateGroupLinks(Id requirementGroupId, List<Id> templateIds)` - Updates template group links
- `getRequirementSetById(Id requirementSetId)` - Gets requirement set by ID
- `getOnboardingContext(Id vendorProgramId)` - Gets onboarding context
- `assignTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds)` - Assigns templates to requirement group

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### RecipientGroupService

**Location:** `force-app/main/default/classes/services/RecipientGroupService.cls`

**Purpose:** Service for Recipient Group domain operations.

**Key Methods:**
- `searchRecipientGroups(String recipientGroupName)` - Searches recipient groups
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates recipient group
- `createRecipientGroupMember(Recipient_Group_Member__c member)` - Creates recipient group member
- `searchVendorProgramRecipientGroups(String vprgName)` - Searches vendor program recipient groups
- `createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - Creates vendor program recipient group link
- `getRecipientGroupsForVendorProgram(Id vendorProgramId)` - Gets recipient groups for vendor program
- `getRecipientGroupMembers(Id recipientGroupId)` - Gets recipient group members
- `createVendorProgramRecipientGroupWithTemplate(Id vendorProgramId, Id recipientGroupId, Id communicationTemplateId, String triggerCondition)` - Creates recipient group with template

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### StatusRulesEngineService

**Location:** `force-app/main/default/classes/services/StatusRulesEngineService.cls`

**Purpose:** Service for Status Rules Engine and Status Rule domain operations.

**Key Methods:**
- `searchStatusRulesEngines(String nameSearchText)` - Searches status rules engines
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c rulesEngine)` - Creates status rules engine
- `createStatusRule(Onboarding_Status_Rule__c rule)` - Creates status rule
- `searchStatusRules(String nameSearchText)` - Searches status rules

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### CommunicationTemplateService

**Location:** `force-app/main/default/classes/services/CommunicationTemplateService.cls`

**Purpose:** Service for Communication Template domain operations.

**Key Methods:**
- `getCommunicationTemplates()` - Gets all communication templates
- `linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId)` - Links template to vendor program

**Dependencies:**
- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation

## Utilities

### ValidationHelper

**Location:** `force-app/main/default/classes/util/ValidationHelper.cls`

**Purpose:** Centralized validation utility class. Provides static methods for input validation across services and orchestrators.

**Key Methods:**
- `requireNotNull(Object value, String fieldName)` - Validates value is not null
- `requireNotBlank(String value, String fieldName)` - Validates string is not blank
- `requireNotEmpty(List<Object> value, String fieldName)` - Validates list is not empty
- `requireId(Id recordId, String fieldName)` - Validates ID is not null
- `requireRecord(SObject record, String recordName)` - Validates record is not null
- `requireField(Object value, String fieldName)` - Validates field value is not null/blank
- `requireFieldForObject(Object value, String objectName, String fieldName)` - Validates field with object context

**Usage:** Used by all service classes and orchestrators for consistent input validation.

### DefaultValueHelper

**Location:** `force-app/main/default/classes/util/DefaultValueHelper.cls`

**Purpose:** Centralized default value assignment utility class. Provides static methods to apply default values to various SObject records.

**Key Methods:**
- `applyRequirementGroupDefaults(Vendor_Program_Requirement_Group__c group)` - Applies defaults to requirement groups
- `applyVendorProgramDefaults(Vendor_Customization__c vendorProgram)` - Applies defaults to vendor programs
- `applyVendorDefaults(Vendor__c vendor)` - Applies defaults to vendors
- `applyRecipientGroupDefaults(Recipient_Group__c recipientGroup)` - Applies defaults to recipient groups
- `applyStatusRulesEngineDefaults(Onboarding_Status_Rules_Engine__c rulesEngine)` - Applies defaults to status rules engines
- `applyTrainingSystemDefaults(Training_System__c trainingSystem)` - Applies defaults to training systems
- `applyRequirementSetDefaults(Onboarding_Requirement_Set__c requirementSet)` - Applies defaults to requirement sets

**Usage:** Used by service classes to ensure consistent default values across the system.

### PicklistHelper

**Location:** `force-app/main/default/classes/util/PicklistHelper.cls`

**Purpose:** Utility class for retrieving picklist values. Eliminates code duplication and provides consistent picklist handling.

**Key Methods:**
- `getPicklistValues(String objectApiName, String fieldApiName)` - Gets picklist values using schema describe
- `getPicklistValuesWithFallback(String objectApiName, String fieldApiName, List<String> fallbackValues)` - Gets picklist values with fallback
- `getPicklistValuesByField(Schema.SObjectField fieldToken, List<String> fallbackValues)` - Gets picklist values using direct field token (faster)

**Usage:** Used by `VendorOnboardingWizardController` for all picklist value retrieval methods.

### StageCompletionConfig

**Location:** `force-app/main/default/classes/util/StageCompletionConfig.cls`

**Purpose:** Configuration for stage completion logic. Centralizes component name checks to follow Open/Closed Principle.

**Key Methods:**
- `isVendorSelectionComponent(String componentApiName)` - Checks if component represents vendor selection stage
- `getVendorSelectionComponents()` - Gets all vendor selection component names

**Usage:** Used by `OnboardingApplicationService` to determine which stages should be auto-completed.

### FLSCheckUtil

**Location:** `force-app/main/default/classes/util/FLSCheckUtil.cls`

**Purpose:** Bulk-safe field-level security checks (`isReadable`, `isUpdateable`, `isCreateable`).

### CustomMetadataUtil

**Location:** `force-app/main/default/classes/util/CustomMetadataUtil.cls`

**Purpose:** Cached custom metadata lookup by DeveloperName with `clearCache` helper.

### LoggingUtil

**Location:** `force-app/main/default/classes/util/LoggingUtil.cls`

**Purpose:** Centralized logging helpers with consistent `[Onboarding]` prefix.

### OnboardingTestDataFactory

**Location:** `force-app/main/default/classes/util/OnboardingTestDataFactory.cls`

**Purpose:** Opinionated factory for onboarding test contexts (account, vendor, program, onboarding, requirement, requirement field).

### VendorProgramStatusMapper

**Location:** `force-app/main/default/classes/util/VendorProgramStatusMapper.cls`

**Purpose:** Maps Vendor Program technical statuses to user-friendly stages for display in the front end.

**⚠️ IMPORTANT**: This mapper is ONLY for `Vendor_Customization__c.Status__c` (Vendor Onboarding).
It does NOT apply to `Onboarding__c.Onboarding_Status__c` (Dealer Onboarding), which should be displayed as-is without simplification.

**Key Methods:**
- `getUserFacingStage(String technicalStatus, Boolean isAdmin)` - Maps technical status to user-friendly stage
- `getUserFacingStageForCurrentUser(String technicalStatus)` - Gets user-facing stage for current user (checks admin status automatically)
- `getStatusVariant(String userFacingStage)` - Gets CSS variant for status badge (brand, warning, success)
- `getStatusIcon(String userFacingStage)` - Gets Lightning icon name for status
- `isCurrentUserAdmin()` - Checks if current user is an admin

**Status Mapping:**
- **Draft/In Process** → "In Progress" 🟡
- **Pending Review/Pending Approval** → "Review Pending" 🟠
- **Complete/Approved** → "Completed" 🟢

**Admin Behavior:**
- Admin users see technical statuses unchanged
- End users see simplified stages

**Usage:**
Used by `OnboardingApplicationService.getUserFacingStage()` for Vendor Program status display in LWC components.

**Note:** Dealer Onboarding statuses (`Onboarding__c.Onboarding_Status__c`) are passed through `OnboardingDTO` and displayed as-is without any simplification.

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
├── strategies/ # Strategy pattern implementations
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

## Stage Dependency Classes

### OnboardingStageDependencyRepository

**Location:** `force-app/main/default/classes/repository/OnboardingStageDependencyRepository.cls`

**Purpose:** Repository layer for Onboarding Stage Dependency queries and data access.

**Key Methods:**
- `getDependenciesForTargetStage(Id targetStageId)` - Gets all dependency rules for a target stage with their members
- `getDependenciesForTargetStages(Set<Id> targetStageIds)` - Bulk query for multiple target stages
- `getCompletedStageIds(Id vendorProgramId, Id processId)` - Gets set of completed stage IDs for a vendor program
- `getDependencyById(Id dependencyId)` - Gets a dependency rule by ID with its members

**Dependencies:**
- `Onboarding_Application_Stage_Dependency__c` - Dependency rule object
- `Onboarding_App_Stage_Dependency_Member__c` - Dependency member object
- `Onboarding_Application_Stage_Completion__c` - Stage completion tracking

**Usage:** Used by `OnboardingStageDependencyService` for dependency queries.

### OnboardingStageDependencyService

**Location:** `force-app/main/default/classes/services/OnboardingStageDependencyService.cls`

**Purpose:** Service layer for Onboarding Stage Dependency validation. Checks if stages can be started based on dependency rules.

**Key Methods:**
- `canStartStage(Id targetStageId, Id vendorProgramId, Id processId)` - Validates if a stage can be started, returns `StageDependencyValidationDTO`
- `getDependencyInfo(Id targetStageId, Id vendorProgramId, Id processId)` - Gets dependency information for display purposes
- `evaluateDependency(String logicType, List<Id> requiredStageIds, Set<Id> completedStageIds)` - Private method that evaluates dependencies based on logic type (ALL, ANY, CUSTOM)

**DTOs:**
- `StageDependencyValidationDTO` - Contains `canStart` flag and list of blocking dependencies
- `DependencyInfo` - Contains dependency details including required, completed, and missing stage IDs

**Logic Types Supported:**
- `ALL` - All required stages must be completed
- `ANY` - At least one required stage must be completed
- `CUSTOM` - Custom logic (defaults to ALL for safety, not yet fully implemented)

**Dependencies:**
- `OnboardingStageDependencyRepository` - For dependency queries
- `Onboarding_Application_Stage_Dependency__c` - Dependency rule object
- `Onboarding_App_Stage_Dependency_Member__c` - Dependency member object

**Usage:** Used by `OnboardingApplicationService.saveProgress()` to validate dependencies before allowing stage progression.

### OnboardingApplicationService Updates

**New Methods:**
- `canStartStage(Id targetStageId, Id vendorProgramId, Id processId)` - Exposes dependency validation to LWC components
- `getStageDependencies(Id targetStageId, Id vendorProgramId, Id processId)` - Gets dependency information for display

**Updated Methods:**
- `saveProgress()` - Now validates dependencies before saving progress. Throws `AuraHandledException` if dependencies are not met.

**Integration:** The `onboardingFlowEngine` LWC component calls `canStartStage()` before allowing navigation to the next stage.

## Related Documentation

- [LWC Components](./lwc-components.md)
- [API Reference](../api/apex-api.md)
- [Architecture Overview](../architecture/overview.md)
- [Apex Patterns](../architecture/apex-patterns.md) - Architectural patterns and conventions
- [Pattern Violations](../reports/architecture/pattern-violations.md) - Identified violations and fixes (historical report)
- [Stage Dependency Management](../processes/stage-dependency-management.md) - **NEW** - Complete guide to stage dependencies
