import { LightningElement, track, wire } from 'lwc';
import getVendorProgramGroups from '@salesforce/apex/OnboardingStatusRulesEngineController.getVendorProgramGroups';
import getRequirementGroups from '@salesforce/apex/OnboardingStatusRulesEngineController.getRequirementGroups';
import getRules from '@salesforce/apex/OnboardingStatusRulesEngineController.getRules';
import saveRules from '@salesforce/apex/OnboardingStatusRulesEngineController.saveRules';

export default class OnboardingStatusRulesEngine extends LightningElement {
    @track vendorProgramGroupOptions = [];
    @track requirementGroupOptions = [];
    @track rules = [];
    @track draftValues = [];

    selectedVendorProgramGroup;
    selectedRequirementGroup;

    columns = [
        { label: 'Requirement', fieldName: 'Requirement__c', editable: false },
        { label: 'Resulting Status', fieldName: 'Resulting_Status__c', editable: true },
        { label: 'Evaluation Logic', fieldName: 'Evaluation_Logic__c', editable: true },
        { label: 'Custom Evaluation Logic', fieldName: 'Custom_Evaluation_Logic__c', editable: true }
    ];

    connectedCallback() {
        Promise.all([
            getVendorProgramGroups(),
            getRequirementGroups()
        ]).then(([vendorGroups, requirementGroups]) => {
            this.vendorProgramGroupOptions = vendorGroups;
            this.requirementGroupOptions = requirementGroups;
        }).catch(error => {
            // Silently fail - groups will remain empty
        });
    }

    handleVendorProgramGroupChange(event) {
        this.selectedVendorProgramGroup = event.detail.value;
    }

    handleRequirementGroupChange(event) {
        this.selectedRequirementGroup = event.detail.value;
    }

    loadRules() {
        getRules({ 
            vendorProgramGroupId: this.selectedVendorProgramGroup, 
            requirementGroupId: this.selectedRequirementGroup 
        }).then(result => {
            this.rules = result;
        });
    }

    handleSave(event) {
        const updatedFields = event.detail.draftValues;
        saveRules({ rules: updatedFields }).then(() => {
            this.loadRules();
            this.draftValues = [];
        });
    }
}
