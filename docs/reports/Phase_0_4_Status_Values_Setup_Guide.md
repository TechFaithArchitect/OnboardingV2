# Phase 0.4: Status Values Setup Guide

## Overview

To enable partial save and resume functionality, you need to add new status values to the `Onboarding_Requirement__c.Status__c` picklist field.

## Required Status Values

Add the following values to `Onboarding_Requirement__c.Status__c`:

1. **Draft** - User started but hasn't submitted
   - Default: false
   - Description: "User has started filling out fields but hasn't completed the requirement"

2. **Partially_Completed** - Some fields filled, validation pending
   - Default: false
   - Description: "Some fields have been filled but validation is still pending"

3. **Abandoned** - Record has been inactive for extended period
   - Default: false
   - Description: "Onboarding requirement has been inactive for 30+ days"

## Status Flow

```
New → Draft → Partially_Completed → In_Progress → Complete
                                      ↓
                                  Needs_Correction
                                      ↓
                                  Abandoned (via cleanup job)
```

## Setup Steps

1. Go to **Setup** → **Object Manager** → **Onboarding Requirement**
2. Click **Fields & Relationships** → **Status**
3. Click **Edit**
4. In the **Picklist Values** section, click **New**
5. Add each status value:
   - **Draft**
   - **Partially_Completed**
   - **Abandoned**
6. Click **Save**

## Is_Archived__c Field

You also need to add the `Is_Archived__c` field to `Onboarding_Requirement__c`:

**Field Details:**
- **Field Type**: Checkbox
- **Field Label**: Is Archived
- **Field Name**: Is_Archived__c
- **Default Value**: false
- **Description**: "Indicates if this record has been soft-deleted/archived"

## Testing

After adding the status values:

1. Test auto-save functionality
2. Verify status transitions work correctly
3. Test resume panel shows correct progress
4. Test cleanup scheduler archives abandoned records

## Notes

- The cleanup scheduler will automatically mark records as `Abandoned` after 30 days of inactivity
- Auto-save will set status to `Draft` when user starts entering data
- Status will transition to `Partially_Completed` when some fields are filled
- Status will transition to `Complete` when all fields are filled and validated

