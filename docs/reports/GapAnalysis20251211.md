Executive review result: End-to-end Onboarding System readiness, gaps, and next steps

Scope assessed
- Data model: Account_Vendor_Program_Onboarding__c (AVO), key fields and relationships
- Apex: VendorOnboardingWizardService (facade), VendorOnboardingWizardController, VendorOnboardingWizardRepository
- LWC: accountProgramOnboardingModal for Account-based onboarding kickoff
- Process architecture docs: Vendor Program Onboarding Flow (10-step), Sharing Model (object-level OWD/Rules for requirement-related objects)

What’s complete (by persona)
1) Sales Reps (Dealer onboarding kickoff)
- End-to-end kickoff is implemented:
  - Eligibility evaluated (NDA + Program Base Application) via repository queries against Onboarding__c.
  - Account Contact Roles retrieved and upserted; Opportunity created with stage defaults; Opportunity Contact Roles inserted.
  - Onboarding__c created and seeded with Onboarding_Requirement__c from Vendor_Program_Requirement__c.
  - AVO created linking Account, Onboarding, and Opportunity with default Status=Intake.
  - LWC modal orchestrates all steps with validation and robust error handling.
- Net: Sales can start onboarding and create all dependent records in one modal.

2) Vendor Program Managers (Program configuration)
- Strong backend capabilities:
  - CRUD/search for Vendors, Vendor Programs, Groups and Requirement Groups, Requirement Sets, Templates (junction model), Recipient Groups and Communication Template linking, Status Rules Engine objects.
  - Admin utilities to sync the Component Library and initialize a default process with ordered stages.
- Metadata-driven flow documented (Component Library + Process + Stages + Flow Engine + Stage Renderer).
- Net: Backend and framework to create/maintain programs are present; ensure corresponding LWCs/Flows exist for each documented step.

3) Onboarding/Compliance Reps (Execution and completion)
- Backend seeding of requirements is present; rules engine scaffolding exists.
- Net: Runtime evaluation hooks and operational UI for requirement progression are not verified in reviewed files and likely need completion/connection.

Notable gaps and risks
A) Sales Rep workflow
- Primary contact designation:
  - OCR creation sets IsPrimary=false for all contacts; there’s no single designated primary.
  - AVO lacks a Primary_Contact__c field. This hampers reporting, handoffs, and downstream automation.
- Eligibility gating uses vendor name:
  - searchVendorProgramsForAccount toggles programs by Vendor__r.Name = 'PerfectVision' vs not—placeholder logic. Should be metadata-driven based on eligibility prerequisites (NDA/Program Base Application) or program-level flags.

B) Vendor Program Manager flow coherence
- Stage/process inconsistency:
  - Code initializes 16 stages; controller copy references “14” components; documentation shows a 10-step flow with some different component names.
  - This undermines admin setup and troubleshooting; choose an authoritative flow and align code/docs/messages.

C) Onboarding/Compliance runtime and UI
- Rules engine invocation:
  - No clear trigger/flow path to evaluate rules after requirement or onboarding updates to drive AVO/Onboarding status transitions.
- Compliance UI:
  - No reviewed LWC/Flow for requirement progression (approve/deny, uploads, validation), escalation, and SLA tracking.

D) AVO object configuration
- enableHistory=false, enableSearch=false. Lacks auditability of Status and global discoverability.
- Sharing ControlledByParent (to Account). May be insufficient for Vendor Program Managers who need org-/region-wide visibility.

E) Security and persona access
- Sharing model documentation covers requirement-related and follow-up objects well but doesn’t explicitly cover AVO access expectations for three personas.
- VendorProgramStatusMapper.isCurrentUserAdmin() assumes a specific permission set. Ensure permission sets exist and reflect least privilege per persona.

F) Data consistency and UX polish
- LWC hard-codes ACR roles; should be sourced from metadata or picklists to avoid drift.
- Validation/lifecycle checks on AVO (e.g., cannot Complete with open requirements) are not present and should be enforced.
- Controller/service copy and stage counts/messages must be consistent.

Recommendations and prioritized next steps

Now (blockers to reliable E2E)
1) Primary contact strategy
- Add AVO.Primary_Contact__c (Lookup(Contact)) with history tracking.
- Update LWC to select exactly one primary contact; update Apex to:
  - Set IsPrimary=true for that OCR and false for others.
  - Mirror selection to AVO.Primary_Contact__c on AVO creation.
- Add validation: AVO requires Primary_Contact__c when Status moved beyond Intake.

2) Eligibility gating refactor to metadata
- Introduce Custom Metadata (e.g., Program_Eligibility_Rule__mdt) or fields on Vendor_Customization__c to indicate required prerequisites (NDA, Program Base, other).
- Replace vendor-name filter with rule evaluation in repository/service:
  - Evaluate Account’s NDA/Base flags once.
  - Return programs allowed by rules; consider a fallback/feature flag for PerfectVision while migrating.
- Add unit tests to cover rule permutations.

3) Stage/process alignment (single source of truth)
- Decide authoritative flow (recommend the documented 10-step set); update:
  - VendorOnboardingWizardService.initializeDefaultVendorProgramOnboardingProcess() to create exactly those steps with matching component API names.
  - Component library sync list to include the 10-step components (e.g., vendorProgramOnboardingRequirementSetOrCreate, vendorProgramOnboardingRequirementGroupLinking, … vendorProgramOnboardingFinalize).
  - Controller messages and any admin UI help text to reflect final count.
- Provide a health-check utility to detect missing/mismatched components/stages.

4) AVO object hardening
- Enable Field History for Status__c, Opportunity__c, and Primary_Contact__c.
- Consider enableSearch=true for ops discoverability.
- Add validation rules:
  - Completed requires zero open Onboarding_Requirement__c.
  - Closed Lost requires Reason_for_Return__c.
  - On Hold optionally requires Reason.

5) Security and persona access sign-off
- Define and implement permission sets:
  - Sales Rep: R/W AVO on visible Accounts, create Opp/OCR, read Program configs.
  - Onboarding/Compliance: R/W Onboarding__c and Requirements; R/W AVO across assigned territory; read Programs.
  - Vendor Program Manager: R/W program configuration objects; org-/region-wide read to AVO; limited Onboarding__c edit.
- If ControlledByParent is insufficient for Vendor PM visibility, add criteria-based sharing or a sharing set based on region/team.
- Confirm “Onboarding Application - Administrator” permission set exists and matches VendorProgramStatusMapper; assign Apex class access and object/field perms.

Next (scale and ops efficiency)
6) Compliance runtime wiring and UI
- Implement trigger/Flow on Onboarding_Requirement__c and related changes to invoke StatusRulesEngineService and update Onboarding__c and AVO.Status__c.
- Build/confirm LWC or Flow screens for requirement progression (file uploads, verification, decisions), with queueing and SLAs.

7) LWC metadata-driven options
- Replace hard-coded ACR roles with:
  - a custom metadata list, or
  - a picklist strategy surfaced via Apex, or
  - retrieval from AccountContactRelation.Roles options if standardized.

8) Admin Console
- Single LWC/Flow to run:
  - Component library sync
  - Process initialization (idempotent)
  - Health checks (components/stages/rules, inactive entries)
  - Post-deployment verifications

Later (robustness, performance, and analytics)
9) Testing and performance
- Add tests for:
  - New eligibility rules
  - AVO lifecycle validations
  - Process initializer idempotency and mismatch repairs
  - Bulk createOnboardingWithRequirements with many templates
- Consider caching metadata lookups for picklists and rule checks.

10) Reporting and dashboards
- Sales: AVO pipeline by Status, Go-Live Target vs Actual, Accounts by Program.
- Vendor PM: Program adoption, time-to-complete, requirement failure hotspots.
- Compliance: aging/overdue requirements, On Hold reasons, SLA breaches.

Complete vs missing matrix (summary)
- Sales Rep kickoff: Implemented; finalize with Primary Contact and eligibility rules.
- Vendor Program configuration: Backend complete; align stages/code/docs and verify admin LWCs/Flows for each step.
- Compliance execution: Foundations present; wire rules engine to runtime and add operational UI.
- Security/sharing: Requirement-related objects documented; finalize AVO access and persona permission sets.
- Reporting/dashboards: To be created.

This plan brings the system to a fully functional end-to-end onboarding platform with robust governance, clear persona access, and operational visibility.
