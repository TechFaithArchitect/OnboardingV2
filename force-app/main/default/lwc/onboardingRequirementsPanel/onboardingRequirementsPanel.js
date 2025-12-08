import { LightningElement, api, track } from 'lwc';
import getRequirements from '@salesforce/apex/OnboardingRequirementsPanelController.getRequirements';
import getInvalidFieldValues from '@salesforce/apex/OnboardingRequirementsPanelController.getInvalidFieldValues';
import updateRequirementStatuses from '@salesforce/apex/OnboardingRequirementsPanelController.updateRequirementStatuses';
import runRuleEvaluation from '@salesforce/apex/OnboardingRequirementsPanelController.runRuleEvaluation';
import rerunValidation from '@salesforce/apex/OnboardingRequirementsPanelController.rerunValidation';

export default class OnboardingRequirementsPanel extends LightningElement {
    @api recordId; // Set automatically on a Record Page
    @track requirements = [];
    @track invalidFields = [];
    @track loading = true;

    statusOptions = [
        { label: 'Not Started', value: 'Not Started' },
        { label: 'Incomplete', value: 'Incomplete' },
        { label: 'Complete', value: 'Complete' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Denied', value: 'Denied' }
    ];

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.loading = true;
        Promise.all([
            getRequirements({ onboardingId: this.recordId }),
            getInvalidFieldValues({ onboardingId: this.recordId })
        ])
            .then(([reqs, invalids]) => {
                this.requirements = reqs.map(r => ({ ...r }));
                this.invalidFields = invalids || [];
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handleStatusChange(event) {
        const id = event.target.name;
        const value = event.detail.value;
        const req = this.requirements.find(r => r.Id === id);
        if (req) req.Status = value;
    }

    submit() {
        updateRequirementStatuses({ updates: this.requirements })
            .then(() => runRuleEvaluation({ onboardingId: this.recordId }))
            .then(() => this.loadData())
            .catch(() => {
                // Preserve existing simple error handling
                alert('An error occurred while processing.');
            });
    }

    rerunSelected() {
        const ids = (this.invalidFields || []).map(f => f.fieldValueId);
        if (!ids.length) {
            return;
        }
        rerunValidation({ fieldValueIds: ids })
            .then(() => this.loadData())
            .catch(() => {
                alert('An error occurred while re-running validation.');
            });
    }
}
