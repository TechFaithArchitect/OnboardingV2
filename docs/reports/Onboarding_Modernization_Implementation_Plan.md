# Onboarding Modernization Implementation Plan

## Overview

This plan implements the complete Onboarding Modernization system across 5 phases over 19 weeks. The plan includes foundational infrastructure, field-level validation, automated follow-ups, Adobe integration, and external system overrides.

## Phase 0: Foundation & Infrastructure (Weeks 0-4)

### 0.1: Object Relationship & Security Hardening

**Task 0.1.1: Convert Requirement_Field_Value__c Relationship**
- Convert `Onboarding_Requirement__c` lookup to Master-Detail on `Requirement_Field_Value__c`
- Update any code referencing the relationship
- Test cascade delete behavior
- **Files**: `force-app/unpackaged/objects/Requirement_Field_Value__c.object`, related Apex classes

**Task 0.1.2: Set Organization-Wide Defaults**
- Set OWD to Private for `Requirement_Field_Value__c`
- Set OWD to Private for `Follow_Up_Queue__c`
- Set OWD to Public Read Only for `Requirement_Field__c` and `Requirement_Field_Group__c`
- **Files**: Object metadata files

**Task 0.1.3: Create Criteria-Based Sharing Rules**
- Create sharing rule for `Requirement_Field_Value__c` (Experience Cloud users)
- Create sharing rule for `Follow_Up_Queue__c` (Experience Cloud users)
- Test sharing with Experience Cloud user profiles
- **Files**: Sharing rule metadata

**Task 0.1.4: Document Sharing Model**
- Create `docs/architecture/sharing-model.md`
- Document OWD settings and rationale
- Document sharing rule definitions
- Document testing procedures

### 0.2: Admin Tools & Validation Testing

**Task 0.2.1: Create Onboarding Admin Lightning App**
- Create Lightning App "Onboarding Admin"
- Create tabs: Dashboard, Validation Failures, Messaging Issues, Adobe Sync Failures, Configuration, Testing, Override Audit
- Configure app navigation and utility items
- **Files**: `force-app/main/default/appMenus/Onboarding_Admin.appMenu-meta.xml`

**Task 0.2.2: Build Validation Failures Tab Component**
- Create `validationFailuresTab` LWC component
- Display `Validation_Failure__c` records with grouping options
- Implement quick actions: Retry Validation, View Details, Dismiss
- Add bulk actions and export functionality
- **Files**: `force-app/main/default/lwc/validationFailuresTab/`

**Task 0.2.3: Build Messaging Issues Tab Component**
- Create `messagingIssuesTab` LWC component
- Display failed follow-up queues with `MessagingDelivery` status
- Implement quick actions: Retry Send, Send Manual SMS, View Session
- Build Follow-Up Fatigue Dashboard sub-component
- **Files**: `force-app/main/default/lwc/messagingIssuesTab/`

**Task 0.2.4: Build Adobe Sync Failures Tab Component**
- Create `adobeSyncFailuresTab` LWC component
- Display `AdobeSyncFailure__c` records with filters
- Implement quick actions: Retry Sync, View Staging Data, Dismiss
- Add bulk retry functionality
- **Files**: `force-app/main/default/lwc/adobeSyncFailuresTab/`

**Task 0.2.5: Build Admin Dashboard Component**
- Create `onboardingAdminDashboard` LWC component
- Display real-time metrics (validation failures, message failures, webhook failures, Platform Event volume)
- Implement color-coded alerts and drill-down navigation
- **Files**: `force-app/main/default/lwc/onboardingAdminDashboard/`

**Task 0.2.6: Build Validation Rule Test Tool**
- Create `validationRuleTester` LWC component
- Create `ValidationRuleTesterController.cls` Apex controller
- Implement rule selection, test value input, and result display
- Add test case save/load functionality
- **Files**: `force-app/main/default/lwc/validationRuleTester/`, `force-app/main/default/classes/controllers/ValidationRuleTesterController.cls`

**Task 0.2.7: Add Validation Mode to Metadata**
- Add `Validation_Mode__c` picklist field to `Requirement_Field_Validation_Rule__mdt`
- Update `RequirementFieldValidationService.cls` to respect validation mode
- Create custom permission `Onboarding_Test_Mode` for test mode access
- **Files**: Custom metadata type definition, `force-app/main/default/classes/services/RequirementFieldValidationService.cls`

### 0.3: Enhanced Follow-Up Fatigue Logic

**Task 0.3.1: Add Fatigue Fields to Follow_Up_Queue__c**
- Add `Consecutive_Failures__c` (Number) field
- Add `Fatigue_Suppressed__c` (Checkbox) field
- Add `Suppression_Reason__c` (Text) field
- **Files**: `force-app/unpackaged/objects/Follow_Up_Queue__c.object`

**Task 0.3.2: Implement Fatigue Suppression Logic**
- Update `FollowUpDetectionService.cls` with `shouldSuppressDueToFatigue()` method
- Add fatigue check in follow-up creation flow
- Implement attempt counting and window calculation
- **Files**: `force-app/main/default/classes/services/FollowUpDetectionService.cls`

**Task 0.3.3: Enhance Follow_Up_Rule__mdt**
- Add `Max_Attempts_Per_Window__c` (Number) field
- Add `Fatigue_Window_Days__c` (Number) field
- Add `Fatigue_Suppression_Enabled__c` (Checkbox) field
- **Files**: Custom metadata type definition

**Task 0.3.4: Enhance Follow_Up_Suppression__mdt**
- Add `Suppression_Type__c` (Picklist) field
- Add `Fatigue_Rule_Reference__c` (Lookup) field
- Add `Timezone_Aware__c` (Checkbox) field
- **Files**: Custom metadata type definition

**Task 0.3.5: Implement Timezone-Aware Suppression**
- Add `Timezone__c` field to `Account` object
- Update `FollowUpExecutionService.cls` with timezone conversion logic
- Test DST transitions and timezone conversions
- **Files**: `force-app/unpackaged/objects/Account.object`, `force-app/main/default/classes/services/FollowUpExecutionService.cls`

### 0.4: Partial Save & Resume Strategy

**Task 0.4.1: Add Draft Status to Onboarding_Requirement__c**
- Add `Draft` and `Partially_Completed` values to `Status__c` picklist
- Update status flow documentation
- **Files**: `force-app/unpackaged/objects/Onboarding_Requirement__c.object`

**Task 0.4.2: Build Auto-Save Component**
- Create `requirementFieldAutoSave` LWC component
- Implement auto-save every 30 seconds (configurable)
- Implement save on field blur and component unmount
- Add save indicators (Saving..., Saved)
- **Files**: `force-app/main/default/lwc/requirementFieldAutoSave/`

**Task 0.4.3: Create Auto-Save Apex Controller**
- Create `RequirementFieldValueController.cls` with `saveFieldValue()` method
- Implement upsert logic for `Requirement_Field_Value__c`
- Update `Onboarding_Requirement__c.Status__c` to Draft/Partially_Completed
- **Files**: `force-app/main/default/classes/controllers/RequirementFieldValueController.cls`

**Task 0.4.4: Build Resume Panel Component**
- Create `onboardingResumePanel` LWC component
- Display incomplete onboarding records with progress indicators
- Implement "Resume" button navigation
- Pre-fill fields from existing values
- **Files**: `force-app/main/default/lwc/onboardingResumePanel/`

**Task 0.4.5: Create Resume Context Service**
- Add `getResumeContext()` method to `OnboardingApplicationService.cls`
- Calculate completion percentage
- Find last completed and next incomplete requirements
- **Files**: `force-app/main/default/classes/services/OnboardingApplicationService.cls`

**Task 0.4.6: Build Draft Cleanup Batch Job**
- Create `OnboardingCleanupScheduler.cls` batch class
- Implement query for abandoned records (Draft/Partially_Completed, 30+ days old)
- Add soft delete pattern with `Is_Archived__c` field
- Create follow-up tasks for Onboarding Reps
- **Files**: `force-app/main/default/classes/batch/OnboardingCleanupScheduler.cls`

**Task 0.4.7: Add Soft Delete Fields**
- Add `Is_Archived__c` (Checkbox) to `Onboarding_Requirement__c`
- Add `Is_Archived__c` to `Requirement_Field_Value__c`
- Add `Is_Archived__c` to `Follow_Up_Queue__c`
- Add `Is_Archived__c` to `Form_Data_Staging__c`
- **Files**: Object metadata files

### 0.5: Metadata Authoring Tools

**Task 0.5.1: Build Validation Rule Builder Component**
- Create `validationRuleBuilder` LWC component
- Implement rule configuration form (name, type, expression, error message)
- Build expression builder with regex tester and field reference picker
- Add test-before-save functionality
- **Files**: `force-app/main/default/lwc/validationRuleBuilder/`

**Task 0.5.2: Create Validation Rule Metadata Service**
- Create `ValidationRuleMetadataService.cls` Apex class
- Implement `createValidationRule()` method (Metadata API or proxy pattern)
- Implement `updateValidationRule()` method
- Implement `validateExpression()` method for syntax checking
- **Files**: `force-app/main/default/classes/services/ValidationRuleMetadataService.cls`

**Task 0.5.3: Build Form Mapping Builder Wizard**
- Create `formMappingBuilder` LWC component (5-step wizard)
- Step 1: Form type selection
- Step 2: Field mapping interface (drag-and-drop or click-to-map)
- Step 3: Transformation configuration
- Step 4: Test mapping with sample JSON
- Step 5: Save and activate mapping
- **Files**: `force-app/main/default/lwc/formMappingBuilder/`

**Task 0.5.4: Create Form Mapping Builder Controller**
- Create `FormMappingBuilderController.cls` Apex class
- Implement `getAdobeFields()` method
- Implement `getSalesforceFields()` method
- Implement `testMapping()` method
- Implement `saveMappingRules()` method
- **Files**: `force-app/main/default/classes/controllers/FormMappingBuilderController.cls`

**Task 0.5.5: Build Rule Test Harness Component**
- Create `ruleTestHarness` LWC component (enhanced validation rule tester)
- Implement test suite management (create, save, load test suites)
- Build test case builder with expected results
- Add batch testing (multiple rules or multiple test cases)
- **Files**: `force-app/main/default/lwc/ruleTestHarness/`

**Task 0.5.6: Create Rule Test Harness Service**
- Create `RuleTestHarnessService.cls` Apex class
- Implement `runTestCase()` method
- Implement `runTestSuite()` method
- Implement `saveTestCase()` method
- **Files**: `force-app/main/default/classes/services/RuleTestHarnessService.cls`

### 0.6: Enhanced Cleanup & Retry Automation

**Task 0.6.1: Create Follow-Up Retry Flow**
- Create `Follow_Up_Retry_Flow` record-triggered flow
- Trigger on `Follow_Up_Queue__c` where `Status__c = 'Failed'`
- Implement exponential backoff calculation
- Set `Status__c = 'Pending Retry'` and `Next_Attempt_Date__c`
- **Files**: `force-app/unpackaged/flows/Follow_Up_Retry_Flow.flow`

**Task 0.6.2: Create Follow-Up Retry Platform Event**
- Create `FollowUpRetryTrigger__e` Platform Event
- Add `Follow_Up_Queue_Id__c` field
- **Files**: `force-app/main/default/objects/FollowUpRetryTrigger__e/`

**Task 0.6.3: Build Follow-Up Retry Handler**
- Create `FollowUpRetryHandler.cls` Platform Event subscriber
- Implement `handleRetry()` method
- Call `FollowUpExecutionService.retryFailedFollowUps()`
- **Files**: `force-app/main/default/classes/handlers/FollowUpRetryHandler.cls`

**Task 0.6.4: Enhance FollowUpExecutionService with Retry Logic**
- Add `retryFailedFollowUps()` method to `FollowUpExecutionService.cls`
- Implement retry logic with error handling
- Update attempt counts and status
- **Files**: `force-app/main/default/classes/services/FollowUpExecutionService.cls`

**Task 0.6.5: Create Webhook Retry Queue Object**
- Create `Webhook_Retry__c` custom object (optional, or enhance `AdobeSyncFailure__c`)
- Add fields: `Form_Data_Staging__c`, `Retry_Count__c`, `Next_Retry_Date__c`, `Status__c`, `Payload__c`
- **Files**: `force-app/unpackaged/objects/Webhook_Retry__c.object`

**Task 0.6.6: Build Webhook Retry Scheduler**
- Create `WebhookRetryScheduler.cls` batch class
- Query pending retry records
- Re-process webhooks with exponential backoff
- Update retry status and counts
- **Files**: `force-app/main/default/classes/batch/WebhookRetryScheduler.cls`

**Task 0.6.7: Add Retry Status Fields to Failure Objects**
- Add retry fields to `Validation_Failure__c`: `Retry_Count__c`, `Last_Retry_Date__c`, `Next_Retry_Date__c`, `Retry_Status__c`
- Verify retry fields exist on `Follow_Up_Queue__c` and `AdobeSyncFailure__c`
- **Files**: Object metadata files

### 0.7: Developer Utility Layer

**Task 0.7.1: Enhance FLSCheckUtil**
- Create/enhance `FLSCheckUtil.cls` with bulk-safe methods
- Add `checkFieldAccessBulk()` method with caching
- Add `canCreate()`, `canDelete()` methods
- Add `filterAccessibleFields()` method
- **Files**: `force-app/main/default/classes/util/FLSCheckUtil.cls`

**Task 0.7.2: Create TestDataFactory**
- Create `OnboardingTestDataFactory.cls` test utility class
- Implement `createOnboardingWithRequirements()` method
- Implement `createTestValidationRule()` method
- Implement `createFollowUpQueue()` method
- Implement `loadSampleMetadata()` method
- **Files**: `force-app/main/default/classes/test/OnboardingTestDataFactory.cls`

**Task 0.7.3: Create CustomMetadataUtil**
- Create `CustomMetadataUtil.cls` utility class
- Implement caching for validation rules
- Implement caching for follow-up rules
- Add `clearCache()` method
- **Files**: `force-app/main/default/classes/util/CustomMetadataUtil.cls`

**Task 0.7.4: Create LoggingUtil**
- Create `LoggingUtil.cls` utility class
- Implement `logError()` method (logs to custom Error_Log__c)
- Implement `logPlatformEventFailure()` method
- Implement `logValidationFailure()` method
- **Files**: `force-app/main/default/classes/util/LoggingUtil.cls`

**Task 0.7.5: Create Error Log Objects**
- Create `Error_Log__c` custom object for centralized logging
- Create `EventFailure__c` custom object for Platform Event failures
- **Files**: `force-app/unpackaged/objects/Error_Log__c.object`, `force-app/unpackaged/objects/EventFailure__c.object`

## Phase 1: Field-Level Validation & Correction Workflow (Weeks 5-9)

### 1.1: Data Model Creation

**Task 1.1.1: Create Requirement_Field__c Object**
- Create custom object with Master-Detail to `Vendor_Program_Requirement__c`
- Add fields: `Field_Type__c`, `Field_API_Name__c`, `Required__c`, `Validation_Type__c`, `Sequence__c`, `Help_Text__c`
- **Files**: `force-app/unpackaged/objects/Requirement_Field__c.object`

**Task 1.1.2: Create Requirement_Field_Value__c Object**
- Create custom object with Master-Detail to `Onboarding_Requirement__c`
- Add fields: `Requirement_Field__c`, `Value__c`, `Encrypted_Value__c`, `Validation_Status__c`, `Validation_Error_Message__c`, etc.
- Configure Shield Platform Encryption for `Encrypted_Value__c`
- **Files**: `force-app/unpackaged/objects/Requirement_Field_Value__c.object`

**Task 1.1.3: Create Requirement_Field_Group__c Object**
- Create custom object with Master-Detail to `Vendor_Program_Requirement__c`
- Add fields: `Sequence__c`, `Description__c`
- **Files**: `force-app/unpackaged/objects/Requirement_Field_Group__c.object`

**Task 1.1.4: Create Requirement_Field_Validation_Rule__mdt**
- Create custom metadata type
- Add fields: `Validation_Type__c`, `Validation_Expression__c`, `Error_Message__c`, `External_Service__c`, `Active__c`, `Validation_Mode__c`
- **Files**: Custom metadata type definition

### 1.2: Validation Service Implementation

**Task 1.2.1: Create RequirementFieldValidationService**
- Create `RequirementFieldValidationService.cls` Apex class
- Implement format validation logic
- Implement cross-field validation logic
- Implement external validation (Fortza) integration
- **Files**: `force-app/main/default/classes/services/RequirementFieldValidationService.cls`

**Task 1.2.2: Create RequirementValidationPlatformEventHandler**
- Create `RequirementValidationPlatformEventHandler.cls` Platform Event subscriber
- Subscribe to `RequirementValidationEvent__e`
- Call validation service and update field values
- **Files**: `force-app/main/default/classes/handlers/RequirementValidationPlatformEventHandler.cls`

**Task 1.2.3: Create RequirementValidationEvent Platform Event**
- Create `RequirementValidationEvent__e` Platform Event
- Add fields: `Requirement_Field_Value_Id__c`, `Field_Values__c` (JSON)
- **Files**: `force-app/main/default/objects/RequirementValidationEvent__e/`

**Task 1.2.4: Create RequirementValidationQueueable**
- Create `RequirementValidationQueueable.cls` Queueable class for high-volume fallback
- Implement batch validation processing
- Add retry logic with exponential backoff
- **Files**: `force-app/main/default/classes/queueable/RequirementValidationQueueable.cls`

**Task 1.2.5: Create FortzaValidationService**
- Create `FortzaValidationService.cls` for fraud/identity checks
- Explore Fortza API capabilities
- Implement API integration with error handling
- **Files**: `force-app/main/default/classes/services/FortzaValidationService.cls`

### 1.3: UI Components

**Task 1.3.1: Build requirementValidationPanel Component**
- Create `requirementValidationPanel` LWC component
- Display field-level validation status
- Show inline error messages
- Implement correction workflow UI
- **Files**: `force-app/main/default/lwc/requirementValidationPanel/`

**Task 1.3.2: Create RequirementCorrectionService**
- Create `RequirementCorrectionService.cls` Apex class
- Implement send-back-for-correction workflow
- Update requirement status and field values
- **Files**: `force-app/main/default/classes/services/RequirementCorrectionService.cls`

**Task 1.3.3: Update Wizard Components**
- Update onboarding wizard components to support field-level correction
- Add validation status indicators
- Implement field-level error display
- **Files**: Wizard component files in `force-app/main/default/lwc/`

### 1.4: Repository Layer

**Task 1.4.1: Create RequirementFieldRepository**
- Create `RequirementFieldRepository.cls` Apex class
- Implement data access methods for `Requirement_Field__c`
- Implement data access methods for `Requirement_Field_Value__c`
- **Files**: `force-app/main/default/classes/repository/RequirementFieldRepository.cls`

## Phase 2: Automated Follow-Up System (Weeks 10-13)

### 2.1: Data Model

**Task 2.1.1: Create Follow_Up_Queue__c Object**
- Create custom object with all required fields (already enhanced in Phase 0.3)
- Add lookup to `Onboarding_Requirement__c` and `Onboarding__c`
- Add messaging session and delivery lookups
- **Files**: `force-app/unpackaged/objects/Follow_Up_Queue__c.object`

**Task 2.1.2: Create Follow_Up_Rule__mdt**
- Create custom metadata type (already enhanced in Phase 0.3)
- Add escalation schedule JSON field
- Add messaging template and channel references
- **Files**: Custom metadata type definition

**Task 2.1.3: Create Follow_Up_Suppression__mdt**
- Create custom metadata type (already enhanced in Phase 0.3)
- Add suppression type and timezone awareness
- **Files**: Custom metadata type definition

### 2.2: Detection & Execution Services

**Task 2.2.1: Create FollowUpDetectionService**
- Create `FollowUpDetectionService.cls` Apex class
- Implement detection logic for stalled onboarding
- Check fatigue suppression (from Phase 0.3)
- Create follow-up queue records
- **Files**: `force-app/main/default/classes/services/FollowUpDetectionService.cls`

**Task 2.2.2: Create FollowUpExecutionService**
- Create/enhance `FollowUpExecutionService.cls` (already started in Phase 0.6)
- Implement SMS sending via Salesforce Messaging API
- Implement email sending
- Implement in-app notification creation
- **Files**: `force-app/main/default/classes/services/FollowUpExecutionService.cls`

**Task 2.2.3: Create FollowUpMessagingService**
- Create `FollowUpMessagingService.cls` Apex class
- Implement `sendSMS()` method using Salesforce Messaging API
- Implement `findOrCreateSession()` method
- Link to `MessagingSession` and `MessagingDelivery` objects
- **Files**: `force-app/main/default/classes/services/FollowUpMessagingService.cls`

**Task 2.2.4: Create FollowUpTrigger Platform Event**
- Create `FollowUpTrigger__e` Platform Event
- Add fields for follow-up queue ID and trigger reason
- **Files**: `force-app/main/default/objects/FollowUpTrigger__e/`

**Task 2.2.5: Build Follow-Up Escalation Flow**
- Create Flow for escalation orchestration
- Use `Follow_Up_Rule__mdt` for configuration
- Implement escalation schedule logic
- **Files**: `force-app/unpackaged/flows/Follow_Up_Escalation_Flow.flow`

### 2.3: Scheduler & Management UI

**Task 2.3.1: Create FollowUpScheduler**
- Create `FollowUpScheduler.cls` scheduled Apex class
- Query pending follow-ups
- Process follow-ups based on `Next_Attempt_Date__c`
- **Files**: `force-app/main/default/classes/schedulable/FollowUpScheduler.cls`

**Task 2.3.2: Build followUpQueueManager Component**
- Create `followUpQueueManager` LWC component for admin management
- Display follow-up queue records
- Allow manual retry and status updates
- **Files**: `force-app/main/default/lwc/followUpQueueManager/`

**Task 2.3.3: Build onboardingFollowUpQueue Dashboard**
- Create `onboardingFollowUpQueue` LWC dashboard component
- Display follow-up metrics and trends
- **Files**: `force-app/main/default/lwc/onboardingFollowUpQueue/`

## Phase 3: Adobe Integration (Weeks 14-16)

### 3.1: Data Model

**Task 3.1.1: Create Form_Data_Staging__c Object**
- Create custom object with all required fields
- Add lookups to `Onboarding__c` and `Onboarding_Requirement__c`
- Add Adobe document and template ID fields
- **Files**: `force-app/unpackaged/objects/Form_Data_Staging__c.object`

**Task 3.1.2: Create FormMappingRule__mdt**
- Create custom metadata type
- Add fields for Adobe field name, Salesforce field API name, mapping type, transform expression
- **Files**: Custom metadata type definition

**Task 3.1.3: Create AdobeSyncFailure__c Object**
- Create custom object (already has retry fields from Phase 0.6)
- Add lookup to `Form_Data_Staging__c`
- **Files**: `force-app/unpackaged/objects/AdobeSyncFailure__c.object`

### 3.2: REST API & Platform Event Bridge

**Task 3.2.1: Create AdobeWebhookHandler REST Endpoint**
- Create `AdobeWebhookHandler.cls` REST API class
- Implement `@HttpPost` method for webhook reception
- Validate webhook request
- Publish `AdobeWebhookEvent__e` Platform Event
- **Files**: `force-app/main/default/classes/api/AdobeWebhookHandler.cls`

**Task 3.2.2: Create AdobeWebhookEvent Platform Event**
- Create `AdobeWebhookEvent__e` Platform Event
- Add fields for webhook payload and staging record ID
- **Files**: `force-app/main/default/objects/AdobeWebhookEvent__e/`

**Task 3.2.3: Create AdobeWebhookEventHandler**
- Create `AdobeWebhookEventHandler.cls` Platform Event subscriber
- Process webhook events
- Update `Form_Data_Staging__c` records
- **Files**: `force-app/main/default/classes/handlers/AdobeWebhookEventHandler.cls`

### 3.3: Mapping & Sync Services

**Task 3.3.1: Create FormDataMappingService**
- Create `FormDataMappingService.cls` Apex class
- Implement mapping between Adobe and Salesforce fields
- Use `FormMappingRule__mdt` for configuration
- **Files**: `force-app/main/default/classes/services/FormDataMappingService.cls`

**Task 3.3.2: Create FormDataEncryptionService**
- Create `FormDataEncryptionService.cls` Apex class
- Implement encryption for sensitive data (SSN, etc.)
- Use Shield Platform Encryption
- **Files**: `force-app/main/default/classes/services/FormDataEncryptionService.cls`

**Task 3.3.3: Create FormDataSyncService**
- Create `FormDataSyncService.cls` Apex class
- Implement sync between Adobe and Salesforce
- Handle signature status updates
- **Files**: `force-app/main/default/classes/services/FormDataSyncService.cls`

**Task 3.3.4: Create AdobeFormDataAPI REST Endpoints**
- Create REST endpoints for Adobe to read/write form data
- Implement authentication via Named Credentials
- **Files**: `force-app/main/default/classes/api/AdobeFormDataAPI.cls`

## Phase 4: External System Override (Weeks 17-19)

### 4.1: Data Model

**Task 4.1.1: Add Override Fields to Onboarding__c**
- Add `External_Override_Enabled__c` (Checkbox)
- Add `External_Override_Reason__c` (Long Text Area)
- Add `External_Override_Date__c` (DateTime)
- Add `External_Override_Source__c` (Text)
- Add `External_Override_Programs__c` (Text)
- Add `Previous_Status_Before_Override__c` (Text)
- Add `External_Override_Request_ID__c` (Text)
- **Files**: `force-app/unpackaged/objects/Onboarding__c.object`

**Task 4.1.2: Create Onboarding_External_Override_Log__c Object**
- Create custom object for audit logging
- Add all required fields for override tracking
- **Files**: `force-app/unpackaged/objects/Onboarding_External_Override_Log__c.object`

### 4.2: REST API & Services

**Task 4.2.1: Create OnboardingExternalOverrideAPI REST Endpoint**
- Create `OnboardingExternalOverrideAPI.cls` REST API class
- Implement `@HttpPost` method
- Validate request and authenticate via Named Credential
- Call override service
- **Files**: `force-app/main/default/classes/api/OnboardingExternalOverrideAPI.cls`

**Task 4.2.2: Create OnboardingExternalOverrideService**
- Create `OnboardingExternalOverrideService.cls` Apex class
- Implement `applyOverride()` method
- Implement `removeOverride()` method
- Implement `isProgramAllowed()` method
- Implement `resetRequirementsForReOnboarding()` method
- **Files**: `force-app/main/default/classes/services/OnboardingExternalOverrideService.cls`

**Task 4.2.3: Create OnboardingOverrideAuditService**
- Create `OnboardingOverrideAuditService.cls` Apex class
- Log all override operations to audit object
- **Files**: `force-app/main/default/classes/services/OnboardingOverrideAuditService.cls`

### 4.3: Status Evaluator Updates

**Task 4.3.1: Update OnboardingStatusEvaluator**
- Modify `OnboardingStatusEvaluator.cls` to check override flags
- Skip rule evaluation if override enabled
- **Files**: `force-app/main/default/classes/services/OnboardingStatusEvaluator.cls`

**Task 4.3.2: Update Onboarding_Record_Trigger_Update_Onboarding_Status Flow**
- Add decision element to check `External_Override_Enabled__c`
- Skip rule evaluation if override is active
- **Files**: `force-app/unpackaged/flows/Onboarding_Record_Trigger_Update_Onboarding_Status.flow`

### 4.4: UI Updates

**Task 4.4.1: Update Vendor Program Selection UI**
- Filter vendor programs based on `External_Override_Programs__c`
- Hide/disable non-allowed programs
- Show clear error messages
- **Files**: Vendor program selection LWC components

**Task 4.4.2: Create Override Management UI**
- Create LWC component for viewing override status
- Display override reason and allowed programs
- Allow manual override removal (with permissions)
- **Files**: `force-app/main/default/lwc/onboardingOverridePanel/`

## Testing & Documentation

**Task TEST.1: Create Test Classes for Phase 0**
- Create test classes for all Phase 0 services and utilities
- Achieve 90%+ code coverage
- **Files**: Test classes in `force-app/main/default/classes/test/`

**Task TEST.2: Create Test Classes for Phase 1**
- Create test classes for validation services and repositories
- Test format, cross-field, and external validation
- **Files**: Test classes in `force-app/main/default/classes/test/`

**Task TEST.3: Create Test Classes for Phase 2**
- Create test classes for follow-up services and scheduler
- Mock Salesforce Messaging API calls
- **Files**: Test classes in `force-app/main/default/classes/test/`

**Task TEST.4: Create Test Classes for Phase 3**
- Create test classes for Adobe integration services
- Mock webhook calls and external service calls
- **Files**: Test classes in `force-app/main/default/classes/test/`

**Task TEST.5: Create Test Classes for Phase 4**
- Create test classes for override API and services
- Test override application and removal
- **Files**: Test classes in `force-app/main/default/classes/test/`

**Task DOC.1: Update Architecture Documentation**
- Update `docs/architecture/` files with new components
- Document sharing model
- Document new data model relationships
- **Files**: Documentation files in `docs/architecture/`

**Task DOC.2: Create Admin User Guide**
- Document how to use admin console
- Document validation rule builder
- Document form mapping builder
- **Files**: `docs/user-guides/admin-guide.md`

**Task DOC.3: Create API Documentation**
- Document REST API endpoints
- Document request/response formats
- Document authentication requirements
- **Files**: `docs/api/` directory

## Dependencies

- Phase 0 must be completed before Phase 1 (foundation is required)
- Phase 1 field-level structure is referenced in Phase 0.4 (partial save)
- Phase 2 depends on Phase 0.3 (follow-up fatigue logic)
- Phase 3 can be developed in parallel with Phase 2
- Phase 4 can be developed in parallel with Phase 3
- All phases require Phase 0.7 (developer utilities) for testing

## Success Criteria

- All object relationships converted to Master-Detail where appropriate
- Admin console functional with all tabs
- Validation rule builder allows non-developers to create rules
- Follow-up system prevents fatigue with intelligent suppression
- Partial save and resume working for incomplete onboarding
- Field-level validation working with correction workflow
- Automated follow-ups sending via Salesforce Messaging
- Adobe integration syncing form data bidirectionally
- External override API functional for Axapta integration
- 90%+ test coverage for all components
- All documentation updated and complete

