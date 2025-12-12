# Account Onboarding Review (Dealer / Program Linkage)

## Scope
- Reviewed `docs/processes/account-onboarding-quick-action.md` and onboarding framework docs for expected behavior.
- Audited recent code in `force-app/main/default/lwc/accountProgramOnboardingModal/accountProgramOnboardingModal.js`, `force-app/main/default/classes/repository/VendorOnboardingWizardRepository.cls`, and `force-app/main/default/classes/services/VendorOnboardingWizardService.cls` plus `VendorOnboardingWizardControllerTest.cls`.

## Changes Applied
- `force-app/main/default/lwc/accountProgramOnboardingModal/accountProgramOnboardingModal.js`: Opportunity creation now uses the derived Program Opportunity record type and defaults stage to a valid picklist option when the hardcoded default is not valid. This keeps LWC behavior consistent with metadata-driven record types.

## Findings (ordered by impact)
- `accountProgramOnboardingModal.js`: Prior to the above change, we always sent `recordTypeId = null`, so any Program Opportunity record type logic/picklists were bypassed. Hardcoded stage `Prospecting` could also have been invalid for that record type.
- `VendorOnboardingWizardService.upsertOpportunityContactRole` (and UI usage): Method name implies upsert but it always inserts; repeated modal runs will create duplicate OCR rows. Align naming/behavior.
- `VendorOnboardingWizardRepository.searchVendorProgramsForAccount`: Gating only toggles PerfectVision vs non-PerfectVision; no Active/status filter or NDA/base checks beyond that. Dynamic SOQL string concatenation could be replaced with bound filters for clarity/safety.
- `VendorOnboardingWizardRepository.createOnboardingWithRequirements`: Seeds *all* Vendor_Program_Requirement__c records including inactive/historical. Docs suggest only active requirements should seed; currently not filtered.
- Tests: Apex tests cover basic CRUD plus program search gating, but there is no coverage for `getVendorProgramEligibilityForAccount`, status-rule/history helpers, or the new default/record type behaviors. No Jest tests for the LWC contact/role gating and error toasts.
- UX/perf: ACR/OCR upserts run sequentially; for accounts with many contacts this could be slow. Consider batching to reduce time spent with spinner locked.

## Recommendations / Next Steps
1) Apex hardening: add active/status filters to `searchVendorProgramsForAccount` and `createOnboardingWithRequirements` (e.g., `Status__c = 'Active'`, `Active__c = true`), and switch the vendor filter to a bound condition rather than string concatenation. Update tests to assert these filters.  
2) OCR behavior: either change `upsertOpportunityContactRole` to a true upsert (query existing OCR per contact/opportunity) or rename to `createOpportunityContactRole` and prevent duplicate creation in the UI (e.g., track created OCR ids).  
3) LWC tests: add Jest specs for `accountProgramOnboardingModal` covering eligibility failure toast, disabled Next when roles missing, stage defaulting to picklist, and the successful happy path dispatching `programselected`.  
4) Eligibility coverage: add Apex tests for `getVendorProgramEligibilityForAccount` to verify NDA + Program Base checks and returned messaging.  
5) Requirement seeding rules: filter to active/current templates or requirements before insert; document the rule in `account-onboarding-quick-action.md` to keep behavior explicit.  
6) Performance polish: batch ACR and OCR operations (e.g., Apex methods that accept lists) to cut down round trips during onboarding kickoff.  
7) Documentation sync: note the record-type-aware Opportunity creation and any future gating rules in `docs/processes/account-onboarding-quick-action.md` so admins know what is enforced by the modal.
