# Phase 0: Criteria-Based Sharing Rules Setup Guide

## Overview

Create criteria-based sharing rules to expose relevant data to Experience Cloud users (dealers) without manual sharing. These rules automatically share records based on the dealer's Account relationship.

## Important Notes

1. **Account RecordType**: The plan references `RecordType.DeveloperName = 'Dealer'`, but your org may use `'POE_Dealer'`. Verify the actual DeveloperName before creating rules.

2. **Experience Cloud User Context**: Sharing rules use `$User.AccountId` to reference the Experience Cloud user's Account.

3. **Master-Detail Objects**: Objects with Master-Detail relationships (Requirement_Field_Value__c, Requirement_Field__c, Requirement_Field_Group__c) inherit sharing from their parent, so sharing rules may not be needed for these objects. However, we'll create rules for Requirement_Field_Value__c to ensure Experience Cloud users can access their own data.

## Sharing Rules to Create

### 1. Requirement_Field_Value__c - Dealer Access Rule

**Rule Name**: `Requirement_Field_Value_Dealer_Access`

**Rule Type**: Criteria-Based Sharing Rule

**Criteria**:
```
Onboarding_Requirement__r.Onboarding__r.Account__c = $User.AccountId
AND Onboarding_Requirement__r.Onboarding__r.Account__r.RecordType.DeveloperName = 'Dealer'
```

**Note**: If your RecordType DeveloperName is 'POE_Dealer', use that instead.

**Share With**: 
- Public Groups: (None - uses criteria)
- Roles: (None - uses criteria)
- Roles and Subordinates: (None - uses criteria)

**Access Level**: Read/Write

**Description**: Allows Experience Cloud users (dealers) to view and edit their own Requirement Field Values through the parent Onboarding relationship.

### 2. Follow_Up_Queue__c - Dealer Read Access Rule

**Rule Name**: `Follow_Up_Queue_Dealer_Read_Access`

**Rule Type**: Criteria-Based Sharing Rule

**Criteria**:
```
Onboarding__r.Account__c = $User.AccountId
AND Onboarding__r.Account__r.RecordType.DeveloperName = 'Dealer'
```

**Note**: If your RecordType DeveloperName is 'POE_Dealer', use that instead.

**Share With**: 
- Public Groups: (None - uses criteria)
- Roles: (None - uses criteria)
- Roles and Subordinates: (None - uses criteria)

**Access Level**: Read Only

**Description**: Allows Experience Cloud users (dealers) to view (but not edit) their own Follow-Up Queue records.

## Implementation Steps

### Option A: Create via UI (Recommended)

1. **For Requirement_Field_Value__c**:
   - Go to **Setup** → **Object Manager** → **Requirement Field Value**
   - Click **Sharing Settings**
   - Click **New** (in Sharing Rules section)
   - Rule Name: `Requirement_Field_Value_Dealer_Access`
   - Rule Type: **Based on criteria**
   - Criteria:
     - Field: `Onboarding Requirement → Onboarding → Account`
     - Operator: `equals`
     - Value: `$User.AccountId`
   - Add second criteria (AND):
     - Field: `Onboarding Requirement → Onboarding → Account → Record Type`
     - Operator: `equals`
     - Value: `Dealer` (or `POE_Dealer` if that's your DeveloperName)
   - Access Level: **Read/Write**
   - Click **Save**

2. **For Follow_Up_Queue__c**:
   - Go to **Setup** → **Object Manager** → **Follow Up Queue**
   - Click **Sharing Settings**
   - Click **New** (in Sharing Rules section)
   - Rule Name: `Follow_Up_Queue_Dealer_Read_Access`
   - Rule Type: **Based on criteria**
   - Criteria:
     - Field: `Onboarding → Account`
     - Operator: `equals`
     - Value: `$User.AccountId`
   - Add second criteria (AND):
     - Field: `Onboarding → Account → Record Type`
     - Operator: `equals`
     - Value: `Dealer` (or `POE_Dealer` if that's your DeveloperName)
   - Access Level: **Read Only**
   - Click **Save**

### Option B: Deploy via Metadata (Advanced)

If you prefer to deploy via metadata, use the sharing rule files created in `force-app/main/default/sharingRules/`.

**Note**: Criteria-based sharing rules with cross-object relationships and `$User` variables are complex and may need to be created/verified in the UI even if deployed via metadata.

## Testing Checklist

- [ ] Verify Account RecordType DeveloperName (should be 'Dealer' or 'POE_Dealer')
- [ ] Create Requirement_Field_Value__c sharing rule
- [ ] Create Follow_Up_Queue__c sharing rule
- [ ] Test with Experience Cloud user:
  - [ ] Experience Cloud user can see their own Requirement_Field_Value__c records
  - [ ] Experience Cloud user can edit their own Requirement_Field_Value__c records
  - [ ] Experience Cloud user can see their own Follow_Up_Queue__c records (read-only)
  - [ ] Experience Cloud user cannot see other dealers' records
  - [ ] Experience Cloud user cannot edit Follow_Up_Queue__c records

## Troubleshooting

**Issue**: Sharing rule criteria not working
- **Solution**: Verify the relationship path is correct. Use "Show Field Accessibility" to confirm fields are accessible.

**Issue**: `$User.AccountId` is null
- **Solution**: Ensure Experience Cloud users have a Contact with an Account relationship.

**Issue**: RecordType criteria not matching
- **Solution**: Verify the exact DeveloperName. Check Setup → Object Manager → Account → Record Types.

## Next Steps

After creating sharing rules:
1. Test with Experience Cloud user profiles
2. Document sharing model in architecture docs (Task 0.1.4)
3. Create test classes to validate sharing behavior

