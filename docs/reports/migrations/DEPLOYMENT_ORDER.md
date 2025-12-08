# Deployment Order Guide

## Important: Deploy Objects Before Classes

The junction objects **must be deployed before** the Apex classes that reference them, otherwise you'll get compilation errors like:

- `No such column 'Requirement_Template__c' on entity 'Requirement_Set_Template__c'`
- `No such column 'Active__c' on entity 'Vendor_Program_Requirement_Set__c'`

## Correct Deployment Order

### Option 1: Deploy Everything Together (Recommended)

```bash
sfdx force:source:deploy -p force-app/main/default
```

This deploys all metadata in the correct order automatically.

### Option 2: Deploy Objects First, Then Classes

**Step 1: Deploy Objects and Fields**
```bash
sfdx force:source:deploy -p force-app/main/default/objects
```

**Step 2: Deploy Classes**
```bash
sfdx force:source:deploy -p force-app/main/default/classes
```

## What Gets Deployed

### Objects (Deploy First)
- `Requirement_Set_Template__c` object + fields
- `Vendor_Program_Requirement_Set__c` object + fields

### Classes (Deploy After Objects)
- `RequirementSetTemplateService.cls`
- `VendorProgramRequirementSetService.cls`
- Updated `VendorOnboardingWizardRepository.cls`
- All dependent classes that reference the junction objects

## Verification

After deployment, verify the objects exist:

```bash
sfdx force:data:soql:query -q "SELECT Id, SObjectType FROM EntityDefinition WHERE QualifiedApiName IN ('Requirement_Set_Template__c', 'Vendor_Program_Requirement_Set__c')"
```

Verify the fields exist:

```bash
sfdx force:data:soql:query -q "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Requirement_Set_Template__c'"
```

## Troubleshooting

If you still get errors after deploying in order:

1. **Check field API names**: Ensure they match exactly (case-sensitive)
   - `Requirement_Template__c` (not `RequirementTemplate__c`)
   - `Onboarding_Requirement_Set__c` (not `OnboardingRequirementSet__c`)

2. **Refresh metadata**: Sometimes Salesforce needs a moment to recognize new objects
   ```bash
   sfdx force:source:retrieve -p force-app/main/default/objects/Requirement_Set_Template__c
   ```

3. **Clear cache**: If using VS Code, reload the window after deploying objects

4. **Verify permissions**: Ensure your user has access to create custom objects and fields

