# Phase 0.5: Custom Metadata Type Setup Guide

## Overview
This guide provides step-by-step instructions for creating the Custom Metadata Type needed for the Validation Rule Builder.

**Note**: Adobe Sign/EchoSign managed package handles all form mapping (Data Mapping: Adobe → Salesforce, Merge Mapping: Salesforce → Adobe), so no custom Form Mapping Builder or Custom Metadata Type is needed.

## Important: Custom Metadata Type Limitations
- **Custom Metadata Types CANNOT have lookup relationships to custom objects**
- Use **Text(18)** fields to store record IDs when you need to reference custom objects
- Custom Metadata Types CAN have:
  - Metadata relationships (to other Custom Metadata Types)
  - Lookup to User (standard object only)
  - All standard field types (Text, Number, Picklist, Checkbox, etc.)

---

## 1. Requirement_Field_Validation_Rule__mdt

### Object Setup
1. Go to **Setup** → **Custom Code** → **Custom Metadata Types**
2. Click **New Custom Metadata Type**
3. Configure:
   - **Label**: `Requirement Field Validation Rule`
   - **Plural Label**: `Requirement Field Validation Rules`
   - **Object Name**: `Requirement_Field_Validation_Rule`
   - **Description**: `Stores validation rules for requirement fields. Used by the Validation Rule Builder to configure field-level validation without code deployments.`

### Fields to Create

#### 1. MasterLabel (Standard - Auto-created)
- **Type**: Text(255)
- **Required**: Yes
- **Description**: Display name of the validation rule

#### 2. DeveloperName (Standard - Auto-created)
- **Type**: Text(255)
- **Required**: Yes
- **Description**: Unique API name (auto-generated from label)

#### 3. Description__c
- **Type**: Long Text Area (32768)
- **Required**: No
- **Description**: Detailed description of what the validation rule does

#### 4. Validation_Type__c
- **Type**: Picklist
- **Required**: Yes
- **Values**:
  - `Format` (Default)
  - `Cross-Field`
  - `External`
- **Description**: Type of validation (Format check, Cross-field validation, External service validation)

#### 5. Validation_Expression__c
- **Type**: Long Text Area (32768)
- **Required**: Yes
- **Description**: The validation expression (e.g., REGEX formula, logical expression)

#### 6. Error_Message__c
- **Type**: Long Text Area (32768)
- **Required**: Yes
- **Description**: Error message displayed when validation fails (supports field variable substitution)

#### 7. Validation_Mode__c
- **Type**: Picklist
- **Required**: Yes
- **Default**: `Active`
- **Values**:
  - `Active` (Default)
  - `Test`
  - `Disabled`
- **Description**: Mode of the validation rule (Active = enforced, Test = test mode, Disabled = not active)

#### 8. Requirement_Field__c
- **Type**: Text(18)
- **Required**: No
- **Description**: ID of the specific Requirement_Field__c record this rule applies to (optional - can be global). Stored as text since Custom Metadata Types cannot have lookups to custom objects.

#### 9. External_Service__c
- **Type**: Text(255)
- **Required**: No
- **Description**: External service identifier (if Validation_Type__c = External)

#### 10. Is_Active__c
- **Type**: Checkbox
- **Required**: No
- **Default**: `true`
- **Description**: Whether the rule is currently active

#### 11. Sequence__c
- **Type**: Number(18,0)
- **Required**: No
- **Description**: Order in which rules should be evaluated

#### 12. Created_By__c
- **Type**: Text(18)
- **Required**: No
- **Description**: User ID of the user who created the rule (stored as text)

#### 13. Last_Modified_By__c
- **Type**: Text(18)
- **Required**: No
- **Description**: User ID of the user who last modified the rule (stored as text)

### Relationships
- **None required** (standalone metadata type)

### Deployment Settings
- **Protected Component**: No (can be deployed in unmanaged packages)
- **Visibility**: Public

---

## Note on Adobe Integration

**Adobe Sign/EchoSign Managed Package handles all form mapping:**
- **Data Mapping**: Adobe → Salesforce (fields from Adobe forms merged into Salesforce records)
- **Merge Mapping**: Salesforce → Adobe (fields from Salesforce sent to Adobe documents)
- The managed package provides these mapping capabilities natively, so no custom Form Mapping Builder is needed.

---

## 2. After Creating Custom Metadata Type

### Next Steps:
1. **Deploy the Custom Metadata Type** to your org
2. **Create sample records** (optional) to test the builder component
3. **Update field-level security** if needed (Custom Metadata Types are typically public)
4. **Test the Validation Rule Builder** component with a sample rule

### Testing Checklist:
- [ ] Can create a new validation rule via the builder
- [ ] Can edit an existing validation rule
- [ ] Expression validation works
- [ ] Test panel works with sample data
- [ ] Rules can be saved to Custom Metadata
- [ ] Rules appear in the Validation Rule Tester

---

## Notes

### Custom Metadata Type Limitations:
- Custom Metadata Types cannot be created/updated via standard DML (INSERT/UPDATE)
- Must use Metadata API or Tooling API
- The Apex service will need to use `Metadata.Operations` API

### Alternative Approach (If Metadata API is complex):
- Use a **proxy custom object** (`Validation_Rule__c`) that admins can edit
- Create a scheduled job or flow that syncs proxy object → Custom Metadata Type
- This allows admins to use standard UI while still deploying as metadata

---

## Field Naming Convention
All custom fields use the `__c` suffix as per Salesforce standards.

## API Names
- Custom Metadata Type: `Requirement_Field_Validation_Rule__mdt`
- All fields use the naming convention shown above

