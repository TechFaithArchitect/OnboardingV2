# Display_Label__c Formula Field Fix

## Problem

The `Display_Label__c` field on `Onboarding_Requirement_Set__c` was a formula field:
```
Vendor_Program__r.Label__c & " Requirements - v" & TEXT(Version__c)
```

After removing the `Vendor_Program__c` lookup field and moving to junction objects (`Vendor_Program_Requirement_Set__c`), this formula field no longer works because:
1. Formula fields cannot directly access junction objects
2. The `Vendor_Program__r` relationship no longer exists

## Solution

Convert `Display_Label__c` from a formula field to a **Text field** and populate it via Apex triggers.

### Components Created

1. **OnboardingRequirementSetTrigger.trigger**
   - Triggers on insert/update of `Onboarding_Requirement_Set__c`
   - Populates `Display_Label__c` when requirement set is created or version changes

2. **VendorProgramRequirementSetTrigger.trigger**
   - Triggers on insert/update/delete of junction records
   - Updates `Display_Label__c` when vendor program links change

3. **RequirementSetTriggerHandler.cls**
   - Handler class that contains the logic to populate `Display_Label__c`
   - Handles multiple vendor programs (uses first one alphabetically by Label)
   - Includes recursion prevention

### Display Label Format

**Format**: `{Vendor Program Label} Requirements - v{Version}`

**Examples**:
- `ABC Corp Requirements - v1`
- `XYZ Inc Requirements - v2`
- `Requirements - v1` (if no vendor program linked)

### Behavior

1. **On Requirement Set Creation**:
   - `Display_Label__c` is populated based on linked vendor programs (via junction)
   - If no vendor programs linked yet, shows `Requirements - v1` (or default version)

2. **On Junction Record Creation/Update**:
   - When a vendor program is linked to a requirement set, `Display_Label__c` is updated
   - Uses the first vendor program alphabetically by Label

3. **On Version Change**:
   - If `Version__c` field exists and changes, `Display_Label__c` is updated

4. **Multiple Vendor Programs**:
   - Requirement sets can be linked to multiple vendor programs
   - Display label uses the first vendor program (sorted alphabetically by Label)
   - If you need all vendor programs in the label, this can be customized

## Migration Steps

### Step 1: Convert Field Type in Salesforce

1. Go to Setup → Object Manager → Onboarding Requirement Set
2. Find `Display_Label__c` field
3. Edit the field and change from **Formula** to **Text**
4. Set length to 255 (or appropriate size)
5. Save

### Step 2: Deploy Apex Code

Deploy the following files:
- `force-app/main/default/triggers/OnboardingRequirementSetTrigger.trigger`
- `force-app/main/default/triggers/OnboardingRequirementSetTrigger.trigger-meta.xml`
- `force-app/main/default/triggers/VendorProgramRequirementSetTrigger.trigger`
- `force-app/main/default/triggers/VendorProgramRequirementSetTrigger.trigger-meta.xml`
- `force-app/main/default/classes/handlers/RequirementSetTriggerHandler.cls`
- `force-app/main/default/classes/handlers/RequirementSetTriggerHandler.cls-meta.xml`

### Step 3: Backfill Existing Records

Run this script in Anonymous Apex to backfill existing requirement sets:

```apex
// Backfill Display_Label__c for existing requirement sets
List<Onboarding_Requirement_Set__c> requirementSets = [
    SELECT Id
    FROM Onboarding_Requirement_Set__c
];

// Trigger the update via handler
RequirementSetTriggerHandler.updateDisplayLabelsFromJunction(
    new List<Vendor_Program_Requirement_Set__c>(), 
    null
);

// Alternative: Direct update approach
Set<Id> reqSetIds = new Set<Id>();
for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
    reqSetIds.add(reqSet.Id);
}

// Get vendor programs via junction
Map<Id, String> displayLabels = new Map<Id, String>();
for (Vendor_Program_Requirement_Set__c junction : [
    SELECT Onboarding_Requirement_Set__c, 
           Vendor_Program__r.Label__c,
           Onboarding_Requirement_Set__r.Version__c
    FROM Vendor_Program_Requirement_Set__c
    WHERE Onboarding_Requirement_Set__c IN :reqSetIds
    ORDER BY Vendor_Program__r.Label__c ASC
]) {
    if (!displayLabels.containsKey(junction.Onboarding_Requirement_Set__c)) {
        String version = junction.Onboarding_Requirement_Set__r.Version__c != null 
            ? junction.Onboarding_Requirement_Set__r.Version__c 
            : '1';
        String label = junction.Vendor_Program__r.Label__c != null
            ? junction.Vendor_Program__r.Label__c
            : '';
        displayLabels.put(
            junction.Onboarding_Requirement_Set__c,
            label + ' Requirements - v' + version
        );
    }
}

// Update requirement sets
List<Onboarding_Requirement_Set__c> toUpdate = new List<Onboarding_Requirement_Set__c>();
for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
    if (displayLabels.containsKey(reqSet.Id)) {
        reqSet.Display_Label__c = displayLabels.get(reqSet.Id);
        toUpdate.add(reqSet);
    } else {
        // No vendor program linked - set default
        reqSet.Display_Label__c = 'Requirements - v1';
        toUpdate.add(reqSet);
    }
}

update toUpdate;
```

## Testing Checklist

- [ ] Create new requirement set without vendor program → Display_Label__c = "Requirements - v1"
- [ ] Create new requirement set and link vendor program → Display_Label__c = "{Label} Requirements - v1"
- [ ] Link requirement set to vendor program → Display_Label__c updates
- [ ] Unlink requirement set from vendor program → Display_Label__c updates
- [ ] Update Version__c (if field exists) → Display_Label__c updates
- [ ] Link requirement set to multiple vendor programs → Uses first alphabetically
- [ ] Backfill existing records → All have proper Display_Label__c

## Important Notes

1. **Field Type**: Must be converted from Formula to Text in Salesforce UI before deploying triggers
2. **Version__c Field**: The handler gracefully handles if this field doesn't exist (defaults to "v1")
3. **Recursion Prevention**: Uses static flag to prevent infinite loops
4. **Multiple Vendor Programs**: Currently uses first vendor program alphabetically - can be customized if needed
5. **Performance**: Consider bulkification if dealing with large volumes

## Customization Options

If you need different behavior:

1. **Show All Vendor Programs**: Modify `buildDisplayLabel()` to concatenate all vendor program labels
2. **Different Format**: Modify the format string in `buildDisplayLabel()`
3. **Priority Order**: Change the ORDER BY in the SOQL query to prioritize differently

---

**Status**: ✅ Solution Implemented
**Date**: December 2025
**Version**: 1.0

