import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getValidationRules from '@salesforce/apex/ValidationRuleTesterController.getValidationRules';
import testRule from '@salesforce/apex/ValidationRuleTesterController.testRule';
import simulateRule from '@salesforce/apex/ValidationRuleTesterController.simulateRule';
import compareRules from '@salesforce/apex/ValidationRuleTesterController.compareRules';
import saveTestCase from '@salesforce/apex/ValidationRuleTesterController.saveTestCase';
import loadTestCases from '@salesforce/apex/ValidationRuleTesterController.loadTestCases';

export default class ValidationRuleTester extends LightningElement {
    @track selectedRuleId = null;
    @track selectedRule = null;
    @track testValues = {};
    @track testResults = [];
    @track isLoading = false;
    @track isSimulationMode = false;
    @track savedTestCases = [];
    @track selectedTestCase = null;
    @track comparisonMode = false;
    @track selectedRuleIds = [];

    @wire(getValidationRules)
    wiredRules({ error, data }) {
        if (data) {
            this.rules = data;
        } else if (error) {
            console.error('Error loading validation rules:', error);
            this.showError('Failed to load validation rules');
        }
    }

    @wire(loadTestCases)
    wiredTestCases({ error, data }) {
        if (data) {
            this.savedTestCases = data;
        } else if (error) {
            console.error('Error loading test cases:', error);
        }
    }

    get rules() {
        return this._rules || [];
    }

    set rules(value) {
        this._rules = value;
    }

    get ruleOptions() {
        return this.rules.map(rule => ({
            label: rule.label || rule.developerName,
            value: rule.developerName
        }));
    }

    get fieldInputs() {
        if (!this.selectedRule) return [];
        
        // Extract fields from rule definition
        // TODO: Parse rule metadata to get field list
        // For now, return common fields with pre-computed values
        const fields = [
            { apiName: 'Value__c', label: 'Value', type: 'text', required: false },
            { apiName: 'Encrypted_Value__c', label: 'Encrypted Value', type: 'text', required: false }
        ];
        
        // Pre-compute values for template (LWC doesn't allow computed property access)
        return fields.map(field => ({
            ...field,
            value: this.testValues[field.apiName] || ''
        }));
    }

    handleRuleSelection(event) {
        this.selectedRuleId = event.detail.value;
        this.selectedRule = this.rules.find(r => r.developerName === this.selectedRuleId);
        this.testValues = {};
        this.testResults = [];
    }

    handleTestValueChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.value;
        this.testValues[fieldName] = value;
    }

    handleRunTest() {
        if (!this.selectedRuleId) {
            this.showWarning('Please select a validation rule');
            return;
        }

        this.isLoading = true;
        const method = this.isSimulationMode ? simulateRule : testRule;
        
        method({ 
            ruleId: this.selectedRuleId,
            testValues: this.testValues
        })
        .then(result => {
            // Pre-compute display values for template
            result.iconName = result.isValid ? 'utility:success' : 'utility:error';
            result.iconClass = result.isValid ? 'slds-icon-text-success' : 'slds-icon-text-error';
            result.statusText = result.isValid ? 'Valid' : 'Invalid';
            this.testResults = [result];
            this.isLoading = false;
            this.showSuccess('Test completed');
        })
        .catch(error => {
            this.showError('Test failed: ' + (error.body?.message || error.message));
            this.isLoading = false;
        });
    }

    handleCompareRules() {
        if (this.selectedRuleIds.length < 2) {
            this.showWarning('Please select at least 2 rules to compare');
            return;
        }

        this.isLoading = true;
        compareRules({
            ruleIds: this.selectedRuleIds,
            testValues: this.testValues
        })
        .then(results => {
            // Pre-compute display values for each result
            results.forEach(result => {
                result.iconName = result.isValid ? 'utility:success' : 'utility:error';
                result.iconClass = result.isValid ? 'slds-icon-text-success' : 'slds-icon-text-error';
                result.statusText = result.isValid ? 'Valid' : 'Invalid';
            });
            this.testResults = results;
            this.comparisonMode = true;
            this.isLoading = false;
            this.showSuccess('Comparison completed');
        })
        .catch(error => {
            this.showError('Comparison failed: ' + (error.body?.message || error.message));
            this.isLoading = false;
        });
    }

    handleSaveTestCase() {
        if (!this.selectedRuleId || Object.keys(this.testValues).length === 0) {
            this.showWarning('Please select a rule and enter test values');
            return;
        }

        this.isLoading = true;
        saveTestCase({
            ruleId: this.selectedRuleId,
            testValues: this.testValues,
            testCaseName: this.testCaseName || 'Test Case ' + Date.now()
        })
        .then(() => {
            this.showSuccess('Test case saved');
            this.isLoading = false;
            // Refresh test cases
            this.refreshTestCases();
        })
        .catch(error => {
            this.showError('Failed to save test case: ' + (error.body?.message || error.message));
            this.isLoading = false;
        });
    }

    handleLoadTestCase(event) {
        const testCaseId = event.detail.value;
        if (!testCaseId) return;

        const testCase = this.savedTestCases.find(tc => tc.id === testCaseId);
        if (testCase) {
            this.selectedRuleId = testCase.ruleId;
            this.selectedRule = this.rules.find(r => r.developerName === testCase.ruleId);
            this.testValues = testCase.testValues || {};
            this.showInfo('Test case loaded');
        }
    }

    handleToggleSimulationMode(event) {
        this.isSimulationMode = event.target.checked;
    }

    handleToggleComparisonMode(event) {
        this.comparisonMode = event.target.checked;
        if (this.comparisonMode) {
            this.selectedRuleIds = this.selectedRuleId ? [this.selectedRuleId] : [];
        }
    }

    handleRuleSelectionForComparison(event) {
        const ruleId = event.detail.value;
        if (this.selectedRuleIds.includes(ruleId)) {
            this.selectedRuleIds = this.selectedRuleIds.filter(id => id !== ruleId);
        } else {
            this.selectedRuleIds.push(ruleId);
        }
    }

    refreshTestCases() {
        // Wire adapter will automatically refresh
    }

    get hasTestResults() {
        return this.testResults && this.testResults.length > 0;
    }

    get testCaseName() {
        return this._testCaseName || '';
    }

    set testCaseName(value) {
        this._testCaseName = value;
    }

    handleTestCaseNameChange(event) {
        this.testCaseName = event.target.value;
    }

    get testCaseOptions() {
        return this.savedTestCases.map(tc => ({
            label: tc.name,
            value: tc.id
        }));
    }

    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }

    showWarning(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Warning',
            message: message,
            variant: 'warning'
        }));
    }

    showInfo(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Info',
            message: message,
            variant: 'info'
        }));
    }
}

