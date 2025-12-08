# Missing Test Classes - Prioritized for Minimal Full Coverage

**Last Updated**: After verification - Most test classes already exist!  
**Strategy**: Focus on classes with actual logic, minimize pass-through testing  
**Status**: ✅ All repositories have tests! Only ~21-25 classes actually missing.

---

## 🎯 Testing Strategy

### Pass-Through Classes (Minimal Testing)
- **Controllers** that only delegate to services/orchestrators → Test that delegation works
- **Orchestrators** that only call repositories → Test that calls are made correctly
- **Simple DTOs** with no logic → Skip tests (unless they have constructors/methods)

### Classes Needing Full Tests
- **Repositories** → All SOQL/DML operations
- **Services** → Business logic, validation, coordination
- **Evaluators/Engines** → Complex logic
- **Helpers/Utilities** → Logic-based methods
- **DTOs with Logic** → Constructors, transformation methods

---

## ✅ GOOD NEWS: All Repositories Have Tests!

**All 15 repositories already have comprehensive test classes:**
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

**Repository Test Coverage: 100% ✅**

---

## 🔴 CRITICAL PRIORITY - Actually Missing Test Classes

### Services (4 Missing - Business Logic Layer)
**Services need tests for business logic, validation, coordination**

1. ✅ **OnboardingRuleEvaluator** ❌ MISSING
   - **Methods**: `evaluateRule()`, `evaluate()`
   - **Complexity**: High - Complex rule evaluation logic
   - **Priority**: CRITICAL - Rules engine core logic

2. ✅ **OnboardingAppECCService** ❌ MISSING
   - **Methods**: Check all methods in class
   - **Complexity**: Medium - Business logic
   - **Priority**: HIGH - ECC functionality

3. ✅ **VendorOnboardingWizardService** ❌ MISSING
   - **Methods**: Check all methods in class
   - **Complexity**: High - Multiple operations
   - **Priority**: HIGH - Wizard functionality

4. ✅ **OnboardingRuleEvaluator** ❌ MISSING
   - **Methods**: `evaluateRule()`, `evaluate()`
   - **Complexity**: High - Complex rule evaluation logic
   - **Priority**: CRITICAL - Rules engine core logic

5. ✅ **EmailCommLoggerService** ❌ MISSING
   - **Methods**: `logImmediately()`
   - **Complexity**: Low - Simple logging
   - **Priority**: MEDIUM - Logging service
   - **Note**: `EmailCommLoggerQueueable` has test, but service doesn't

**Note**: `OnboardingApplicationService` ✅ HAS TEST - was incorrectly listed as missing

### Controllers (LWC Integration)
**Controllers are mostly pass-through - minimal tests needed**

1. ✅ **OnboardingAppECCController** ❌ MISSING
   - **Type**: Pass-through (delegates to service)
   - **Test Strategy**: Test that service methods are called correctly
   - **Priority**: MEDIUM - LWC integration point

2. ✅ **OnboardingRequirementsPanelController** ❌ MISSING
   - **Type**: Pass-through (delegates to service)
   - **Test Strategy**: Test delegation
   - **Priority**: MEDIUM - LWC integration point

3. ✅ **OnboardingStatusRuleController** ❌ MISSING
   - **Type**: Pass-through (delegates to service)
   - **Test Strategy**: Test delegation
   - **Priority**: MEDIUM - LWC integration point

4. ✅ **OnboardingStatusRulesEngineController** ❌ MISSING
   - **Type**: Pass-through (delegates to service)
   - **Test Strategy**: Test delegation
   - **Priority**: MEDIUM - LWC integration point

5. ✅ **OnboardingAppVendorProgramReqCtlr** ❌ MISSING
   - **Type**: Pass-through (delegates to service)
   - **Test Strategy**: Test delegation
   - **Priority**: MEDIUM - LWC integration point

6. ✅ **VendorOnboardingWizardController** ❌ MISSING
   - **Type**: Pass-through (delegates to service)
   - **Test Strategy**: Test delegation (30+ methods - can group tests)
   - **Priority**: MEDIUM - LWC integration point

---

## 🟡 MEDIUM PRIORITY - Missing Test Classes

### Orchestrators
**Some orchestrators are pass-through, some have coordination logic**

1. ✅ **OnboardingAppVendorProgramReqOrch** ❌ MISSING
   - **Type**: Has validation logic + direct DML (should use repository)
   - **Complexity**: Medium - Has null checks and validation
   - **Priority**: MEDIUM - Has logic beyond pass-through
   - **Note**: ⚠️ Contains direct DML (lines 27, 37) - should be refactored to use repository

### Helpers
**Helpers with logic need tests**

1. ✅ **EmailCommLogHelper** ❌ MISSING
   - **Methods**: `buildLogFromRequest()`
   - **Complexity**: Low - Data transformation
   - **Priority**: MEDIUM - Helper with logic

### Utilities
**Utilities with logic need tests**

1. ✅ **OnboardingExpressionEngine** ❌ MISSING
   - **Methods**: `evaluate()`, `clearCache()`
   - **Complexity**: Medium - Expression parsing/evaluation
   - **Priority**: MEDIUM - Used by rule evaluator

### Rules/Registry
**Rules and registry need tests**

1. ✅ **OnboardingAppRuleRegistry** ❌ MISSING
   - **Methods**: `getValidationRules()`, `getActivationRulesForObject()`
   - **Complexity**: Low - Registry pattern
   - **Priority**: MEDIUM - Rule registration

### Handlers
**Handlers need tests for trigger logic**

1. ✅ **OnboardingAppVendorProgramReqHdlr** ❌ MISSING
   - **Type**: Trigger handler
   - **Priority**: MEDIUM - Trigger logic

2. ✅ **VendorProgramGroupMemberTriggerHandler** ❌ MISSING
   - **Type**: Pass-through (delegates to VersioningTriggerHandler)
   - **Test Strategy**: Minimal - test delegation
   - **Priority**: LOW - Simple pass-through

---

## 🟢 LOW PRIORITY - Missing Test Classes

### DTOs (Only if they have logic)

1. ✅ **EmailSyncSummaryDTO** ❌ MISSING
   - **Has Logic**: Constructor with calculations
   - **Priority**: LOW - Has logic, but simple

2. ✅ **EmailTemplateDTO** ❌ MISSING
   - **Has Logic**: Check for `toSObject()`, `hasChanges()` methods
   - **Priority**: LOW - If has transformation methods

3. ✅ **OrgWideEmailDTO** ❌ MISSING
   - **Has Logic**: Check for `toSObject()` method
   - **Priority**: LOW - If has transformation methods

4. ✅ **EmailCommSendRequestDTO** ❌ MISSING
   - **Has Logic**: Check for methods
   - **Priority**: LOW - If has logic

5. ✅ **EmailCommSendResultDTO** ❌ MISSING
   - **Has Logic**: Check for methods
   - **Priority**: LOW - If has logic

6. ✅ **EmailTemplateSyncRequestDTO** ❌ MISSING
   - **Has Logic**: Check for methods
   - **Priority**: LOW - If has logic

7. ✅ **RecipientGroupEmailRequestDTO** ❌ MISSING
   - **Has Logic**: Check for methods
   - **Priority**: LOW - If has logic

8. ✅ **RecipientGroupEmailResultDTO** ❌ MISSING
   - **Has Logic**: Check for methods
   - **Priority**: LOW - If has logic

### Jobs
**Scheduled jobs need basic tests**

1. ✅ **EmailCommTerritoryRoleSyncJob** ❌ MISSING
   - **Type**: Scheduled job
   - **Priority**: LOW - Basic execution test

---

## ❌ Classes That DON'T Need Tests

### Test Factories (They ARE test utilities)
- `TestAccountFactory`
- `TestCommTemplateFactory`
- `TestContactFactory`
- `TestCredentialFactory`
- `TestDataFactory`
- `TestDataFactoryIdUtil`
- `TestDataFactoryUtil`
- `TestDataFactoryWrapper`
- `TestECCFactory`
- `TestEmailCommLogFactory`
- `TestEmailCommSendResultFactory`
- `TestProductFactory`
- `TestRequiredCredentialFactory`
- `TestTrainingRequirementFactory`
- `TestTrainingSystemFactory`
- `TestVendorFactory`
- `TestVendorProgramFactory`

**Reason**: Test factories are test utilities themselves - they don't need tests.

### Interfaces (No Implementation)
- `OnboardingAppValidationRule` - Interface only
- `OnboardingAppActivationRule` - Interface only

### Constants (No Logic)
- `EmailSyncServiceConstants` - Pure constants

### Simple Pass-Through Controllers (Already Tested)
- `OnboardingAppActivationController` ✅ HAS TEST
- `EmailTemplateSyncController` ✅ HAS TEST
- `OrgWideEmailSyncController` ✅ HAS TEST

---

## 📊 Summary Statistics - ACTUAL STATUS

### Missing Test Classes by Priority

- **🔴 CRITICAL Services**: 4 classes
- **🟡 MEDIUM Controllers**: 6 classes (pass-through, minimal tests)
- **🟡 MEDIUM Supporting**: 5 classes (Orchestrators, Helpers, Utilities, Handlers)
- **🟢 LOW Priority**: 9-10 classes (Rules, DTOs with logic, Jobs)

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

### Test Coverage Strategy

1. **Phase 1 (Week 1)**: Critical Services (4 classes)
   - ✅ Repositories already done!
   - `OnboardingRuleEvaluator` - CRITICAL (complex logic)
   - `OnboardingAppECCService` - HIGH (business logic)
   - `VendorOnboardingWizardService` - HIGH (business logic)
   - `EmailCommLoggerService` - MEDIUM (logging)

2. **Phase 2 (Week 2)**: Controllers (6 classes)
   - All pass-through - minimal tests needed
   - Can group similar tests

3. **Phase 3 (Week 3)**: Supporting Classes (5 classes)
   - Orchestrators, Helpers, Utilities, Handlers
   - DTOs with logic

---

## 🎯 Minimal Full Coverage Approach

### For Pass-Through Controllers
```apex
@isTest
static void testMethod_DelegatesToService() {
    // Arrange
    // Mock service if needed
    
    // Act
    Test.startTest();
    Controller.method(params);
    Test.stopTest();
    
    // Assert
    // Verify service was called (or verify result)
}
```

### For Repositories
```apex
@isTest
static void testMethod_InsertsRecord() {
    // Arrange
    SObject record = TestFactory.create();
    
    // Act
    Test.startTest();
    Repository.insertRecord(record);
    Test.stopTest();
    
    // Assert
    List<SObject> results = [SELECT Id FROM SObject WHERE Id = :record.Id];
    System.assertEquals(1, results.size());
}
```

### For Services
```apex
@isTest
static void testMethod_ValidatesAndProcesses() {
    // Arrange
    // Setup test data
    
    // Act
    Test.startTest();
    Service.method(params);
    Test.stopTest();
    
    // Assert
    // Verify business logic executed correctly
}
```

---

## ⚠️ Issues Found During Analysis

### 1. Direct DML in Orchestrator
**File**: `OnboardingAppVendorProgramReqOrch.cls`
- **Issue**: Contains direct `insert` statements (lines 27, 37)
- **Should**: Use repository pattern
- **Priority**: Medium - Should be refactored

### 2. Missing Repository Tests
**All repositories** are missing tests - this is the highest priority.

---

## Next Steps

1. ✅ Review this document
2. ✅ Start with Phase 1 (Repositories)
3. ✅ Create test classes following patterns above
4. ✅ Focus on minimal full coverage (not 100% line coverage)
5. ✅ Test business logic, not pass-through code

