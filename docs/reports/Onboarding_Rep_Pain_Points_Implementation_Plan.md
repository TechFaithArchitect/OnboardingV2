# Onboarding Rep Pain Points - Implementation Plan

## Overview

This plan addresses three critical pain points identified by Onboarding Reps:

1. **Sub-step Decomposition & Validation** - Field-level validation and correction workflow
2. **Automated Follow-Up Queue** - Relentless automated follow-up with SMS integration
3. **Adobe Form Data Support** - Data structure to support Adobe managed package integration

## Business Context

### Problem 1: Sub-step Decomposition

- **Current State**: Requirements are all-or-nothing; one error requires restarting entire form
- **Desired State**: Highlight specific fields/sections, send back for correction, automatic validation
- **Key Question**: What could be wrong and how do we know? (Fortza integration exploration)

### Problem 2: Automated Follow-Up Queue

- **Current State**: Manual email/notes, no automated follow-up, 2-week delays common
- **Desired State**: Automated, relentless follow-up via in-app notifications and SMS (Twilio)
- **Timeline**: Not originally considered, but can be implemented

### Problem 3: Adobe Form Data Support

- **Current State**: Adobe managed package coming in Version 2 (all-or-nothing configuration)
- **Desired State**: Data structure ready to support Adobe pre-fill, PDF generation, signature injection
- **Note**: Adobe handles the UI/workflow; we need to provide data structure

---

## Phase 1: Sub-step Decomposition & Validation

### Architecture Overview

Extend the requirement model to support field-level granularity:

- `Onboarding_Requirement__c` → Parent requirement (existing)
- `Requirement_Field__c` → Individual fields within a requirement (NEW)
- `Requirement_Field_Value__c` → Captured values and validation status (NEW)
- `Requirement_Field_Validation_Rule__c` → Validation rules (NEW)

### Task 1.1: Create Requirement Field Data Model

**New Objects:**

#### Requirement_Field__c

**Purpose**: Defines individual fields within a requirement (e.g., "Legal Name", "Driver's License Number")

**Key Fields:**

- `Name` (Text) - Field name/label
- `Vendor_Program_Requirement__c` (Lookup) - Parent requirement definition
- `Field_Type__c` (Picklist) - Text, Number, Date, Email, Phone, SSN, etc.
- `Field_API_Name__c` (Text) - API name for mapping to form fields
- `Required__c` (Checkbox) - Whether field is required
- `Validation_Type__c` (Picklist) - None, Format, Cross-Field, External (Fortza)
- `Validation_Rule__c` (Long Text) - Validation expression or rule reference
- `Sequence__c` (Number) - Display order
- `Help_Text__c` (Text) - Help text for users

**Relationships:**

- Master-Detail to Vendor_Program_Requirement__c
- Has many Requirement_Field_Value__c

#### Requirement_Field_Value__c

**Purpose**: Stores captured values and validation status for each field

**Key Fields:**

- `Onboarding_Requirement__c` (Lookup) - Parent requirement instance
- `Requirement_Field__c` (Lookup) - Field definition
- `Value__c` (Text) - Captured value (encrypted for SSN)
- `Encrypted_Value__c` (Encrypted Text) - For sensitive data like SSN
- `Validation_Status__c` (Picklist) - Valid, Invalid, Pending, Needs_Correction
- `Validation_Error_Message__c` (Text) - Error message if invalid
- `Last_Validated_Date__c` (DateTime) - When validation last ran
- `Correction_Requested_Date__c` (DateTime) - When correction was requested
- `Correction_Reason__c` (Text) - Why correction is needed

**Relationships:**

- Master-Detail to Onboarding_Requirement__c
- Lookup to Requirement_Field__c

#### Requirement_Field_Validation_Rule__c (Custom Metadata)

**Purpose**: Defines validation rules that can be reused

**Key Fields:**

- `Name` (Text) - Rule name
- `Validation_Type__c` (Picklist) - Format, Cross-Field, External
- `Validation_Expression__c` (Text) - Expression or API endpoint
- `Error_Message__c` (Text) - Error message template
- `External_Service__c` (Picklist) - Fortza, Custom, etc.

**Dependencies**: None

### Task 1.2: Create Validation Service Layer

**File**: `force-app/main/default/classes/services/RequirementFieldValidationService.cls` (new)

**Purpose**: Centralized validation logic

**Methods:**

- `validateField(Id fieldValueId)` - Validates a single field value
- `validateRequirement(Id requirementId)` - Validates all fields in a requirement
- `validateFieldsBulk(List<Id> fieldValueIds)` - Bulk validation
- `getValidationErrors(Id requirementId)` - Returns all validation errors
- `requestFieldCorrection(Id fieldValueId, String reason)` - Marks field for correction

**Validation Types:**

1. **Format Validation**: Regex, length, pattern matching
2. **Cross-Field Validation**: Compare fields (e.g., legal name matches driver's license name)
3. **External Validation**: Call Fortza API or other external service

**Dependencies**: Task 1.1

### Task 1.3: Create Fortza Integration Service (Exploration)

**File**: `force-app/main/default/classes/services/FortzaValidationService.cls` (new)

**Purpose**: Integration with Fortza for fraud/validation checks

**Methods:**

- `validateIdentity(Id fieldValueId)` - Validate identity information
- `checkFraudFlags(Id onboardingId)` - Check for fraud flags
- `validateDocument(Id documentId)` - Validate uploaded documents

**Implementation Notes:**

- Use Named Credentials for API authentication
- Implement retry logic and error handling
- Cache results to avoid duplicate API calls
- Return structured validation results

**Dependencies**: Task 1.2

### Task 1.4: Create Requirement Field Repository

**File**: `force-app/main/default/classes/repository/RequirementFieldRepository.cls` (new)

**Purpose**: Data access for requirement fields

**Methods:**

- `getFieldsForRequirement(Id requirementId)` - Get all fields for a requirement
- `getFieldValuesForRequirement(Id requirementId)` - Get all field values
- `getFieldsNeedingCorrection(Id requirementId)` - Get fields marked for correction
- `upsertFieldValues(List<Requirement_Field_Value__c> values)` - Save field values

**Dependencies**: Task 1.1

### Task 1.5: Create "Send Back for Correction" Feature

**File**: `force-app/main/default/classes/services/RequirementCorrectionService.cls` (new)

**Purpose**: Handle correction workflow

**Methods:**

- `sendRequirementForCorrection(Id requirementId, List<Id> fieldValueIds, String reason)` - Send specific fields back
- `getCorrectionRequests(Id requirementId)` - Get all correction requests
- `markFieldCorrected(Id fieldValueId)` - Mark field as corrected
- `getFieldsPendingCorrection(Id onboardingId)` - Get all fields needing correction

**Workflow:**

1. Onboarding Rep identifies invalid field(s)
2. Calls `sendRequirementForCorrection` with specific field IDs
3. System marks fields as `Needs_Correction`
4. Dealer sees highlighted fields in wizard
5. Dealer corrects only those fields
6. System re-validates corrected fields
7. Onboarding Rep approves correction

**Dependencies**: Task 1.2, Task 1.4

### Task 1.6: Update Onboarding Requirements Panel

**File**: `force-app/main/default/lwc/onboardingRequirementsPanel/` (update)

**Changes:**

- Add field-level view (expandable requirement rows)
- Show validation status per field
- Add "Send Back for Correction" button with field selection
- Display correction requests and reasons
- Show validation errors inline

**New Component**: `requirementFieldCorrection` (new)

- Modal for selecting fields to send back
- Reason text area
- Preview of fields being sent back

**Dependencies**: Task 1.5

### Task 1.7: Update Wizard Components to Support Field-Level Correction

**Files**:

- `force-app/main/default/lwc/vendorProgramOnboardingRequirementSet/` (update)
- Flow engine components (update)

**Changes:**

- Highlight fields marked for correction
- Show validation errors inline
- Allow saving individual field corrections
- Auto-validate on field change
- Show correction reasons

**Dependencies**: Task 1.6

### Task 1.8: Create Test Classes

**Files:**

- `force-app/main/default/classes/test/RequirementFieldValidationServiceTest.cls` (new)
- `force-app/main/default/classes/test/FortzaValidationServiceTest.cls` (new)
- `force-app/main/default/classes/test/RequirementCorrectionServiceTest.cls` (new)
- `force-app/main/default/classes/test/RequirementFieldRepositoryTest.cls` (new)

**Coverage Requirements:**

- All validation types (format, cross-field, external)
- Correction workflow
- Error handling
- Bulk operations

**Dependencies**: All Phase 1 tasks

---

## Phase 2: Automated Follow-Up Queue

### Architecture Overview

Create a follow-up queue system that:

- Monitors requirement status changes
- Tracks follow-up attempts
- Escalates based on time thresholds
- Sends in-app notifications and SMS

### Task 2.1: Create Follow-Up Queue Data Model

**New Objects:**

#### Follow_Up_Queue__c

**Purpose**: Tracks pending follow-ups for requirements

**Key Fields:**

- `Name` (Auto-Number) - Follow-up number
- `Onboarding_Requirement__c` (Lookup) - Requirement needing follow-up
- `Onboarding__c` (Lookup) - Parent onboarding
- `Follow_Up_Type__c` (Picklist) - Email, SMS, In-App, Phone
- `Status__c` (Picklist) - Pending, Sent, Acknowledged, Escalated, Resolved
- `Priority__c` (Picklist) - Low, Medium, High, Critical
- `Trigger_Reason__c` (Text) - Why follow-up was triggered
- `Days_Since_Trigger__c` (Formula) - Days since follow-up was created
- `Last_Attempt_Date__c` (DateTime) - Last follow-up attempt
- `Attempt_Count__c` (Number) - Number of attempts
- `Next_Attempt_Date__c` (DateTime) - When to attempt next
- `Escalation_Level__c` (Number) - Current escalation level
- `Resolved_Date__c` (DateTime) - When follow-up was resolved

**Relationships:**

- Lookup to Onboarding__c
- Lookup to Onboarding_Requirement__c

#### Follow_Up_Rule__c (Custom Metadata)

**Purpose**: Defines when to trigger follow-ups

**Key Fields:**

- `Name` (Text) - Rule name
- `Trigger_Condition__c` (Text) - Condition expression
- `Follow_Up_Type__c` (Picklist) - Email, SMS, In-App
- `Initial_Delay_Days__c` (Number) - Days before first follow-up
- `Escalation_Schedule__c` (Text) - JSON array of escalation intervals
- `Max_Attempts__c` (Number) - Maximum attempts before escalation
- `Active__c` (Checkbox) - Whether rule is active

**Example Escalation Schedule:**

```json
[
  {"days": 3, "type": "Email"},
  {"days": 7, "type": "SMS"},
  {"days": 10, "type": "SMS"},
  {"days": 14, "type": "Phone"}
]
```

**Dependencies**: None

### Task 2.2: Create Follow-Up Detection Service

**File**: `force-app/main/default/classes/services/FollowUpDetectionService.cls` (new)

**Purpose**: Detects when follow-ups should be created

**Methods:**

- `detectFollowUpsForRequirement(Id requirementId)` - Check if requirement needs follow-up
- `detectFollowUpsForOnboarding(Id onboardingId)` - Check all requirements
- `evaluateFollowUpRules(Id requirementId)` - Evaluate all active rules
- `createFollowUpQueue(Id requirementId, Id ruleId)` - Create follow-up queue entry

**Trigger Conditions:**

- Requirement status changed to "In Process" but no activity for X days
- Background check started but not submitted for 2+ weeks
- Field marked for correction but not corrected after X days
- Requirement incomplete after deadline

**Dependencies**: Task 2.1

### Task 2.3: Create Follow-Up Execution Service

**File**: `force-app/main/default/classes/services/FollowUpExecutionService.cls` (new)

**Purpose**: Executes follow-up actions

**Methods:**

- `executeFollowUp(Id followUpQueueId)` - Execute a single follow-up
- `executePendingFollowUps()` - Execute all pending follow-ups (scheduled)
- `sendEmailFollowUp(Id followUpQueueId)` - Send email
- `sendSMSFollowUp(Id followUpQueueId)` - Send SMS via Twilio
- `sendInAppNotification(Id followUpQueueId)` - Send in-app notification
- `escalateFollowUp(Id followUpQueueId)` - Escalate to next level

**Dependencies**: Task 2.2, Task 2.4

### Task 2.4: Create Twilio SMS Integration Service

**File**: `force-app/main/default/classes/services/TwilioSMSService.cls` (new)

**Purpose**: Integration with Twilio for SMS notifications

**Methods:**

- `sendSMS(String phoneNumber, String message, Id followUpQueueId)` - Send SMS
- `sendSMSTemplate(String phoneNumber, String templateName, Map<String, String> variables)` - Send templated SMS
- `getSMSStatus(String messageSid)` - Check SMS delivery status
- `handleSMSResponse(String fromNumber, String messageBody)` - Handle incoming SMS (future)

**Implementation:**

- Use Named Credentials for Twilio API
- Implement retry logic
- Log SMS attempts to Follow_Up_Queue__c
- Support SMS templates with variable substitution

**Dependencies**: Task 2.1

### Task 2.5: Create Scheduled Follow-Up Job

**File**: `force-app/main/default/classes/schedulable/FollowUpScheduler.cls` (new)

**Purpose**: Scheduled job to process follow-up queue

**Implementation:**

- Runs every hour (or configurable interval)
- Queries `Follow_Up_Queue__c` where `Status__c = 'Pending'` and `Next_Attempt_Date__c <= NOW`
- Calls `FollowUpExecutionService.executePendingFollowUps()`
- Updates attempt counts and next attempt dates
- Escalates based on rules

**Dependencies**: Task 2.3

### Task 2.6: Create Follow-Up Queue Management UI

**File**: `force-app/main/default/lwc/followUpQueueManager/` (new)

**Purpose**: Admin UI to manage follow-up queue

**Features:**

- View all pending follow-ups
- Filter by type, status, priority
- Manually trigger follow-ups
- View follow-up history
- Configure escalation rules

**Dependencies**: Task 2.1

### Task 2.7: Create Follow-Up Dashboard Component

**File**: `force-app/main/default/lwc/onboardingFollowUpQueue/` (new)

**Purpose**: Dashboard component showing follow-ups needing attention

**Features:**

- List of requirements with pending follow-ups
- Days since last activity
- Next follow-up date
- Quick actions: Send Now, Escalate, Resolve

**Dependencies**: Task 2.6

### Task 2.8: Create Test Classes

**Files:**

- `force-app/main/default/classes/test/FollowUpDetectionServiceTest.cls` (new)
- `force-app/main/default/classes/test/FollowUpExecutionServiceTest.cls` (new)
- `force-app/main/default/classes/test/TwilioSMSServiceTest.cls` (new)
- `force-app/main/default/classes/test/FollowUpSchedulerTest.cls` (new)

**Coverage Requirements:**

- Follow-up detection logic
- SMS sending (mock Twilio)
- Escalation logic
- Scheduled job execution

**Dependencies**: All Phase 2 tasks

---

## Phase 3: Adobe Form Data Support

### Architecture Overview

Create data structure to support Adobe managed package:

- Staging object for form data
- API endpoints for Adobe to read/write
- Data mapping service
- Encryption support for sensitive fields

### Task 3.1: Create Form Data Staging Object

**New Object:**

#### Form_Data_Staging__c

**Purpose**: Staging area for form data that Adobe can read/write

**Key Fields:**

- `Name` (Auto-Number) - Form data record number
- `Onboarding__c` (Lookup) - Related onboarding
- `Onboarding_Requirement__c` (Lookup) - Related requirement
- `Form_Type__c` (Picklist) - Background Check, Credit Application, etc.
- `Form_Data_JSON__c` (Long Text Area) - JSON structure of form data
- `Status__c` (Picklist) - Draft, Submitted, Processing, Complete, Error
- `Adobe_Document_ID__c` (Text) - Adobe document reference
- `Adobe_Template_ID__c` (Text) - Adobe template reference
- `Pre_Fill_Data__c` (Long Text Area) - Pre-fill data for Adobe
- `Signature_Status__c` (Picklist) - Not Signed, Pending, Signed, Rejected
- `Signature_Date__c` (DateTime) - When signed
- `Last_Synced_Date__c` (DateTime) - Last sync with Adobe

**Relationships:**

- Lookup to Onboarding__c
- Lookup to Onboarding_Requirement__c

**Note**: This object serves as the bridge between Salesforce and Adobe. Adobe managed package will read/write to this object.

**Dependencies**: None

### Task 3.2: Create Form Data Mapping Service

**File**: `force-app/main/default/classes/services/FormDataMappingService.cls` (new)

**Purpose**: Maps between Salesforce data and Adobe form structure

**Methods:**

- `getPreFillDataForRequirement(Id requirementId)` - Get pre-fill data from Requirement_Field_Value__c
- `mapFormDataToFields(Id formDataStagingId)` - Map Adobe form data back to Requirement_Field_Value__c
- `generatePreFillJSON(Id requirementId)` - Generate JSON for Adobe pre-fill
- `validateFormDataStructure(String formDataJSON)` - Validate JSON structure

**Data Mapping:**

- Requirement_Field_Value__c → Adobe form fields (via Field_API_Name__c)
- Handles encryption/decryption for sensitive fields
- Supports nested structures for complex forms

**Dependencies**: Task 3.1, Phase 1 (Requirement_Field_Value__c)

### Task 3.3: Create Adobe Integration API Endpoints

**File**: `force-app/main/default/classes/rest/AdobeFormDataAPI.cls` (new)

**Purpose**: REST API endpoints for Adobe to call

**Endpoints:**

- `GET /services/apexrest/AdobeFormData/PreFill/{requirementId}` - Get pre-fill data
- `POST /services/apexrest/AdobeFormData/Submit` - Submit form data from Adobe
- `GET /services/apexrest/AdobeFormData/Status/{formDataId}` - Get form status
- `POST /services/apexrest/AdobeFormData/Signature` - Update signature status

**Authentication:**

- Use Named Credentials or API key
- Validate Adobe requests

**Dependencies**: Task 3.2

### Task 3.4: Create Form Data Encryption Service

**File**: `force-app/main/default/classes/services/FormDataEncryptionService.cls` (new)

**Purpose**: Encrypt/decrypt sensitive form data (SSN, etc.)

**Methods:**

- `encryptFieldValue(String value, String fieldType)` - Encrypt sensitive value
- `decryptFieldValue(String encryptedValue)` - Decrypt value
- `maskFieldValue(String value, String fieldType)` - Mask for display (e.g., SSN: ***-**-1234)

**Implementation:**

- Use Salesforce Shield Platform Encryption or custom encryption
- Support field-level encryption
- Audit encryption/decryption events

**Dependencies**: Task 3.1

### Task 3.5: Create Form Data Sync Service

**File**: `force-app/main/default/classes/services/FormDataSyncService.cls` (new)

**Purpose**: Syncs form data between Adobe and Salesforce

**Methods:**

- `syncFormDataFromAdobe(Id formDataStagingId)` - Sync data from Adobe
- `syncPreFillDataToAdobe(Id requirementId)` - Send pre-fill data to Adobe
- `handleAdobeWebhook(String webhookPayload)` - Handle Adobe webhooks

**Dependencies**: Task 3.2, Task 3.3

### Task 3.6: Create Test Classes

**Files:**

- `force-app/main/default/classes/test/FormDataMappingServiceTest.cls` (new)
- `force-app/main/default/classes/test/AdobeFormDataAPITest.cls` (new)
- `force-app/main/default/classes/test/FormDataEncryptionServiceTest.cls` (new)
- `force-app/main/default/classes/test/FormDataSyncServiceTest.cls` (new)

**Coverage Requirements:**

- Data mapping logic
- API endpoint security
- Encryption/decryption
- Webhook handling

**Dependencies**: All Phase 3 tasks

---

## Implementation Timeline

### Week 1-2: Phase 1 Foundation

- Task 1.1: Data model
- Task 1.2: Validation service
- Task 1.4: Repository

### Week 3-4: Phase 1 Completion

- Task 1.3: Fortza exploration (parallel with 1.5)
- Task 1.5: Correction service
- Task 1.6: UI updates
- Task 1.7: Wizard updates

### Week 5: Phase 1 Testing

- Task 1.8: Test classes

### Week 6-7: Phase 2 Foundation

- Task 2.1: Follow-up data model
- Task 2.2: Detection service
- Task 2.3: Execution service
- Task 2.4: Twilio integration

### Week 8: Phase 2 Completion

- Task 2.5: Scheduled job
- Task 2.6: Management UI
- Task 2.7: Dashboard component

### Week 9: Phase 2 Testing

- Task 2.8: Test classes

### Week 10-11: Phase 3 (Parallel with Adobe Configuration)

- Task 3.1: Staging object
- Task 3.2: Mapping service
- Task 3.3: API endpoints
- Task 3.4: Encryption service

### Week 12: Phase 3 Completion & Testing

- Task 3.5: Sync service
- Task 3.6: Test classes

---

## Key Considerations

### Security

- Encrypt sensitive data (SSN, etc.) at rest and in transit
- Use Named Credentials for external API calls
- Implement field-level security for form data
- Audit all data access

### Performance

- Bulk operations for validation and follow-ups
- Cache validation rules and follow-up rules
- Async processing for external API calls (Fortza, Twilio)
- Index key fields for query performance

### Scalability

- Design for high volume of follow-ups
- Queue-based processing for SMS/email
- Batch processing for scheduled jobs
- Consider Platform Events for real-time updates

### Integration Points

- **Fortza**: Explore API capabilities, fraud detection endpoints
- **Twilio**: SMS sending, delivery status, webhooks
- **Adobe**: Form data read/write, signature status, webhooks

### Configuration

- Use Custom Metadata for validation rules and follow-up rules
- Make rules configurable without code changes
- Support rule versioning

---

## Success Criteria

### Phase 1: Sub-step Decomposition

- Field-level validation working
- "Send back for correction" workflow functional
- Automatic validation on field change
- Fortza integration explored (if feasible)
- 90%+ test coverage

### Phase 2: Follow-Up Queue

- Automated follow-up detection working
- SMS integration functional
- Escalation logic working
- Scheduled job processing queue
- 90%+ test coverage

### Phase 3: Adobe Support

- Form data staging object ready
- API endpoints functional
- Encryption working
- Data mapping service complete
- Ready for Adobe configuration

---

## Open Questions / Exploration Items

1. **Fortza Integration**:

   - What APIs does Fortza provide?
   - What validation/fraud checks are available?
   - What is the authentication model?
   - What is the cost/rate limit structure?

2. **Twilio Configuration**:

   - What is the Twilio account setup?
   - What phone numbers are available?
   - What are the SMS template requirements?
   - What is the opt-in/opt-out process?

3. **Adobe Integration**:

   - What is the exact Adobe managed package name?
   - What are the API requirements?
   - What is the data structure expected?
   - What is the signature workflow?

4. **Validation Rules**:

   - What are the most common validation errors?
   - What cross-field validations are needed?
   - What external validations are required?

