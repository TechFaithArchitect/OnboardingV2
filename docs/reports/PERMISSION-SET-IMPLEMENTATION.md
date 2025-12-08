# Permission Set-Based Admin/User Differentiation

## Overview

The Vendor Program Onboarding Wizard now differentiates between **Administrator** and **User** roles using permission sets. This allows Step 9 (Recipient Groups) to be shown only to administrators, while regular users skip directly to Step 10 (Communication Template).

## Permission Sets

Two permission sets are used to define user roles:

1. **Onboarding Application - Administrator** (Label)
   - API Name: `Onboarding_Application_Administrator` (auto-generated)
   - Users with this permission set can:
     - Create new Recipient Groups
     - Add Recipient Group Members
     - Link Recipient Groups to Vendor Programs
     - Access Step 9 in the onboarding wizard

2. **Onboarding Application - User** (Label)
   - API Name: `Onboarding_Application_User` (auto-generated)
   - Regular users without Administrator permission set:
     - Skip Step 9 (Recipient Groups)
     - Proceed directly to Step 10 (Communication Template)
     - Can only select existing Recipient Groups in Step 10

## Implementation Details

### Apex: Permission Set Check

**Location:** `force-app/main/default/classes/util/VendorProgramStatusMapper.cls`

**Method:** `isCurrentUserAdmin()`

```apex
public static Boolean isCurrentUserAdmin() {
    // Check for "Onboarding Application - Administrator" permission set
    // Try both Label and API Name formats
    try {
        List<PermissionSetAssignment> assignments = [
            SELECT Id, PermissionSet.Name, PermissionSet.Label
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
              AND (PermissionSet.Name = 'Onboarding_Application_Administrator' 
                OR PermissionSet.Label = 'Onboarding Application - Administrator')
            LIMIT 1
        ];
        
        if (!assignments.isEmpty()) {
            return true;
        }
    } catch (Exception e) {
        System.debug('Error checking permission set: ' + e.getMessage());
    }
    
    // Fallback: Check for System Administrator profile
    String profileName = ProfileRepository.getProfileNameById(UserInfo.getProfileId());
    if (profileName == 'System Administrator') {
        return true;
    }
    
    return false;
}
```

**Features:**
- Checks both Permission Set Label and API Name
- Falls back to System Administrator profile check
- Returns `false` on error (secure default)

### Apex Controller: Expose Admin Check

**Location:** `force-app/main/default/classes/controllers/VendorOnboardingWizardController.cls`

**Method:** `isCurrentUserAdmin()`

```apex
@AuraEnabled(cacheable=true)
public static Boolean isCurrentUserAdmin() {
    return VendorProgramStatusMapper.isCurrentUserAdmin();
}
```

**Features:**
- Cacheable method for client-side caching
- Used by LWC components to check admin status

### Flow Engine: Skip Step 9 for Non-Admin Users

**Location:** `force-app/main/default/lwc/onboardingFlowEngine/onboardingFlowEngine.js`

**Changes:**

1. **Admin Status Check on Initialization:**
   ```javascript
   async connectedCallback() {
     // Check admin status first, then initialize flow
     await this.checkAdminStatus();
     await this.initializeFlow();
   }
   ```

2. **Skip Step 9 During Initialization:**
   - If user is not admin and current stage is Step 9, automatically skip to Step 10
   - Auto-completes the skipped stage

3. **Skip Step 9 When Navigating Forward:**
   - In `handleNext()`, checks if next stage is Step 9
   - If non-admin, skips to Step 10 and auto-completes Step 9

4. **Skip Step 9 When Navigating Backward:**
   - In `handleBack()`, checks if previous stage is Step 9
   - If non-admin, skips to Step 8 (Status Rules Engine)

### Recipient Group Component: Admin-Only UI

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRecipientGroup/`

**Changes:**

1. **Admin Status Check:**
   ```javascript
   connectedCallback() {
     this.checkAdminStatus();
     if (this.isAdmin) {
       this.loadExistingGroups();
       this.loadAssignableUsers();
     } else {
       // Non-admin users should skip this step - auto-advance to next
       this.handleSkipForNonAdmin();
     }
   }
   ```

2. **Non-Admin Message:**
   - Shows informational message explaining admin access is required
   - Provides "Continue to Next Step" button
   - Explains that regular users skip this step

3. **Auto-Advance:**
   - Non-admin users automatically dispatch `next` event to skip to Step 10

## User Experience

### Administrator Flow

1. **Step 1-8:** Same as User flow
2. **Step 9:** Full Recipient Group management UI
   - View existing groups
   - Create new groups
   - Add members
   - Link to Vendor Program
3. **Step 10:** Select Communication Template, Recipient Group, and trigger condition
4. **Step 10 (Final):** Complete onboarding

### User Flow

1. **Step 1-8:** Same as Admin flow
2. **Step 9:** **SKIPPED** - Shows message and auto-advances
3. **Step 10:** Select Communication Template, Recipient Group (from existing), and trigger condition
4. **Step 10 (Final):** Complete onboarding

## Flow Behavior

### Forward Navigation (Next)

- **Admin:** Proceeds normally through all steps including Step 9
- **User:** Automatically skips Step 9 when navigating from Step 8 to Step 9

### Backward Navigation (Back)

- **Admin:** Can navigate back to Step 9 normally
- **User:** Automatically skips Step 9 when navigating back from Step 10

### Resume/Initialization

- **Admin:** Resumes at saved stage, including Step 9 if that's where they left off
- **User:** If saved progress is at Step 9, automatically advances to Step 10

## Auto-Completion

When Step 9 is skipped for non-admin users:
- The stage is automatically marked as complete
- A completion record is created in `Onboarding_Application_Stage_Completion__c`
- Progress is saved to skip to Step 10

## Error Handling

- If permission set check fails, defaults to non-admin (secure default)
- If admin status check fails during initialization, flow continues with `isAdmin = false`
- All errors are logged to console for debugging

## Testing

To test the implementation:

1. **Assign Permission Set:**
   - Go to Setup → Users → Permission Sets
   - Find "Onboarding Application - Administrator"
   - Assign to a test user

2. **Test Admin Flow:**
   - Log in as user with Administrator permission set
   - Start Vendor Program Onboarding
   - Verify Step 9 shows full Recipient Group management UI

3. **Test User Flow:**
   - Log in as user without Administrator permission set
   - Start Vendor Program Onboarding
   - Verify Step 9 is skipped and shows message
   - Verify flow proceeds directly to Step 10

## Related Documentation

- [Vendor Program Onboarding Flow](./processes/vendor-program-onboarding-flow.md)
- [Vendor Program Onboarding Wizard Components](./components/vendor-program-onboarding-wizard-components.md)
- [Onboarding Workflow Guide](./user-guides/onboarding-workflow.md)

