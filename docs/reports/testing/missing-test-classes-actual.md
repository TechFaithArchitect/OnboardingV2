# Missing Test Classes - ACTUAL Status

**Last Updated**: After verification of existing test classes  
**Status**: Most test classes exist! Only a few are actually missing.

---

## ✅ GOOD NEWS: Most Test Classes Already Exist!

### Repositories - ALL HAVE TESTS ✅
All 15 repositories have comprehensive test classes:
- ✅ EmailCommLogRepositoryTest
- ✅ EmailAttachmentRepositoryTest
- ✅ OnboardingAppActivationRepositoryTest
- ✅ VendorCustomizationRepositoryTest
- ✅ OrgWideEmailAddressRepositoryTest
- ✅ OnboardingApplicationRepositoryTest
- ✅ OnboardingRulesRepositoryTest
- ✅ OnboardingRepositoryTest
- ✅ OnboardingAppECCRepositoryTest
- ✅ OnboardingAppVendorProgramReqRepoTest
- ✅ VendorOnboardingWizardRepositoryTest (just added!)
- ✅ CommunicationTemplateRepositoryTest
- ✅ EmailCatalogCMDTRepositoryTest
- ✅ EmailTemplateRepositoryTest
- ✅ OrgWideEmailCMDTRepositoryTest
- ✅ OrgWideEmailRepositoryTest

---

## 🔴 ACTUALLY MISSING - Critical Priority

### Services (4 Missing)

1. **OnboardingAppECCService** ❌
   - **Location**: `services/OnboardingAppECCService.cls`
   - **Priority**: HIGH - Business logic service
   - **Methods to test**: All service methods

2. **OnboardingRuleEvaluator** ❌
   - **Location**: `services/OnboardingRuleEvaluator.cls`
   - **Priority**: CRITICAL - Complex rule evaluation logic
   - **Methods to test**: `evaluateRule()`, `evaluate()`

3. **VendorOnboardingWizardService** ❌
   - **Location**: `services/VendorOnboardingWizardService.cls`
   - **Priority**: HIGH - Wizard business logic
   - **Methods to test**: All service methods

4. **EmailCommLoggerService** ❌
   - **Location**: `services/EmailCommLoggerService.cls`
   - **Priority**: MEDIUM - Logging service
   - **Methods to test**: `logImmediately()`
   - **Note**: `EmailCommLoggerQueueable` has test, but service doesn't

### Controllers (6 Missing - Pass-Through, Minimal Tests Needed)

1. **OnboardingAppECCController** ❌
   - **Type**: Pass-through (delegates to service)
   - **Priority**: MEDIUM - LWC integration point
   - **Test Strategy**: Minimal - verify delegation works

2. **OnboardingRequirementsPanelController** ❌
   - **Type**: Pass-through (delegates to service)
   - **Priority**: MEDIUM - LWC integration point
   - **Test Strategy**: Minimal - verify delegation works

3. **OnboardingStatusRuleController** ❌
   - **Type**: Pass-through (delegates to service)
   - **Priority**: MEDIUM - LWC integration point
   - **Test Strategy**: Minimal - verify delegation works

4. **OnboardingStatusRulesEngineController** ❌
   - **Type**: Pass-through (delegates to service)
   - **Priority**: MEDIUM - LWC integration point
   - **Test Strategy**: Minimal - verify delegation works

5. **OnboardingAppVendorProgramReqCtlr** ❌
   - **Type**: Pass-through (delegates to service)
   - **Priority**: MEDIUM - LWC integration point
   - **Test Strategy**: Minimal - verify delegation works

6. **VendorOnboardingWizardController** ❌
   - **Type**: Pass-through (delegates to service)
   - **Priority**: MEDIUM - LWC integration point
   - **Test Strategy**: Minimal - verify delegation (30+ methods, can group tests)

---

## 🟡 MEDIUM PRIORITY - Missing Test Classes

### Orchestrators (1 Missing)

1. **OnboardingAppVendorProgramReqOrch** ❌
   - **Location**: `orchestrators/OnboardingAppVendorProgramReqOrch.cls`
   - **Priority**: MEDIUM - Has validation logic + direct DML
   - **Methods to test**: 
     - `orchestrateCredentialLoad()` - validation + delegation
     - `orchestrateTrainingLoad()` - validation + delegation
     - `orchestrateCreateCredential()` - validation + direct DML ⚠️
     - `orchestrateCreateTraining()` - validation + direct DML ⚠️
   - **Note**: ⚠️ Contains direct DML (lines 27, 37) - should use repository pattern

### Helpers (1 Missing)

1. **EmailCommLogHelper** ❌
   - **Location**: `helpers/EmailCommLogHelper.cls`
   - **Priority**: MEDIUM - Helper with logic
   - **Methods to test**: `buildLogFromRequest()`

### Utilities (2-3 Missing)

1. **OnboardingExpressionEngine** ❌
   - **Location**: `util/OnboardingExpressionEngine.cls`
   - **Priority**: MEDIUM - Expression parsing/evaluation
   - **Methods to test**: `evaluate()`, `clearCache()`
   - **Used by**: OnboardingRuleEvaluator

2. **RecipientGroupUtil** ❌
   - **Location**: `util/RecipientGroupUtil.cls`
   - **Priority**: LOW - Check if has logic
   - **Methods to test**: Check class for methods

3. **Utilities** ❌
   - **Location**: `util/Utilities.cls`
   - **Priority**: LOW - Check if has logic
   - **Methods to test**: Check class for methods

### Rules/Registry (1 Missing)

1. **OnboardingAppRuleRegistry** ❌
   - **Location**: `rules/OnboardingAppRuleRegistry.cls`
   - **Priority**: MEDIUM - Rule registration
   - **Methods to test**: `getValidationRules()`, `getActivationRulesForObject()`

### Handlers (1-2 Missing)

1. **OnboardingAppVendorProgramReqHdlr** ❌
   - **Location**: `handlers/OnboardingAppVendorProgramReqHdlr.cls`
   - **Priority**: MEDIUM - Trigger handler logic

2. **VendorProgramGroupMemberTriggerHandler** ❌
   - **Location**: `handlers/VendorProgramGroupMemberTriggerHandler.cls`
   - **Priority**: LOW - Simple pass-through to VersioningTriggerHandler
   - **Test Strategy**: Minimal - verify delegation

---

## 🟢 LOW PRIORITY - Missing Test Classes

### Rules (Many Missing, But Some Have Tests)

**Rules with Tests** ✅:
- ✅ OnlyOneActiveRecGrpPerPrgrmRuleTest
- ✅ PreventDupRecGrpAssignmentRuleTest
- ✅ RecipientAndProgramMustBeActiveRuleTest
- ✅ RequireParentVersionOnActivationRuleTest

**Rules Missing Tests** ❌:
- AllChildRequirementsMustBeActiveRule
- AllLinkedEngineMustBeActiveRule
- AllRequirementGroupsMustBeActiveRule
- AllRequirementSetMustBeActiveRule
- AllStatusRuleGroupMustBeActiveRule
- AllStatusRulesMustBeActiveRule
- AllTemplatesInGroupMustBeActiveRule
- AllTemplatesInReqSetMustBeActiveRule
- NoDuplicateRecipientGroupAssignmentRule

**Priority**: LOW - These are validation rules, can be tested when needed

### DTOs (Check if they have logic)

Most DTOs are likely pure data structures. Check these if they have constructors/methods:
- EmailSyncSummaryDTO - Has constructor with calculations
- EmailTemplateDTO - Check for `toSObject()`, `hasChanges()` methods
- OrgWideEmailDTO - Check for `toSObject()` method
- Others - Check if they have logic

---

## 📊 Summary

### Actually Missing Test Classes

- **🔴 Critical Services**: 4 classes
- **🟡 Controllers (Pass-Through)**: 6 classes (minimal tests needed)
- **🟡 Orchestrators**: 1 class
- **🟡 Helpers/Utilities**: 3-4 classes
- **🟡 Rules/Registry**: 1 class
- **🟡 Handlers**: 1-2 classes
- **🟢 Rules**: 9 classes (low priority)
- **🟢 DTOs**: Check if they have logic

**Total Actually Missing**: ~21-25 classes (much less than originally thought!)

### What's Already Covered ✅

- ✅ **ALL Repositories** (15/15) - 100% coverage
- ✅ **Most Services** (9/13) - 69% coverage
- ✅ **Some Controllers** (3/9) - 33% coverage
- ✅ **Some Orchestrators** (4/5) - 80% coverage
- ✅ **Some Helpers** (2/3) - 67% coverage
- ✅ **Some Utilities** (1/4) - 25% coverage
- ✅ **Some Handlers** (3/5) - 60% coverage
- ✅ **Some Rules** (4/13) - 31% coverage

---

## 🎯 Recommended Testing Priority

### Phase 1: Critical Services (Week 1)
1. OnboardingRuleEvaluator - CRITICAL (complex logic)
2. OnboardingAppECCService - HIGH (business logic)
3. VendorOnboardingWizardService - HIGH (business logic)
4. EmailCommLoggerService - MEDIUM (logging)

### Phase 2: Controllers (Week 2)
All 6 controllers - minimal pass-through tests
- Can group similar tests
- Focus on verifying delegation works

### Phase 3: Supporting Classes (Week 3)
1. OnboardingAppVendorProgramReqOrch - Has logic + DML issue
2. EmailCommLogHelper - Helper with logic
3. OnboardingExpressionEngine - Used by rule evaluator
4. OnboardingAppRuleRegistry - Rule registration
5. OnboardingAppVendorProgramReqHdlr - Trigger handler

### Phase 4: Low Priority (As Needed)
- Rules without tests (9 classes)
- DTOs with logic
- Other utilities

---

## ⚠️ Issues Found

### 1. Direct DML in Orchestrator
**File**: `OnboardingAppVendorProgramReqOrch.cls`
- **Issue**: Contains direct `insert` statements (lines 27, 37)
- **Should**: Use repository pattern
- **Priority**: Medium - Should be refactored before or during testing

---

## ✅ Conclusion

**Great news!** Most test classes already exist. The codebase has:
- ✅ 100% repository test coverage
- ✅ 69% service test coverage
- ✅ Good coverage of orchestrators, helpers, and handlers

**Only ~21-25 classes actually need tests**, and many of those are:
- Pass-through controllers (minimal tests)
- Low-priority rules
- DTOs that may not need tests

**Focus on the 4 critical services first**, then the pass-through controllers.

