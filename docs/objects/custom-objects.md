# Custom Objects

## Core Onboarding Objects

### Onboarding__c

**Purpose**: Central object tracking an onboarding request for a vendor.

**Key Fields:**
- `Name` (Auto-Number) - Onboarding Number
- `Account__c` (Master-Detail to Account) - Vendor account
- `Onboarding_Status__c` (Picklist) - Current status
- `Interview_Status__c` (Picklist) - Interview status
- `Interview__c` (Lookup to Interview__c) - Related interview
- `Vendor_Customization__c` (Lookup) - Related vendor customization

**Relationships:**
- Master-Detail to Account
- Has many Onboarding_Requirement__c
- Has many Onboarding_Order__c

**Sharing**: Controlled by Parent (Account)

**Key Flows:**
- `APP_Onboarding` - Main orchestration
- `Onboarding_Record_Trigger_Update_Onboarding_Status` - Status evaluation

### Vendor_Program__c

**Purpose**: Represents a vendor program configuration.

**Key Fields:**
- `Name` (Text) - Program name
- `Active__c` (Checkbox) - Active status
- `Vendor__c` (Lookup to Account) - Vendor account

**Relationships:**
- Has many Vendor_Program_Group__c
- Has many Vendor_Customization__c
- Has many Onboarding__c (via Vendor_Customization__c)

### Vendor_Program_Group__c

**Purpose**: Groups requirements and rules for a vendor program.

**Key Fields:**
- `Name` (Text) - Group name
- `Vendor_Program__c` (Lookup) - Parent program
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many Vendor_Program_Group_Member__c
- Has many Onboarding_Status_Rules_Engine__c

### Vendor_Program_Group_Member__c

**Purpose**: Members of a vendor program group, linking vendor programs to groups.

**Key Fields:**
- `Vendor_Program_Group__c` (Lookup) - Parent group
- `Required_Program__c` (Lookup) - Required vendor program (Vendor_Customization__c)
- `Required_Customization__c` (Lookup) - Required customization (Vendor_Customization__c)
- `Inherited_Program_Requirement_Group__c` (Lookup) - Inherited requirement group
- `Is_Target__c` (Checkbox) - Whether this is a target program
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Belongs to Vendor_Program_Group__c
- References Vendor_Customization__c (via Required_Program__c or Required_Customization__c)

**Usage**: Used by `getVendorProgramGroupIds()` to find groups associated with a vendor program

### Vendor_Customization__c

**Purpose**: Customization configuration for a vendor program.

**Key Fields:**
- `Name` (Text) - Customization name
- `Vendor_Program__c` (Lookup) - Parent program
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Belongs to Vendor_Program__c
- Has many Onboarding__c

## Requirement Objects

### Onboarding_Requirement__c

**Purpose**: Tracks individual requirements for an onboarding.

**Key Fields:**
- `Name` (Text) - Requirement name
- `Onboarding__c` (Lookup) - Parent onboarding
- `Vendor_Program_Requirement__c` (Lookup) - Requirement definition
- `Status__c` (Picklist) - Status (Not Started, Incomplete, Complete, Approved, Denied)

**Relationships:**
- Belongs to Onboarding__c
- References Vendor_Program_Requirement__c

**Usage**: Used by status evaluation engine

### Vendor_Program_Requirement__c

**Purpose**: Defines requirements for a vendor program.

**Key Fields:**
- `Name` (Text) - Requirement name
- `Vendor_Program__c` (Lookup) - Parent program
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Belongs to Vendor_Program__c
- Referenced by Onboarding_Requirement__c

## Status Rules Objects

### Onboarding_Status_Rules_Engine__c

**Purpose**: Defines a rules engine for status evaluation.

**Key Fields:**
- `Name` (Text) - Rules engine name
- `Vendor_Program_Group__c` (Lookup) - Associated program group
- `Target_Onboarding_Status__c` (Text) - Status to set when rule passes
- `Evaluation_Logic__c` (Picklist) - Logic type (ALL, ANY, CUSTOM)
- `Custom_Evaluation_Logic__c` (Text) - Custom expression

**Relationships:**
- Belongs to Vendor_Program_Group__c
- Has many Onboarding_Status_Rule__c

**Usage**: Used by status evaluation engine

### Onboarding_Status_Rule__c

**Purpose**: Individual rule conditions within a rules engine.

**Key Fields:**
- `Name` (Text) - Rule name
- `Parent_Rule__c` (Lookup) - Parent rules engine
- `Requirement__c` (Lookup) - Requirement to evaluate
- `Expected_Status__c` (Text) - Expected requirement status
- `Rule_Number__c` (Number) - Order of evaluation

**Relationships:**
- Belongs to Onboarding_Status_Rules_Engine__c
- References Vendor_Program_Requirement__c

**Usage**: Used in rule evaluation logic

## Application Framework Objects

### Onboarding_Application_Process__c

**Purpose**: Defines a reusable onboarding flow process.

**Key Fields:**
- `Name` (Text) - Process name
- `Description__c` (Text) - Process description
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many Onboarding_Application_Stage__c
- Has many Onboarding_Application_Progress__c

### Onboarding_Application_Stage__c

**Purpose**: Defines a stage within an onboarding process.

**Key Fields:**
- `Name` (Text) - Stage name
- `Onboarding_Application_Process__c` (Lookup) - Parent process
- `Onboarding_Component_Library__c` (Lookup) - Component to render
- `Display_Order__c` (Number) - Order in flow
- `Label__c` (Text) - Display label
- `Required__c` (Checkbox) - Whether stage is required
- `Next_Stage__c` (Lookup) - Next stage (for branching)

**Relationships:**
- Belongs to Onboarding_Application_Process__c
- References Onboarding_Component_Library__c
- Self-referential for branching

### Onboarding_Component_Library__c

**Purpose**: Maps LWC components to metadata.

**Key Fields:**
- `Name` (Text) - Component name
- `Component_API_Name__c` (Text) - LWC component API name
- `Description__c` (Text) - Component description

**Relationships:**
- Referenced by Onboarding_Application_Stage__c

### Onboarding_Application_Progress__c

**Purpose**: Tracks user progress through an onboarding process.

**Key Fields:**
- `Onboarding_Application_Process__c` (Lookup) - Process being executed
- `Vendor_Program__c` (Lookup) - Vendor program being onboarded
- `Current_Stage__c` (Lookup) - Current stage

**Relationships:**
- Belongs to Onboarding_Application_Process__c
- References Vendor_Program__c
- References Onboarding_Application_Stage__c

### Onboarding_Application_Stage_Completion__c

**Purpose**: Audit log of completed stages.

**Key Fields:**
- `Vendor_Program__c` (Lookup) - Vendor program
- `Onboarding_Application_Process__c` (Lookup) - Process
- `Onboarding_Application_Stage__c` (Lookup) - Completed stage
- `Completed_Date__c` (DateTime) - Completion timestamp
- `Completed_By__c` (Lookup to User) - User who completed

**Relationships:**
- References Vendor_Program__c
- References Onboarding_Application_Process__c
- References Onboarding_Application_Stage__c

### Onboarding_Application_Stage_Dependency__c

**Purpose**: Defines dependency rules between onboarding stages. Uses a Campaign/Campaign Member pattern to allow flexible dependency management that persists even when stage orders change.

**Key Fields:**
- `Name` (Text, 80) - Dependency rule name
- `Logic_Type__c` (Picklist) - Evaluation logic: ALL (all members must be complete), ANY (at least one member must be complete), or CUSTOM (custom logic)
- `Required__c` (Checkbox) - Whether this dependency is required
- `Required_Stage__c` (Lookup to Onboarding_Application_Stage__c) - The stage that has dependencies (legacy field, may be deprecated)
- `Target_Stage__c` (Lookup to Onboarding_Application_Stage__c) - The stage that requires dependencies to be met before it can be started

**Relationships:**
- Has many Onboarding_App_Stage_Dependency_Member__c (Master-Detail)
- References Onboarding_Application_Stage__c (via Required_Stage__c and Target_Stage__c)

**Usage**: 
- Used to enforce that certain stages must be completed before others can be started
- The Campaign/Campaign Member pattern allows long-term reference even if stage orders change
- Logic_Type__c determines how multiple dependency members are evaluated (ALL vs ANY)

**Best Practices:**
- Use descriptive names like "Vendor Selection Required Before Program Setup"
- Set Target_Stage__c to the stage that requires dependencies
- Use ALL logic when all dependencies must be met, ANY when at least one is sufficient

### Onboarding_App_Stage_Dependency_Member__c

**Purpose**: Individual required stages within a dependency rule. Acts as the "Campaign Member" in the Campaign/Campaign Member pattern.

**Key Fields:**
- `Name` (Auto Number) - Auto-generated member identifier
- `Dependency__c` (Master-Detail to Onboarding_Application_Stage_Dependency__c) - Parent dependency rule
- `Required_Stage__c` (Lookup to Onboarding_Application_Stage__c) - The stage that must be completed
- `Required__c` (Checkbox) - Whether this specific member is required (allows optional dependencies)

**Relationships:**
- Belongs to Onboarding_Application_Stage_Dependency__c (Master-Detail)
- References Onboarding_Application_Stage__c (via Required_Stage__c)

**Usage:**
- Each member represents one stage that must be completed
- Multiple members can be added to a single dependency rule
- The parent dependency's Logic_Type__c determines how members are evaluated together

**Best Practices:**
- Add one member per required stage
- Use Required__c to mark optional dependencies (though Logic_Type__c on parent typically handles this)

## Training Objects

### Training_Requirement__c

**Purpose**: Defines training requirements.

**Key Fields:**
- `Name` (Text) - Requirement name
- `Training_System__c` (Lookup) - Training system
- `Active__c` (Checkbox) - Active status

**Relationships:**
- References Training_System__c

### Training_Assignment__c

**Purpose**: Tracks training assignments to contacts.

**Key Fields:**
- `Name` (Text) - Assignment name
- `Contact__c` (Lookup) - Assigned contact
- `Training_Requirement__c` (Lookup) - Training requirement
- `Status__c` (Picklist) - Assignment status

**Relationships:**
- Belongs to Contact
- References Training_Requirement__c

### Training_System__c

**Purpose**: Defines training systems.

**Key Fields:**
- `Name` (Text) - System name
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many Training_Requirement__c

### TrainingAssignmentCredential__c

**Purpose**: Links training assignments to credentials.

**Key Fields:**
- `Training_Assignment__c` (Lookup) - Training assignment
- `POE_External_Contact_Credential__c` (Lookup) - Credential
- `Unique_Key__c` (Text) - Unique identifier

**Relationships:**
- References Training_Assignment__c
- References POE_External_Contact_Credential__c

## Credential Objects

### External_Contact_Credential_Type__c

**Purpose**: Defines types of credentials for external contacts.

**Key Fields:**
- `Name` (Text) - Credential type name
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many POE_External_Contact_Credential__c

**Duplicate Prevention**: Matching rule prevents duplicates

### POE_External_Contact_Credential__c

**Purpose**: Tracks credentials for external contacts.

**Key Fields:**
- `Name` (Text) - Credential name
- `Contact__c` (Lookup) - Contact
- `External_Contact_Credential_Type__c` (Lookup) - Credential type
- `Status__c` (Picklist) - Credential status
- `Unique_Key__c` (Text) - Unique identifier (auto-generated)

**Relationships:**
- Belongs to Contact
- References External_Contact_Credential_Type__c

**Duplicate Prevention**: Matching rule prevents duplicates per contact/type

### Required_Credential__c

**Purpose**: Defines required credentials for programs.

**Key Fields:**
- `Name` (Text) - Requirement name
- `Credential_Type__c` (Lookup) - Required credential type
- `Active__c` (Checkbox) - Active status

**Relationships:**
- References External_Contact_Credential_Type__c

### Required_External_Contact_Credential__c

**Purpose**: Links required credentials to vendor programs.

**Key Fields:**
- `Vendor_Program__c` (Lookup) - Vendor program
- `Required_Credential__c` (Lookup) - Required credential

**Relationships:**
- References Vendor_Program__c
- References Required_Credential__c

### External_Credential_Type_Dependency__c

**Purpose**: Defines dependencies between credential types.

**Key Fields:**
- `Credential_Type__c` (Lookup) - Credential type
- `Dependent_Credential_Type__c` (Lookup) - Dependent credential type

**Relationships:**
- References External_Contact_Credential_Type__c (self-referential)

## ECC Configuration Objects

### ECC_Field_Configuration_Group__c

**Purpose**: Groups field configurations for ECC forms.

**Key Fields:**
- `Name` (Text) - Group name
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many ECC_Field_Configuration_Group_Mapping__c

### ECC_Field_Display_Configuration__c

**Purpose**: Defines how fields are displayed in ECC forms.

**Key Fields:**
- `Name` (Text) - Configuration name
- `Field_API_Name__c` (Text) - Salesforce field API name
- `Display_Label__c` (Text) - Display label
- `Required__c` (Checkbox) - Whether field is required
- `Display_Order__c` (Number) - Order in form

**Relationships:**
- Referenced by ECC_Field_Configuration_Group_Mapping__c

### ECC_Field_Configuration_Group_Mapping__c

**Purpose**: Maps field configurations to groups.

**Key Fields:**
- `ECC_Field_Configuration_Group__c` (Lookup) - Configuration group
- `ECC_Field_Display_Configuration__c` (Lookup) - Field configuration

**Relationships:**
- Belongs to ECC_Field_Configuration_Group__c
- References ECC_Field_Display_Configuration__c

## Order Objects

### Onboarding_Order__c

**Purpose**: Tracks orders related to onboarding.

**Key Fields:**
- `Name` (Text) - Order name
- `Onboarding__c` (Lookup) - Parent onboarding
- `Status__c` (Picklist) - Order status

**Relationships:**
- Belongs to Onboarding__c

## Related Documentation

- [Data Model](../architecture/data-model.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Status Evaluation](../processes/status-evaluation.md)
