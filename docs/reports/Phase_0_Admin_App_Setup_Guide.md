# Phase 0.2: Onboarding Admin Lightning App Setup Guide

## Overview

Create a centralized admin console for onboarding operations with comprehensive visibility and control over validations, follow-ups, and sync errors.

## App Configuration

### Step 1: Create Lightning App

1. Go to **Setup** → **App Manager**
2. Click **New Lightning App**
3. **App Information**:
   - App Name: `Onboarding Admin`
   - Developer Name: `Onboarding_Admin`
   - Description: `Centralized admin console for onboarding operations, validation monitoring, and system health`
   - App Image: (Optional - upload custom logo)
   - Utility: (Leave default)
4. Click **Next**

### Step 2: Configure App Navigation

**Navigation Items** (in order):

1. **Dashboard** (Lightning Page)
   - Type: Lightning Page
   - Lightning Page: `Onboarding_Admin_Dashboard` (to be created)
   - Icon: `utility:dashboard`
   - Label: `Dashboard`

2. **Validation Failures** (Lightning Page)
   - Type: Lightning Page
   - Lightning Page: `Onboarding_Admin_Validation_Failures` (to be created)
   - Icon: `utility:error`
   - Label: `Validation Failures`

3. **Messaging Issues** (Lightning Page)
   - Type: Lightning Page
   - Lightning Page: `Onboarding_Admin_Messaging_Issues` (to be created)
   - Icon: `utility:message`
   - Label: `Messaging Issues`

4. **Adobe Sync Failures** (Lightning Page)
   - Type: Lightning Page
   - Lightning Page: `Onboarding_Admin_Adobe_Failures` (to be created)
   - Icon: `utility:sync`
   - Label: `Adobe Sync Failures`

5. **Configuration** (Lightning Page)
   - Type: Lightning Page
   - Lightning Page: `Onboarding_Admin_Configuration` (to be created)
   - Icon: `utility:settings`
   - Label: `Configuration`

6. **Testing** (Lightning Page)
   - Type: Lightning Page
   - Lightning Page: `Onboarding_Admin_Testing` (to be created)
   - Icon: `utility:test`
   - Label: `Testing`

7. **Override Audit** (Object Tab)
   - Type: Object Tab
   - Object: `Onboarding_External_Override_Log__c` (to be created in Phase 4)
   - Icon: `utility:audit`
   - Label: `Override Audit`

**Utility Items** (optional):
- Add standard utilities (Notifications, etc.)

### Step 3: Assign App to Users

1. **App Options**:
   - Select user profiles or permission sets
   - Recommended: Create permission set `Onboarding_Admin_Access`
   - Assign to System Administrators and Onboarding Admins

2. Click **Save** and **Finish**

## Lightning Pages to Create

Each tab will use a Lightning Page with the corresponding LWC component:

1. **Onboarding_Admin_Dashboard** → Uses `onboardingAdminDashboard` LWC
2. **Onboarding_Admin_Validation_Failures** → Uses `validationFailuresTab` LWC
3. **Onboarding_Admin_Messaging_Issues** → Uses `messagingIssuesTab` LWC
4. **Onboarding_Admin_Adobe_Failures** → Uses `adobeSyncFailuresTab` LWC
5. **Onboarding_Admin_Configuration** → Uses configuration components (to be created)
6. **Onboarding_Admin_Testing** → Uses `validationRuleTester` and `ruleTestHarness` LWC

## Permission Set

Create permission set: `Onboarding_Admin_Access`

**Object Permissions**:
- Requirement_Field__c: Read, Create, Edit, Delete
- Requirement_Field_Value__c: Read, Create, Edit, Delete
- Requirement_Field_Group__c: Read, Create, Edit, Delete
- Follow_Up_Queue__c: Read, Create, Edit, Delete
- Validation_Failure__c: Read, Create, Edit, Delete (to be created)
- AdobeSyncFailure__c: Read, Create, Edit, Delete (to be created)
- Onboarding_External_Override_Log__c: Read (to be created in Phase 4)

**Field Permissions**:
- Grant access to all fields on above objects

**Custom Permissions**:
- `Onboarding_Test_Mode` (to be created)

## Next Steps

After creating the app:
1. Create Lightning Pages for each tab
2. Build LWC components for each tab
3. Test app navigation and permissions
4. Assign to admin users

