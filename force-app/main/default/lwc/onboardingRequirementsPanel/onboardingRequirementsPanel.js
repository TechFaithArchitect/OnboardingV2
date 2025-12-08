import { LightningElement, api, track } from 'lwc';
import getRequirements from '@salesforce/apex/OnboardingRequirementsPanelController.getRequirements';
import updateRequirementStatuses from '@salesforce/apex/OnboardingRequirementsPanelController.updateRequirementStatuses';
import runRuleEvaluation from '@salesforce/apex/OnboardingRequirementsPanelController.runRuleEvaluation';

export default class OnboardingRequirementsPanel extends LightningElement {
    @api recordId; // Set automatically on a Record Page
    @track requirements = [];

    statusOptions = [
        { label: 'Not Started', value: 'Not Started' },
        { label: 'Incomplete', value: 'Incomplete' },
        { label: 'Complete', value: 'Complete' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Denied', value: 'Denied' }
    ];

    connectedCallback() {
        getRequirements({ onboardingId: this.recordId }).then(data => {
            this.requirements = data.map(r => ({ ...r }));
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
            .then(() => {
                alert('Requirements updated. Onboarding status re-evaluated.');
            })
            .catch(err => {
                alert('An error occurred while processing.');
            });
    }
}
