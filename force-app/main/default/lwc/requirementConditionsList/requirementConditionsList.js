import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getConditions from '@salesforce/apex/OnboardingStatusRuleController.getConditions';
import deleteCondition from '@salesforce/apex/OnboardingStatusRuleController.deleteCondition';

export default class RequirementConditionList extends LightningElement {
    @api ruleId;
    @track conditions = [];

    columns = [
        { label: 'Sequence', fieldName: 'Sequence__c', type: 'number' },
        { label: 'Requirement', fieldName: 'requirementName' },
        {
            type: 'button',
            typeAttributes: {
                label: 'Delete',
                name: 'delete',
                variant: 'destructive'
            }
        }
    ];

    @wire(getConditions, { ruleId: '$ruleId' })
    wiredConditions(result) {
        this.wiredConditionsResult = result; // Store result for refreshApex
        const { error, data } = result;
        if (data) {
            this.conditions = data.map(row => ({
                ...row,
                requirementName: row.Vendor_Program_Requirement__r.Name
            }));
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            deleteCondition({ conditionId: row.Id })
                .then(() => {
                    // Refresh wire adapter to reflect the deletion
                    if (this.wiredConditionsResult) {
                        return refreshApex(this.wiredConditionsResult);
                    }
                });
        }
    }

    addCondition() {
        // Ideally open a modal or navigation to a child record form
        alert('Add Condition – not yet implemented');
    }

    refreshData() {
        return getConditions({ ruleId: this.ruleId }).then(data => {
            this.conditions = data.map(row => ({
                ...row,
                requirementName: row.Vendor_Program_Requirement__r.Name
            }));
        });
    }
}
