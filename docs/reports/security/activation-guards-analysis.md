# Activation Guards Analysis and Recommendations

This document identifies all Apex classes responsible for guarding against setting records to active status and provides recommendations for their use and improvement.

## Overview

The system uses multiple layers of protection to prevent invalid record activations:

1. **Activation Services** - Control the activation process
2. **Validation Rules** - Prevent invalid states via triggers
3. **Versioning Handlers** - Enforce versioning constraints
4. **Orchestrators** - Coordinate activation workflows

---

## Activation Guard Classes

### 1. OnboardingAppActivationService

**Location:** `force-app/main/default/classes/services/OnboardingAppActivationService.cls`

**Purpose:** Generic activation service that handles activation for any object type with versioning support.

**Guards Implemented:**
- ✅ Prevents re-activation (checks if `Status__c == 'Active'`)
- ✅ Deactivates sibling versions when activating a new version
- ✅ Supports both `Active__c` and legacy `Is_Active__c` fields
- ✅ Handles versioning via `Previous_Version__c` field

**Key Logic:**
```apex
// Prevents re-activation
if (status == 'Active') {
    throw new AuraHandledException('Record is already active.');
}

// Deactivates siblings
if (parentVersionId != null) {
    // Query and deactivate all active siblings
}
```

**Issues & Recommendations:**

1. **✅ FIXED: Activation Rule Integration**
   - **Status:** Now calls `OnboardingAppRuleRegistry.getActivationRulesForObject()` before activation
   - **Implementation:** Lines 12-17 execute activation rules before proceeding with activation
   - **Note:** Uses new `OnboardingAppActivationRule` interface (different from validation rules)

2. **⚠️ Dynamic SOQL Injection Risk**
   - **Issue:** Uses string concatenation for SOQL queries
   - **Risk:** Potential SOQL injection if `objectApiName` is not properly validated
   - **Recommendation:** Add validation:
   ```apex
   // Validate object name against allowed list
   Set<String> allowedObjects = new Set<String>{'Vendor_Customization__c', 'Communication_Template__c'};
   if (!allowedObjects.contains(objectApiName)) {
       throw new AuraHandledException('Invalid object type for activation.');
   }
   ```

3. **⚠️ Incomplete Error Handling**
   - **Issue:** Generic error messages don't indicate which validation failed
   - **Recommendation:** Capture and return specific validation errors

4. **✅ Good:** Handles both field naming conventions (`Active__c` vs `Is_Active__c`)

---

### 2. VendorProgramActivationService

**Location:** `force-app/main/default/classes/services/VendorProgramActivationService.cls`

**Purpose:** Specialized activation service for `Vendor_Customization__c` records.

**Guards Implemented:**
- ✅ Prevents re-activation (checks `Status__c == 'Active'`)
- ✅ Deactivates sibling versions
- ✅ Has placeholder for vendor-specific post-activation logic

**Key Logic:**
```apex
if (record.Status__c == 'Active') {
    throw new AuraHandledException('Program is already active.');
}
deactivateSiblings(record);
```

**Issues & Recommendations:**

1. **⚠️ Missing Activation Rules**
   - **Issue:** Does NOT call activation rules from `OnboardingAppRuleRegistry.getActivationRulesForObject()`
   - **Risk:** Can bypass activation rules that are registered for `Vendor_Customization__c` (e.g., `AllRequirementGroupsMustBeActiveRule`)
   - **Recommendation:** Add activation rule execution before activation:
   ```apex
   // Before activation, execute activation rules
   List<OnboardingAppActivationRule> rules = 
       OnboardingAppRuleRegistry.getActivationRulesForObject('Vendor_Customization__c');
   for (OnboardingAppActivationRule rule : rules) {
       rule.apply(recordId, 'Vendor_Customization__c');
   }
   ```
   - **Note:** Should be added before `deactivateSiblings()` call

2. **⚠️ Empty Post-Activation Hook**
   - **Issue:** `postActivate()` method is empty
   - **Recommendation:** Document what should go here or remove if not needed:
   ```apex
   private static void postActivate(Vendor_Customization__c record) {
       // TODO: Implement vendor-specific post-activation logic
       // Examples:
       // - Create related records
       // - Send notifications
       // - Update related objects
   }
   ```

3. **✅ Good:** Type-specific implementation allows for vendor-specific business logic

---

### 3. OnboardingAppActivationOrchestrator

**Location:** `force-app/main/default/classes/orchestrators/OnboardingAppActivationOrchestrator.cls`

**Purpose:** Routes activation requests to appropriate service based on object type.

**Guards Implemented:**
- ✅ Input validation (checks for null/blank parameters)
- ✅ Routes to specialized service for `Vendor_Customization__c`
- ✅ Falls back to generic service for other objects

**Key Logic:**
```apex
switch on objectApiName {
    when 'Vendor_Customization__c' {
        VendorProgramActivationService.activate(recordId);
    }
    when else {
        OnboardingAppActivationService.activateRecord(objectApiName, recordId);
    }
}
```

**Issues & Recommendations:**

1. **✅ PARTIALLY FIXED: Activation Rule Execution**
   - **Status:** `OnboardingAppActivationService.activateRecord()` now executes activation rules (lines 12-17)
   - **Issue:** `VendorProgramActivationService.activate()` still does NOT execute activation rules
   - **Recommendation:** Update `VendorProgramActivationService` to call activation rules, OR update orchestrator to execute rules before calling services:
   ```apex
   public static void activate(Id recordId, String objectApiName) {
       // Validate input
       if (String.isBlank(objectApiName) || recordId == null) {
           throw new AuraHandledException('Object API Name and Record Id are required.');
       }
       
       // Execute activation rules BEFORE calling service
       List<OnboardingAppActivationRule> rules = 
           OnboardingAppRuleRegistry.getActivationRulesForObject(objectApiName);
       for (OnboardingAppActivationRule rule : rules) {
           rule.apply(recordId, objectApiName);
       }
       
       // Then proceed with activation
       switch on objectApiName {
           // ...
       }
   }
   ```

2. **⚠️ Commented-Out Code**
   - **Issue:** Has commented code for `CommunicationTemplateActivationRules.afterActivation(recordId)`
   - **Recommendation:** Either implement or remove commented code

3. **✅ Good:** Clean separation of concerns with routing logic

---

### 4. OnboardingAppRuleRegistry

**Location:** `force-app/main/default/classes/OnboardingAppRuleRegistry.cls`

**Purpose:** Central registry of validation rules by object type.

**Guards Implemented:**
- ✅ Registers validation rules for `Vendor_Program_Recipient_Group__c`
- ✅ Provides extensible pattern for adding rules to other objects

**Current Validation Rules Registered (via `getValidationRules()`):**
- `RequireParentVersionOnActivationRule` - For `Vendor_Program_Recipient_Group__c`
- `OnlyOneActiveRecGrpPerPrgrmRule` - For `Vendor_Program_Recipient_Group__c`
- `RecipientAndProgramMustBeActiveRule` - For `Vendor_Program_Recipient_Group__c`
- `PreventDupRecGrpAssignmentRule` - For `Vendor_Program_Recipient_Group__c`

**✅ NEW: Activation Rules Registry (via `getActivationRulesForObject()`):**

**For `Vendor_Program__c`:**
- `AllChildRequirementsMustBeActiveRule` - Ensures all child requirements are active
- `AllTemplatesInReqSetMustBeActiveRule` - Ensures all requirement templates are active

**For `Vendor_Customization__c`:**
- `AllRequirementGroupsMustBeActiveRule` - Ensures requirement group is active

**For `Onboarding_Status_Rule__c`:**
- `AllLinkedEngineMustBeActiveRule` - Ensures parent rules engine is active

**For `Onboarding_Status_Rules_Engine__c`:**
- `AllStatusRulesMustBeActiveRule` - Ensures all child status rules are active
- `AllStatusRuleGroupMustBeActiveRule` - Ensures related groups are active

**Issues & Recommendations:**

1. **✅ IMPROVED: Expanded Object Coverage**
   - **Status:** Now has activation rules for multiple objects via `getActivationRulesForObject()`
   - **Note:** Activation rules are separate from validation rules - they run during activation, not on save

2. **⚠️ No Documentation**
   - **Issue:** Registry doesn't document what each rule does
   - **Recommendation:** Add inline documentation:
   ```apex
   // Vendor Program Recipient Group Rules
   // - RequireParentVersionOnActivationRule: Non-draft versions must have parent
   // - OnlyOneActiveRecGrpPerPrgrmRule: Only one active version per parent
   // - RecipientAndProgramMustBeActiveRule: Related records must be active
   // - PreventDupRecGrpAssignmentRule: No duplicate assignments
   ```

3. **✅ Good:** Clean registry pattern makes it easy to add new rules

---

## New Activation Rules (OnboardingAppActivationRule Interface)

The following rules implement the `OnboardingAppActivationRule` interface and are executed during activation (not on save). They throw `AuraHandledException` if activation should be blocked.

### AllChildRequirementsMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/AllChildRequirementsMustBeActiveRule.cls`

**Purpose:** Ensures all child `Vendor_Program_Requirement__c` records are active before activating a `Vendor_Program__c`.

**Guards Implemented:**
- ✅ Queries all requirements for the vendor program
- ✅ Validates each requirement has `Active__c = true`
- ✅ Throws exception if any requirement is inactive

**Registered For:** `Vendor_Program__c`

**Key Logic:**
```apex
List<Vendor_Program_Requirement__c> requirements = [
    SELECT Id, Active__c
    FROM Vendor_Program_Requirement__c
    WHERE Vendor_Program__c = :recordId
];
for (Vendor_Program_Requirement__c req : requirements) {
    if (!req.Active__c) {
        throw new AuraHandledException('Cannot activate Vendor Program because not all Requirements are active.');
    }
}
```

**Issues & Recommendations:**
- **✅ Good:** Clear error message
- **⚠️ Performance:** Queries all requirements - consider bulkification if called multiple times
- **⚠️ Edge Case:** What if there are no requirements? Should that be allowed?

---

### AllTemplatesInReqSetMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/AllTemplatesInReqSetMustBeActiveRule.cls`

**Purpose:** Ensures all requirement templates referenced by vendor program requirements are active.

**Guards Implemented:**
- ✅ Queries all `Vendor_Program_Requirement__c` records for the vendor program
- ✅ Checks `Requirement_Template__r.Active__c` for each requirement
- ✅ Throws exception with template name if any template is inactive

**Registered For:** `Vendor_Program__c`

**Key Logic:**
```apex
List<Vendor_Program_Requirement__c> programRequirements = [
    SELECT Requirement_Template__r.Active__c, Requirement_Template__r.Name
    FROM Vendor_Program_Requirement__c
    WHERE Vendor_Program__c = :recordId
];
for (Vendor_Program_Requirement__c inst : programRequirements) {
    if (inst.Requirement_Template__r != null && !inst.Requirement_Template__r.Active__c) {
        throw new AuraHandledException('Cannot activate Vendor Program because requirement template ' + inst.Requirement_Template__r.Name + ' is not active.');
    }
}
```

**Issues & Recommendations:**
- **✅ Good:** Handles null templates gracefully
- **✅ Good:** Includes template name in error message
- **⚠️ Note:** This rule and `AllChildRequirementsMustBeActiveRule` both check requirements - consider if both are needed

---

### AllRequirementGroupsMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/AllRequirementGroupsMustBeActiveRule.cls`

**Purpose:** Ensures the requirement group linked to a vendor program is active before activation.

**Guards Implemented:**
- ✅ Queries vendor program to get `Vendor_Program_Requirement_Group__c`
- ✅ Validates the requirement group has `Active__c = true`
- ✅ Returns early if no requirement group is linked

**Registered For:** `Vendor_Customization__c`

**Key Logic:**
```apex
Vendor_Customization__c vendorProgram = [
    SELECT Vendor_Program_Requirement_Group__c
    FROM Vendor_Customization__c
    WHERE Id = :recordId
];
Vendor_Program_Requirement_Group__c group = [
    SELECT Active__c
    FROM Vendor_Program_Requirement_Group__c
    WHERE Id = :vendorProgram.Vendor_Program_Requirement_Group__c
];
if (!group.Active__c) {
    throw new AuraHandledException('Cannot activate Vendor Program because its Requirement Group is not active.');
}
```

**Issues & Recommendations:**

1. **⚠️ CRITICAL BUG: Wrong Method Signature**
   - **Issue:** Method signature is `apply(String objectApiName, Id recordId)` but interface requires `apply(Id recordId, String objectApiName)`
   - **Risk:** Will cause `MethodNotFoundException` at runtime
   - **Fix:** Change to `public void apply(Id recordId, String objectApiName)`

2. **⚠️ Null Safety**
   - **Issue:** Doesn't check if `Vendor_Program_Requirement_Group__c` query returns null
   - **Recommendation:** Add null check:
   ```apex
   if (vendorProgram.Vendor_Program_Requirement_Group__c == null) return;
   Vendor_Program_Requirement_Group__c group = [SELECT Active__c FROM ...];
   if (group == null || !group.Active__c) {
       throw new AuraHandledException(...);
   }
   ```

---

### AllLinkedEngineMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/AllLinkedEngineMustBeActiveRule.cls`

**Purpose:** Ensures the parent rules engine and requirement are active before activating a status rule.

**Guards Implemented:**
- ✅ Queries `Onboarding_Status_Rule__c` with parent and requirement relationships
- ✅ Validates both `Parent_Rule__r.Active__c` and `Requirement__r.Active__c`
- ✅ Throws exception if either is inactive

**Registered For:** `Onboarding_Status_Rule__c`

**Key Logic:**
```apex
Onboarding_Status_Rule__c rule = [
    SELECT Parent_Rule__r.Active__c, Requirement__r.Active__c
    FROM Onboarding_Status_Rule__c
    WHERE Id = :recordId
];
if (!rule.Parent_Rule__r.Active__c || !rule.Requirement__r.Active__c) {
    throw new AuraHandledException('Cannot activate Status Rule because its parent Rules Engine is not active.');
}
```

**Issues & Recommendations:**
- **⚠️ Null Safety:** Doesn't check if relationships return null
- **⚠️ Error Message:** Only mentions parent engine, but also checks requirement
- **Recommendation:** Update error message or split into two checks

---

### AllStatusRulesMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/AllStatusRulesMustBeActiveRule.cls`

**Purpose:** Ensures all child status rules are active before activating a rules engine.

**Guards Implemented:**
- ✅ Queries all `Onboarding_Status_Rule__c` records where `Parent_Rule__c = recordId`
- ✅ Validates each rule has `Active__c = true`
- ✅ Throws exception if any rule is inactive

**Registered For:** `Onboarding_Status_Rules_Engine__c`

**Key Logic:**
```apex
List<Onboarding_Status_Rule__c> rules = [
    SELECT Id, Active__c
    FROM Onboarding_Status_Rule__c
    WHERE Parent_Rule__c = :recordId
];
for (Onboarding_Status_Rule__c rule : rules) {
    if (!rule.Active__c) {
        throw new AuraHandledException('Cannot activate Rules Engine unless all Status Rules are active.');
    }
}
```

**Issues & Recommendations:**
- **✅ Good:** Clear error message
- **⚠️ Edge Case:** What if there are no child rules? Should that be allowed?

---

### AllStatusRuleGroupMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/AllStatusRuleGroupMustBeActiveRule.cls`

**Purpose:** Ensures both related groups (Requirement Group and Vendor Program Group) are active before activating a rules engine.

**Guards Implemented:**
- ✅ Queries `Onboarding_Status_Rules_Engine__c` with group relationships
- ✅ Validates both `Requirement_Group__r.Active__c` and `Vendor_Program_Group__r.Active__c`
- ✅ Throws exception if either is inactive

**Registered For:** `Onboarding_Status_Rules_Engine__c`

**Key Logic:**
```apex
Onboarding_Status_Rules_Engine__c engine = [
    SELECT Requirement_Group__r.Active__c, Vendor_Program_Group__r.Active__c
    FROM Onboarding_Status_Rules_Engine__c
    WHERE Id = :recordId
];
if (!engine.Requirement_Group__r.Active__c || !engine.Vendor_Program_Group__r.Active__c) {
    throw new AuraHandledException('Cannot activate Rules Engine because one or both related groups are not active.');
}
```

**Issues & Recommendations:**
- **⚠️ Null Safety:** Doesn't check if relationships return null
- **✅ Good:** Error message mentions "one or both" which is accurate

---

### AllRequirementSetMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/AllRequirementSetMustBeActiveRule.cls`

**Purpose:** Ensures the requirement set is active before activating a requirement template.

**Guards Implemented:**
- ✅ Queries `Vendor_Program_Onboarding_Req_Template__c` with requirement set relationship
- ✅ Validates `Onboarding_Requirement_Set__r.Active__c`
- ✅ Throws exception if requirement set is inactive

**Registered For:** `Vendor_Program_Onboarding_Req_Template__c` (not currently in registry, but rule exists)

**Key Logic:**
```apex
Vendor_Program_Onboarding_Req_Template__c template = [
    SELECT Onboarding_Requirement_Set__r.Active__c
    FROM Vendor_Program_Onboarding_Req_Template__c
    WHERE Id = :recordId
];
if (template.Onboarding_Requirement_Set__r != null && !template.Onboarding_Requirement_Set__r.Active__c) {
    throw new AuraHandledException('Cannot activate Template because the associated Requirement Set is not active.');
}
```

**Issues & Recommendations:**
- **⚠️ Not Registered:** This rule exists but is not registered in `OnboardingAppRuleRegistry.getActivationRulesForObject()`
- **Recommendation:** Add to registry if needed, or remove if not used

---

### AllTemplatesInGroupMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/AllTemplatesInGroupMustBeActiveRule.cls`

**Purpose:** Ensures all templates in a requirement group are active before activating the group.

**Guards Implemented:**
- ✅ Queries all `Vendor_Program_Onboarding_Req_Template__c` records where `Category_Group__c = recordId`
- ✅ Validates each template has `Active__c = true`
- ✅ Throws exception with template name if any template is inactive

**Registered For:** `Vendor_Program_Requirement_Group__c` (not currently in registry, but rule exists)

**Key Logic:**
```apex
List<Vendor_Program_Onboarding_Req_Template__c> templates = [
    SELECT Id, Name, Active__c
    FROM Vendor_Program_Onboarding_Req_Template__c
    WHERE Category_Group__c = :recordId
];
for (Vendor_Program_Onboarding_Req_Template__c tpl : templates) {
    if (!tpl.Active__c) {
        throw new AuraHandledException('Cannot activate Requirement Group because assigned template ' + tpl.Name + ' is not active.');
    }
}
```

**Issues & Recommendations:**
- **⚠️ Not Registered:** This rule exists but is not registered in `OnboardingAppRuleRegistry.getActivationRulesForObject()`
- **Recommendation:** Add to registry if requirement groups should have activation rules

---

### 5. RequireParentVersionOnActivationRule

**Location:** `force-app/main/default/classes/rules/RequireParentVersionOnActivationRule.cls`

**Purpose:** Ensures non-draft versions have a parent version reference.

**Guards Implemented:**
- ✅ Prevents activation of non-draft records without `Parent_Version__c`
- ✅ Only applies when record is not in Draft status

**Key Logic:**
```apex
Boolean needsLink = rec.Status__c != 'Draft' && rec.Parent_Version__c == null;
if (needsLink && existing != null && existing > 0) {
    rec.addError('Non-draft versions must reference a parent version.');
}
```

**Issues & Recommendations:**

1. **⚠️ Logic Issue**
   - **Issue:** Checks if existing records exist, but error message doesn't match logic
   - **Recommendation:** Clarify the rule logic:
   ```apex
   // If this is NOT a draft and has no parent, it must be the first record
   // OR it must have a parent version
   Boolean isNonDraft = rec.Status__c != 'Draft';
   Boolean hasNoParent = rec.Parent_Version__c == null;
   Boolean isNotFirstRecord = existing != null && existing > 0;
   
   if (isNonDraft && hasNoParent && isNotFirstRecord) {
       rec.addError('Non-draft versions must reference a parent version. Only the first record can be created without a parent.');
   }
   ```

2. **⚠️ Field Name Inconsistency**
   - **Issue:** Uses `Status__c` but other rules use `Is_Active__c`
   - **Recommendation:** Document which field to check and why

3. **✅ Good:** Prevents orphaned version records

---

### 6. OnlyOneActiveRecGrpPerPrgrmRule

**Location:** `force-app/main/default/classes/rules/OnlyOneActiveRecGrpPerPrgrmRule.cls`

**Purpose:** Ensures only one active version exists per parent version.

**Guards Implemented:**
- ✅ Prevents multiple active versions of the same parent
- ✅ Uses aggregate queries for performance

**Key Logic:**
```apex
if (rec.Is_Active__c && rec.Parent_Version__c != null) {
    if (activeCountByParent.get(rec.Parent_Version__c) > 1) {
        rec.addError('Only one active version is allowed per Recipient Group.');
    }
}
```

**Issues & Recommendations:**

1. **⚠️ Race Condition Risk**
   - **Issue:** Counts include records in current batch, but doesn't account for concurrent updates
   - **Recommendation:** Add database-level unique constraint or use FOR UPDATE:
   ```apex
   // Consider adding unique constraint at database level
   // OR use FOR UPDATE in query to lock records
   ```

2. **⚠️ Field Name Inconsistency**
   - **Issue:** Uses `Is_Active__c` while other classes use `Active__c`
   - **Recommendation:** Standardize on one field name or document the difference

3. **✅ Good:** Efficient aggregate query approach

---

### 7. RecipientAndProgramMustBeActiveRule

**Location:** `force-app/main/default/classes/rules/RecipientAndProgramMustBeActiveRule.cls`

**Purpose:** Ensures related Recipient Group and Vendor Program are active before activation.

**Guards Implemented:**
- ✅ Validates `Recipient_Group__c.Is_Active__c` is true
- ✅ Validates `Vendor_Program__c.Active__c` is true
- ✅ Only validates when record itself is being activated

**Key Logic:**
```apex
if (rec.Is_Active__c) {
    if (!groups.get(rec.Recipient_Group__c).Is_Active__c) {
        rec.addError('Recipient Group must be active before this record can be activated.');
    }
    if (!programs.get(rec.Vendor_Program__c).Active__c) {
        rec.addError('Vendor Program must be active before this record can be activated.');
    }
}
```

**Issues & Recommendations:**

1. **⚠️ Field Name Inconsistency**
   - **Issue:** Uses `Is_Active__c` for Recipient Group but `Active__c` for Vendor Program
   - **Recommendation:** Document why different fields are used, or standardize

2. **⚠️ Null Safety**
   - **Issue:** Doesn't check if `groups.get()` or `programs.get()` returns null
   - **Recommendation:** Add null checks:
   ```apex
   if (rec.Recipient_Group__c != null) {
       Recipient_Group__c group = groups.get(rec.Recipient_Group__c);
       if (group == null || !group.Is_Active__c) {
           rec.addError('Recipient Group must be active before this record can be activated.');
       }
   }
   ```

3. **✅ Good:** Prevents activation of records with inactive dependencies

---

### 8. PreventDupRecGrpAssignmentRule

**Location:** `force-app/main/default/classes/rules/PreventDupRecGrpAssignmentRule.cls`

**Purpose:** Prevents duplicate assignments of the same Recipient Group to the same Vendor Program.

**Guards Implemented:**
- ✅ Prevents duplicates within the same transaction
- ✅ Prevents duplicates with existing active records
- ✅ Handles updates correctly (allows same record to update)

**Key Logic:**
```apex
// Checks both Is_Active__c = true OR Status__c = 'Active'
WHERE (Is_Active__c = true OR Status__c = 'Active')
```

**Issues & Recommendations:**

1. **⚠️ Dual Field Check**
   - **Issue:** Checks both `Is_Active__c` and `Status__c` which could be inconsistent
   - **Recommendation:** Standardize on one field or document why both are needed:
   ```apex
   // Note: Checking both fields because some records may use Status__c
   // while others use Is_Active__c. Consider standardizing in future.
   ```

2. **⚠️ Performance**
   - **Issue:** Queries all existing records for each batch
   - **Recommendation:** Consider using aggregate query or unique constraint:
   ```apex
   // Consider adding unique constraint: (Vendor_Program__c, Recipient_Group__c)
   // WHERE Is_Active__c = true
   ```

3. **✅ Good:** Handles both insert and update scenarios correctly

---

### 9. VersioningTriggerHandler

**Location:** `force-app/main/default/classes/handlers/VersioningTriggerHandler.cls`

**Purpose:** Enforces versioning constraints at the trigger level for any versioned object.

**Guards Implemented:**
- ✅ Auto-corrects invalid Draft + Active combinations
- ✅ Enforces one active version per parent
- ✅ Supports dynamic object detection

**Key Logic:**
```apex
// Auto-correct: Draft records cannot be Active
if (status == 'Draft' && isActive == true) {
    record.put('Active__c', false);
}

// Enforce: Only one active per parent
if (willBeActive && p != null && count > 1) {
    rec.addError('Only one active version is allowed per record lineage.');
}
```

**Issues & Recommendations:**

1. **⚠️ Silent Auto-Correction**
   - **Issue:** Silently changes `Active__c` from true to false for Draft records
   - **Recommendation:** Consider logging or warning:
   ```apex
   if (status == 'Draft' && isActive == true) {
       System.debug(LoggingLevel.WARN, 'Auto-correcting: Draft record cannot be Active. Setting Active__c to false for record: ' + record.Id);
       record.put('Active__c', false);
   }
   ```

2. **⚠️ Dynamic SOQL**
   - **Issue:** Uses string concatenation for SOQL
   - **Recommendation:** Validate object name or use static queries per object type

3. **⚠️ Incomplete enforceRootRecordAllowance**
   - **Issue:** Method exists but doesn't do anything
   - **Recommendation:** Implement or remove:
   ```apex
   private static void enforceRootRecordAllowance(List<SObject> newList) {
       // TODO: Implement root record validation
       // OR remove if not needed
   }
   ```

4. **✅ Good:** Generic handler works for any versioned object

---

### 10. OnboardingAppRuleEngineHandler

**Location:** `force-app/main/default/classes/handlers/OnboardingAppRuleEngineHandler.cls`

**Purpose:** Applies validation rules from registry to records in triggers.

**Guards Implemented:**
- ✅ Executes all registered rules for an object type
- ✅ Called from triggers before insert/update

**Key Logic:**
```apex
public static void apply(String sObjectType, List<SObject> newList, Map<Id, SObject> oldMap) {
    List<OnboardingAppValidationRule> rules = getRulesFor(sObjectType);
    for (OnboardingAppValidationRule rule : rules) {
        rule.validate(newList, oldMap);
    }
}
```

**Issues & Recommendations:**

1. **⚠️ No Error Aggregation**
   - **Issue:** If multiple rules fail, all errors are added but not prioritized
   - **Recommendation:** Consider error prioritization or early exit:
   ```apex
   // Option 1: Stop on first error
   for (OnboardingAppValidationRule rule : rules) {
       rule.validate(newList, oldMap);
       // Check if any errors were added
       for (SObject rec : newList) {
           if (rec.hasErrors()) {
               return; // Stop processing
           }
       }
   }
   
   // Option 2: Continue and collect all errors (current behavior)
   ```

2. **⚠️ No Logging**
   - **Issue:** Doesn't log which rules were executed
   - **Recommendation:** Add debug logging:
   ```apex
   System.debug('Applying ' + rules.size() + ' validation rules for ' + sObjectType);
   ```

3. **✅ Good:** Clean separation - handler doesn't know about specific rules

---

## Summary of Critical Issues

### High Priority

1. **✅ PARTIALLY FIXED: Activation Services Execute Rules**
   - **Status:** `OnboardingAppActivationService` now executes activation rules (✅ FIXED)
   - **Issue:** `VendorProgramActivationService` still does NOT execute activation rules (⚠️ NEEDS FIX)
   - **Risk:** Vendor programs can be activated even if they fail activation rules (e.g., requirement groups not active)
   - **Fix:** Add activation rule execution in `VendorProgramActivationService.activate()`:
   ```apex
   // Before deactivateSiblings(), add:
   List<OnboardingAppActivationRule> rules = 
       OnboardingAppRuleRegistry.getActivationRulesForObject('Vendor_Customization__c');
   for (OnboardingAppActivationRule rule : rules) {
       rule.apply(recordId, 'Vendor_Customization__c');
   }
   ```

2. **⚠️ Bug in AllRequirementGroupsMustBeActiveRule**
   - **Issue:** Method signature is `apply(String objectApiName, Id recordId)` but interface requires `apply(Id recordId, String objectApiName)`
   - **Risk:** Will cause runtime error when called
   - **Fix:** Correct the parameter order to match interface

3. **Field Name Inconsistency**
   - Some classes use `Active__c`, others use `Is_Active__c`
   - Some rules check `Status__c`, others check `Is_Active__c`
   - **Risk:** Inconsistent validation behavior
   - **Fix:** Standardize field names or document the difference clearly

3. **✅ FIXED: Activation Rules for Vendor_Customization__c**
   - **Status:** `AllRequirementGroupsMustBeActiveRule` is now registered for `Vendor_Customization__c`
   - **Note:** However, `VendorProgramActivationService` doesn't call these rules yet (see issue #1)

### Medium Priority

4. **Race Conditions**
   - `OnlyOneActiveRecGrpPerPrgrmRule` and versioning logic may have race conditions
   - **Fix:** Add database constraints or use FOR UPDATE locks

5. **Silent Auto-Correction**
   - `VersioningTriggerHandler` silently changes data
   - **Fix:** Add logging or warnings

6. **Incomplete Error Messages**
   - Generic error messages don't indicate which validation failed
   - **Fix:** Add specific error context

### Low Priority

7. **Performance Optimization**
   - Some rules query all records instead of using aggregates
   - **Fix:** Optimize queries

8. **Documentation**
   - Missing documentation for rule purposes and field usage
   - **Fix:** Add inline documentation

---

## Recommended Architecture Improvements

### 1. Unified Activation Flow

```
Controller → Orchestrator → Validation → Service → Repository
                ↓
         Rule Registry
```

**Implementation:**
```apex
public static void activate(Id recordId, String objectApiName) {
    // 1. Validate input
    validateInput(recordId, objectApiName);
    
    // 2. Execute validation rules
    executeValidationRules(recordId, objectApiName);
    
    // 3. Execute activation service
    executeActivationService(recordId, objectApiName);
    
    // 4. Post-activation hooks
    executePostActivationHooks(recordId, objectApiName);
}
```

### 2. Standardize Field Names

Create a utility class to handle field name differences:
```apex
public class ActivationFieldHelper {
    public static Boolean isActive(SObject record) {
        if (record.getSObjectType().getDescribe().fields.getMap().containsKey('Active__c')) {
            return (Boolean) record.get('Active__c');
        } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('Is_Active__c')) {
            return (Boolean) record.get('Is_Active__c');
        }
        return false;
    }
    
    public static void setActive(SObject record, Boolean value) {
        if (record.getSObjectType().getDescribe().fields.getMap().containsKey('Active__c')) {
            record.put('Active__c', value);
        } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('Is_Active__c')) {
            record.put('Is_Active__c', value);
        }
    }
}
```

### 3. Add Database Constraints

Consider adding unique constraints at the database level:
- `(Vendor_Program__c, Recipient_Group__c)` WHERE `Is_Active__c = true`
- `(Previous_Version__c)` WHERE `Active__c = true` (one active per parent)

### 4. Comprehensive Logging

Add logging throughout the activation flow:
```apex
public static void activate(Id recordId, String objectApiName) {
    System.debug('Activation started: ' + objectApiName + ' - ' + recordId);
    try {
        // ... activation logic
        System.debug('Activation successful: ' + recordId);
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'Activation failed: ' + e.getMessage());
        throw e;
    }
}
```

---

## Testing Recommendations

1. **Test Activation Bypass Scenarios**
   - Verify that validation rules are executed during activation
   - Test that invalid records cannot be activated even through services

2. **Test Concurrent Activation**
   - Test race conditions with multiple users activating versions simultaneously
   - Verify only one active version exists after concurrent updates

3. **Test Field Name Variations**
   - Test with both `Active__c` and `Is_Active__c` fields
   - Verify consistent behavior

4. **Test Error Messages**
   - Verify error messages are clear and actionable
   - Test that all validation errors are surfaced

---

## Related Documentation

- [Security Model](./security-model.md)
- [Apex Patterns](../architecture/apex-patterns.md)
- [Apex Classes](../components/apex-classes.md)

