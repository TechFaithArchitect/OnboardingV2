import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getEligibility from '@salesforce/apex/VendorOnboardingWizardController.getVendorProgramEligibilityForAccount';
import searchPrograms from '@salesforce/apex/VendorOnboardingWizardController.searchVendorProgramsForAccount';
import getContactsWithRoles from '@salesforce/apex/VendorOnboardingWizardController.getAccountContactsWithRoles';
import upsertAcr from '@salesforce/apex/VendorOnboardingWizardController.upsertAccountContactRelation';
import createOpp from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingOpportunity';
import upsertOcr from '@salesforce/apex/VendorOnboardingWizardController.upsertOpportunityContactRole';
import createOnboardingWithReqs from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingWithRequirements';
import createAvo from '@salesforce/apex/VendorOnboardingWizardController.createAccountVendorProgramOnboarding';
// Using static options for ACR Roles (standard Roles field is not exposed via schema here)

export default class AccountProgramOnboardingModal extends LightningElement {
    @api recordId; // Account Id
    @api onboardingRefId; // optional, if you have an existing onboarding record

    @track eligibilityMessage;
    @track eligibilityPassed = false;
    @track programOptions = [];
    @track selectedProgramId = '';
    @track searchText = '';
    @track isLoading = false;
    @track contacts = [];
    @track acrRoleOptions = [];

    @track oppName = '';
    @track oppStage = 'Prospecting';
    @track oppCloseDate;

    connectedCallback() {
        this.loadEligibility();
        this.loadAcrRolePicklist();
        this.loadContacts();
        this.oppCloseDate = this.computeDefaultCloseDate();
    }

    get disableSearch() {
        return this.isLoading || !this.searchText || this.searchText.trim().length < 2;
    }

    get disableNext() {
        const contactsMissingRole = this.contacts.some(c => !c.role);
        return (
            this.isLoading ||
            !this.selectedProgramId ||
            contactsMissingRole ||
            !this.oppName ||
            !this.oppStage ||
            this.contacts.length === 0
        );
    }

    async loadEligibility() {
        this.isLoading = true;
        try {
            const result = await getEligibility({ accountId: this.recordId });
            this.eligibilityPassed = result?.eligibilityPassed || false;
            this.eligibilityMessage = result?.message;
        } catch (error) {
            this.eligibilityMessage = 'Unable to load eligibility. Please retry.';
            // keep eligibilityPassed as false so only PerfectVision is returned
            console.error('Eligibility error', error);
        } finally {
            this.isLoading = false;
        }
    }

    async loadContacts() {
        try {
            const results = await getContactsWithRoles({ accountId: this.recordId });
            this.contacts = results?.map(r => ({
                contactId: r.contactId,
                name: r.name,
                email: r.email,
                role: r.role,
                hasAcr: r.hasAcr
            })) || [];
        } catch (error) {
            console.error('Contact load error', error);
            this.contacts = [];
        }
    }

    loadAcrRolePicklist() {
        this.acrRoleOptions = [
            { label: 'Principal Owner', value: 'Principal Owner' },
            { label: 'Owner', value: 'Owner' },
            { label: 'Authorized Signer', value: 'Authorized Signer' },
            { label: 'Other', value: 'Other' }
        ];
    }

    handleSearchChange(event) {
        this.searchText = event.target.value;
    }

    async handleSearch() {
        if (this.disableSearch) {
            return;
        }
        this.isLoading = true;
        try {
            const programs = await searchPrograms({
                accountId: this.recordId,
                vendorProgramNameSearchText: this.searchText.trim(),
                eligibilityPassed: this.eligibilityPassed
            });
            this.programOptions = programs.map(p => ({
                label: `${p.Name} (${p.Vendor__r?.Name || 'Vendor'})`,
                value: p.Id
            }));
            if (!this.programOptions.length) {
                this.selectedProgramId = '';
            }
        } catch (error) {
            console.error('Program search error', error);
            this.programOptions = [];
            this.selectedProgramId = '';
        } finally {
            this.isLoading = false;
        }
    }

    handleProgramChange(event) {
        this.selectedProgramId = event.detail.value;
    }

    handleContactRoleChange(event) {
        const contactId = event.target.dataset.contactId;
        const value = event.detail.value;
        this.contacts = this.contacts.map(c => c.contactId === contactId ? { ...c, role: value } : c);
    }

    handleOppNameChange(event) {
        this.oppName = event.target.value;
    }

    handleOppStageChange(event) {
        this.oppStage = event.target.value;
    }

    handleOppCloseDateChange(event) {
        this.oppCloseDate = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleNext() {
        if (this.disableNext) {
            return;
        }
        this.isLoading = true;
        try {
            // Upsert ACRs
            for (const c of this.contacts) {
                await upsertAcr({ accountId: this.recordId, contactId: c.contactId, role: c.role });
            }

            // Create Opportunity
            const oppId = await createOpp({
                accountId: this.recordId,
                name: this.oppName,
                stageName: this.oppStage,
                closeDate: this.oppCloseDate,
                recordTypeId: null
            });

            // Create OCRs for each contact with role
            for (const c of this.contacts) {
                await upsertOcr({
                    opportunityId: oppId,
                    contactId: c.contactId,
                    role: c.role,
                    isPrimary: false
                });
            }

            // Create Onboarding with seeded requirements
            const onboardingResult = await createOnboardingWithReqs({
                accountId: this.recordId,
                vendorProgramId: this.selectedProgramId,
                opportunityId: oppId
            });

            // Create AVO (always) linking Account, Onboarding, Opportunity
            const avoId = await createAvo({
                accountId: this.recordId,
                onboardingId: onboardingResult.onboardingId,
                opportunityId: oppId,
                status: 'Intake'
            });

            const detail = {
                selectedProgramId: this.selectedProgramId,
                eligibilityPassed: this.eligibilityPassed,
                opportunityId: oppId,
                accountVendorProgramOnboardingId: avoId,
                onboardingId: onboardingResult.onboardingId
            };
            this.dispatchEvent(new CustomEvent('programselected', { detail, bubbles: true, composed: true }));
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            console.error('Next handler error', error);
        } finally {
            this.isLoading = false;
        }
    }

    computeDefaultCloseDate() {
        const today = new Date();
        const future = new Date();
        future.setDate(today.getDate() + 14);
        return future.toISOString().slice(0, 10);
    }
}
