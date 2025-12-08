# Apex Class Pattern Violations

This document lists all identified violations of the architectural patterns in the Apex codebase.

## Directory Organization Violations

### ✅ COMPLETED: Services in Root Directory
All service classes have been moved to `services/`:

1. ✅ **OnboardingApplicationService.cls** - MOVED
   - Now located: `/force-app/main/default/classes/services/OnboardingApplicationService.cls`
   - Status: ✅ Also refactored to use repository pattern

2. ✅ **OnboardingRulesService.cls** - MOVED
   - Now located: `/force-app/main/default/classes/services/OnboardingRulesService.cls`
   - Status: ✅ Also refactored to use repository pattern

3. ✅ **OnboardingAppECCService.cls** - MOVED
   - Now located: `/force-app/main/default/classes/services/OnboardingAppECCService.cls`
   - Status: ✅ Already correctly delegates to repository

### ✅ COMPLETED: Controllers in Root Directory
All controller classes have been moved to `controllers/`:

1. ✅ **OnboardingAppECCController.cls** - MOVED
   - Now located: `/force-app/main/default/classes/controllers/OnboardingAppECCController.cls`

2. ✅ **OnboardingRequirementsPanelController.cls** - MOVED
   - Now located: `/force-app/main/default/classes/controllers/OnboardingRequirementsPanelController.cls`

3. ✅ **OnboardingStatusRulesEngineController.cls** - MOVED
   - Now located: `/force-app/main/default/classes/controllers/OnboardingStatusRulesEngineController.cls`

4. ✅ **OnboardingStatusRuleController.cls** - MOVED
   - Now located: `/force-app/main/default/classes/controllers/OnboardingStatusRuleController.cls`

5. ✅ **VendorOnboardingWizardController.cls** - MOVED
   - Now located: `/force-app/main/default/classes/controllers/VendorOnboardingWizardController.cls`

### ✅ COMPLETED: Repositories in Root Directory
All repository classes have been moved to `repository/`:

1. ✅ **OnboardingAppECCRepository.cls** - MOVED
   - Now located: `/force-app/main/default/classes/repository/OnboardingAppECCRepository.cls`

2. ✅ **VendorOnboardingWizardRepository.cls** - MOVED
   - Now located: `/force-app/main/default/classes/repository/VendorOnboardingWizardRepository.cls`

3. ✅ **OnboardingApplicationRepository.cls** - CREATED
   - New repository created for `OnboardingApplicationService`
   - Location: `/force-app/main/default/classes/repository/OnboardingApplicationRepository.cls`

4. ✅ **OnboardingRulesRepository.cls** - CREATED
   - New repository created for `OnboardingRulesService`
   - Location: `/force-app/main/default/classes/repository/OnboardingRulesRepository.cls`

5. ✅ **OnboardingRepository.cls** - CREATED
   - New repository created for `OnboardingStatusEvaluator`
   - Location: `/force-app/main/default/classes/repository/OnboardingRepository.cls`

### ✅ COMPLETED: Handlers in Root Directory
All handler classes have been moved to `handlers/`:

1. ✅ **OnboardingAppRuleEngineHandler.cls** - MOVED
   - Now located: `/force-app/main/default/classes/handlers/OnboardingAppRuleEngineHandler.cls`
   - Note: Renaming to `*Hdlr.cls` pattern is low priority

### ✅ COMPLETED: Validation Rules in Root Directory
All validation rule classes have been moved to `rules/`:

1. ✅ **RequireParentVersionOnActivationRule.cls** - MOVED
   - Now located: `/force-app/main/default/classes/rules/RequireParentVersionOnActivationRule.cls`

2. ✅ **OnlyOneActiveRecGrpPerPrgrmRule.cls** - MOVED
   - Now located: `/force-app/main/default/classes/rules/OnlyOneActiveRecGrpPerPrgrmRule.cls`

3. ✅ **RecipientAndProgramMustBeActiveRule.cls** - MOVED
   - Now located: `/force-app/main/default/classes/rules/RecipientAndProgramMustBeActiveRule.cls`

4. ✅ **PreventDupRecGrpAssignmentRule.cls** - MOVED
   - Now located: `/force-app/main/default/classes/rules/PreventDupRecGrpAssignmentRule.cls`

5. ✅ **NoDuplicateRecipientGroupAssignmentRule.cls** - MOVED
   - Now located: `/force-app/main/default/classes/rules/NoDuplicateRecipientGroupAssignmentRule.cls`

6. ✅ **OnboardingAppRuleRegistry.cls** - MOVED
   - Now located: `/force-app/main/default/classes/rules/OnboardingAppRuleRegistry.cls`

7. ✅ **OnboardingAppValidationRule.cls** - MOVED
   - Now located: `/force-app/main/default/classes/rules/OnboardingAppValidationRule.cls`

### ✅ COMPLETED: Additional Classes in Root Directory

1. ✅ **OnboardingExpressionEngine.cls** - MOVED
   - Now located: `/force-app/main/default/classes/util/OnboardingExpressionEngine.cls`

2. ✅ **OnboardingRuleEvaluator.cls** - MOVED
   - Now located: `/force-app/main/default/classes/services/OnboardingRuleEvaluator.cls`

3. ✅ **OnboardingStatusEvaluator.cls** - MOVED
   - Now located: `/force-app/main/default/classes/services/OnboardingStatusEvaluator.cls`

4. ✅ **OnboardingStatusEvaluatorTest.cls** - MOVED
   - Now located: `/force-app/main/default/classes/services/OnboardingStatusEvaluatorTest.cls`

## Service Layer Pattern Violations

### ✅ FIXED: Direct SOQL in Services

1. **OnboardingApplicationService** ✅ FIXED
   - **Previous Violation**: Contained direct SOQL queries in multiple methods
   - **Fix Applied**: Created `OnboardingApplicationRepository` and moved all queries there
   - **Status**: ✅ All queries now go through repository
   - **Repository**: `OnboardingApplicationRepository`

2. **OnboardingRulesService** ✅ FIXED
   - **Previous Violation**: Contained direct SOQL queries in multiple methods
   - **Fix Applied**: Created `OnboardingRulesRepository` and moved all queries there
   - **Status**: ✅ All queries now go through repository
   - **Repository**: `OnboardingRulesRepository`

### ✅ FIXED: Direct DML in Services

1. **OnboardingApplicationService** ✅ FIXED
   - **Previous Violation**: Contained direct DML operations (upsert, insert)
   - **Fix Applied**: Moved all DML operations to `OnboardingApplicationRepository`
   - **Status**: ✅ All DML now goes through repository

2. **OnboardingRulesService** ✅ FIXED
   - **Previous Violation**: Contained direct DML operations (upsert, delete)
   - **Fix Applied**: Moved all DML operations to `OnboardingRulesRepository`
   - **Status**: ✅ All DML now goes through repository

3. **OnboardingStatusEvaluator** ✅ FIXED
   - **Previous Violation**: Directly updated records
   - **Fix Applied**: Created `OnboardingRepository` and moved update operation there
   - **Status**: ✅ All updates now go through repository
   - **Repository**: `OnboardingRepository`

### ✅ FIXED: Additional Direct SOQL/DML Violations

4. **OrgWideEmailSyncService** ✅ FIXED
   - **Previous Violation**: Direct SOQL query for OrgWideEmailAddress
   - **Fix Applied**: Created `OrgWideEmailAddressRepository` and moved query there
   - **Status**: ✅ All queries now go through repository
   - **Repository**: `OrgWideEmailAddressRepository`

5. **EmailAttachmentService** ✅ FIXED
   - **Previous Violation**: Direct SOQL queries for Attachment and ContentVersion
   - **Fix Applied**: Created `EmailAttachmentRepository` and moved queries there
   - **Status**: ✅ All queries now go through repository
   - **Repository**: `EmailAttachmentRepository`

6. **VendorProgramActivationService** ✅ FIXED
   - **Previous Violation**: Direct SOQL queries and DML operations
   - **Fix Applied**: Created `VendorCustomizationRepository` and moved all data access there
   - **Status**: ✅ All queries and DML now go through repository
   - **Repository**: `VendorCustomizationRepository`

7. **OnboardingAppActivationService** ✅ FIXED
   - **Previous Violation**: Direct dynamic SOQL queries and DML operations
   - **Fix Applied**: Created `OnboardingAppActivationRepository` for dynamic SOQL and moved DML there
   - **Status**: ✅ All queries and DML now go through repository
   - **Repository**: `OnboardingAppActivationRepository`

8. **EmailCommLoggerService** ✅ FIXED
   - **Previous Violation**: Direct DML operation (insert)
   - **Fix Applied**: Created `EmailCommLogRepository` and moved insert operation there
   - **Status**: ✅ All DML now goes through repository
   - **Repository**: `EmailCommLogRepository`

9. **EmailCommLoggerQueueable** ✅ FIXED
   - **Previous Violation**: Direct DML operation (insert)
   - **Fix Applied**: Uses `EmailCommLogRepository` for insert operation
   - **Status**: ✅ All DML now goes through repository
   - **Repository**: `EmailCommLogRepository`

10. **EmailCommDedupeUtil** ✅ FIXED
    - **Previous Violation**: Direct SOQL query
    - **Fix Applied**: Uses `EmailCommLogRepository` for query
    - **Status**: ✅ All queries now go through repository
    - **Repository**: `EmailCommLogRepository`

## Sharing Model Violations

### ✅ FIXED: Missing `with sharing` Declarations

1. **OnboardingExpressionEngine** ✅ FIXED
   - **Previous Violation**: Missing `with sharing` declaration
   - **Fix Applied**: Added `with sharing` declaration
   - **Status**: ✅ Now uses `with sharing`

2. **EmailAttachmentService** ✅ FIXED
   - **Previous Violation**: Missing `with sharing` declaration
   - **Fix Applied**: Added `with sharing` declaration
   - **Status**: ✅ Now uses `with sharing`

3. **EmailCommLoggerService** ✅ FIXED
   - **Previous Violation**: Missing `with sharing` declaration
   - **Fix Applied**: Added `with sharing` declaration
   - **Status**: ✅ Now uses `with sharing`

4. **EmailCommLoggerQueueable** ✅ FIXED
   - **Previous Violation**: Missing `with sharing` declaration
   - **Fix Applied**: Added `with sharing` declaration
   - **Status**: ✅ Now uses `with sharing`

5. **EmailCommLogHelper** ✅ FIXED
   - **Previous Violation**: Missing `with sharing` declaration
   - **Fix Applied**: Added `with sharing` declaration
   - **Status**: ✅ Now uses `with sharing`

6. **EmailCommDedupeUtil** ✅ FIXED
   - **Previous Violation**: Missing `with sharing` declaration
   - **Fix Applied**: Added `with sharing` declaration
   - **Status**: ✅ Now uses `with sharing`

7. **OnboardingAppRuleRegistry** ✅ FIXED
   - **Previous Violation**: Missing `with sharing` declaration
   - **Fix Applied**: Added `with sharing` declaration
   - **Status**: ✅ Now uses `with sharing`

8. **OnboardingStatusTrackerHandler** ✅ FIXED
   - **Previous Violation**: Missing `with sharing` declaration
   - **Fix Applied**: Added `with sharing` declaration
   - **Status**: ✅ Now uses `with sharing`

All classes now use `with sharing` correctly. No violations found.

## Naming Convention Violations

1. **OnboardingAppRuleEngineHandler**
   - **Issue**: Should be `OnboardingAppRuleEngineHdlr` for consistency
   - **Current**: `OnboardingAppRuleEngineHandler`
   - **Note**: Or keep as `Handler` if that's the preferred pattern

2. **VendorProgramGroupMemberTriggerHandler**
   - **Issue**: Should follow `*Hdlr.cls` pattern
   - **Current**: `VendorProgramGroupMemberTriggerHandler`
   - **Location**: `/force-app/main/default/classes/handlers/VendorProgramGroupMemberTriggerHandler.cls`

## Code Quality Improvements

### ✅ COMPLETED: Magic Numbers Replaced with Constants

1. ✅ **Constants.cls** - CREATED
   - Created shared constants class for magic numbers
   - Location: `/force-app/main/default/classes/util/Constants.cls`
   - Constants defined:
     - `MILLISECONDS_TO_SECONDS = 1000.0`
     - `DEFAULT_BATCH_SIZE = 200`
     - `DEFAULT_QUERY_LIMIT = 100`
     - `DEFAULT_WORK_DURATION = 60`

2. ✅ **OrgWideEmailSyncService** - UPDATED
   - Replaced magic number `1000.0` with `Constants.MILLISECONDS_TO_SECONDS`

3. ✅ **EmailTemplateSyncService** - UPDATED
   - Replaced magic number `1000.0` with `Constants.MILLISECONDS_TO_SECONDS`

4. ✅ **EmailSyncSummaryDTO** - UPDATED
   - Replaced magic number `1000.0` with `Constants.MILLISECONDS_TO_SECONDS`

## Additional Refactorings Completed

### ✅ COMPLETED: Service Layer Refactoring (SRP)

**VendorOnboardingWizardService** ✅ REFACTORED
- **Previous Violation**: Monolithic service with 60+ methods, 900+ lines, violating Single Responsibility Principle
- **Fix Applied**: Split into 8 domain-specific services:
  - `VendorService`
  - `VendorProgramService`
  - `VendorProgramGroupService`
  - `VendorProgramRequirementGroupService`
  - `VendorProgramRequirementService`
  - `OnboardingRequirementSetService`
  - `RecipientGroupService`
  - `StatusRulesEngineService`
  - `CommunicationTemplateService`
- **Status**: ✅ `VendorOnboardingWizardService` now acts as facade, maintaining backward compatibility

### ✅ COMPLETED: Centralized Utilities (DRY)

**New Utility Classes Created**:
1. ✅ **ValidationHelper** - Centralized input validation
2. ✅ **DefaultValueHelper** - Centralized default value assignment
3. ✅ **PicklistHelper** - Centralized picklist value retrieval
4. ✅ **StageCompletionConfig** - Centralized stage completion configuration

**Status**: ✅ All services, orchestrators, and controllers now use these utilities

### ✅ COMPLETED: Strategy Pattern Implementation (OCP)

**New Strategy Classes Created**:
1. ✅ **ActivationStrategy** interface and implementations
2. ✅ **EmailSenderStrategy** interface and implementations
3. ✅ **ActivationStrategyFactory** - Strategy factory for activation
4. ✅ **EmailSenderStrategyFactory** - Strategy factory for email sending

**Refactored Classes**:
1. ✅ **OnboardingAppActivationOrchestrator** - Now uses strategy pattern
2. ✅ **EmailCommSenderService** - Now uses strategy pattern
3. ✅ **OnboardingApplicationService** - Uses `StageCompletionConfig` for component checks

**Status**: ✅ All OCP violations fixed, code now extensible without modification

## Summary Statistics

- **Total Violations**: 30+ (originally)
- **Directory Organization**: ✅ COMPLETED - All 19 classes moved
- **Service Layer Pattern**: ✅ COMPLETED - All 10 services refactored to use repositories
- **Sharing Model**: ✅ COMPLETED - All classes now use `with sharing`
- **Magic Numbers**: ✅ COMPLETED - Replaced with constants
- **Service Refactoring**: ✅ COMPLETED - Monolithic service split into 8 domain services (SRP)
- **Utility Centralization**: ✅ COMPLETED - 4 new utility classes created (DRY)
- **Strategy Pattern**: ✅ COMPLETED - 2 strategy patterns implemented (OCP)
- **Naming Conventions**: 2 classes need renaming (low priority)

## Priority Recommendations

### ✅ High Priority - COMPLETED
1. ✅ Refactor `OnboardingApplicationService` to use repository pattern
2. ✅ Refactor `OnboardingRulesService` to use repository pattern
3. ✅ Refactor `OnboardingStatusEvaluator` to use repository pattern

### ✅ Medium Priority - COMPLETED
1. ✅ Move all classes to appropriate subdirectories
2. ✅ Create repository classes for services with direct data access

### Low Priority (Remaining)
1. Rename handler classes for consistency
2. ✅ Create `rules/` directory for validation rules - COMPLETED

## Migration Plan

See [Apex Patterns](./apex-patterns.md#migration-recommendations) for detailed migration recommendations.

