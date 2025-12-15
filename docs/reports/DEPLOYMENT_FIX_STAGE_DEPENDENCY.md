# Deployment Fix: Stage Dependency Viewer

**Date**: January 2025  
**Status**: ✅ **FIXED** - Ready for deployment

---

## Issue

Deployment failed with error:
```
Unable to find Apex action class referenced as 'OnboardingStageDependencyController'.
```

**Root Cause**: The LWC component `onboardingStageDependencyViewer` references an Apex controller that hasn't been deployed yet.

---

## Fixes Applied

### 1. Field Reference Fix
**File**: `force-app/main/default/classes/controllers/OnboardingStageDependencyController.cls`

**Problem**: Controller referenced `Sequence__c` field, but repository query returns `Display_Order__c`.

**Fix**: Updated controller to use `Display_Order__c` instead of `Sequence__c`:
```apex
// Before:
dto.sequence = stage.Sequence__c != null ? Integer.valueOf(stage.Sequence__c) : 0;

// After:
dto.sequence = stage.Display_Order__c != null ? Integer.valueOf(stage.Display_Order__c) : 0;
```

---

## Deployment Order

**IMPORTANT**: Deploy Apex classes **BEFORE** deploying the LWC component.

### Step 1: Deploy Apex Classes

Deploy these classes first (they're dependencies):

```bash
# Deploy controller and its dependencies
sfdx force:source:deploy -p force-app/main/default/classes/controllers/OnboardingStageDependencyController.cls \
  force-app/main/default/classes/repository/OnboardingApplicationRepository.cls \
  force-app/main/default/classes/repository/OnboardingStageDependencyRepository.cls \
  force-app/main/default/classes/util/ValidationHelper.cls
```

**Or deploy all classes at once:**
```bash
sfdx force:source:deploy -p force-app/main/default/classes
```

### Step 2: Deploy LWC Component

After Apex classes are deployed, deploy the LWC:

```bash
sfdx force:source:deploy -p force-app/main/default/lwc/onboardingStageDependencyViewer
```

**Or deploy all LWCs:**
```bash
sfdx force:source:deploy -p force-app/main/default/lwc
```

---

## Dependencies

The `OnboardingStageDependencyController` depends on:

1. ✅ `OnboardingApplicationRepository` - Fetches stages for a process
2. ✅ `OnboardingStageDependencyRepository` - Fetches dependencies and completions
3. ✅ `ValidationHelper` - Validates input parameters

All dependencies exist and are ready to deploy.

---

## Verification

After deployment, verify:

1. ✅ Controller compiles without errors
2. ✅ LWC component can reference the controller
3. ✅ `getStagesWithDependencies` method is accessible
4. ✅ Field references match repository queries

---

## Notes

- The controller uses `Display_Order__c` for sequencing (not `Sequence__c`)
- All repository methods exist and are properly implemented
- The controller is `@AuraEnabled(cacheable=true)` for performance

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Status**: Ready for Deployment ✅

