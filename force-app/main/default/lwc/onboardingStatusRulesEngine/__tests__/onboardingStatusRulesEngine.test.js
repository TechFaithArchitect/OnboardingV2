import { createElement } from '@lwc/engine-dom';
import OnboardingStatusRulesEngine from 'c/onboardingStatusRulesEngine';
import getVendorProgramGroups from '@salesforce/apex/OnboardingStatusRulesEngineController.getVendorProgramGroups';
import getRequirementGroups from '@salesforce/apex/OnboardingStatusRulesEngineController.getRequirementGroups';
import getRules from '@salesforce/apex/OnboardingStatusRulesEngineController.getRules';
import saveRules from '@salesforce/apex/OnboardingStatusRulesEngineController.saveRules';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/OnboardingStatusRulesEngineController.getVendorProgramGroups',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingStatusRulesEngineController.getRequirementGroups',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingStatusRulesEngineController.getRules',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingStatusRulesEngineController.saveRules',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-onboarding-status-rules-engine', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    const mockVendorProgramGroups = [
        { value: 'a0X000000000001AAA', label: 'Group 1' },
        { value: 'a0X000000000002AAA', label: 'Group 2' }
    ];

    const mockRequirementGroups = [
        { value: 'a0X000000000003AAA', label: 'Requirement Group 1' },
        { value: 'a0X000000000004AAA', label: 'Requirement Group 2' }
    ];

    const mockRules = [
        {
            Id: 'a0X000000000005AAA',
            Requirement__c: 'Req 1',
            Resulting_Status__c: 'Approved',
            Evaluation_Logic__c: 'ALL',
            Custom_Evaluation_Logic__c: null
        }
    ];

    it('renders component', () => {
        const element = createElement('c-onboarding-status-rules-engine', {
            is: OnboardingStatusRulesEngine
        });
        document.body.appendChild(element);

        expect(element).toBeTruthy();
    });

    it('loads vendor program groups and requirement groups on connectedCallback', async () => {
        getVendorProgramGroups.mockResolvedValue(mockVendorProgramGroups);
        getRequirementGroups.mockResolvedValue(mockRequirementGroups);

        const element = createElement('c-onboarding-status-rules-engine', {
            is: OnboardingStatusRulesEngine
        });
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        expect(getVendorProgramGroups).toHaveBeenCalled();
        expect(getRequirementGroups).toHaveBeenCalled();
        expect(element.vendorProgramGroupOptions).toEqual(mockVendorProgramGroups);
        expect(element.requirementGroupOptions).toEqual(mockRequirementGroups);
    });

    it('handles vendor program group selection change', () => {
        const element = createElement('c-onboarding-status-rules-engine', {
            is: OnboardingStatusRulesEngine
        });
        document.body.appendChild(element);

        const mockEvent = {
            detail: { value: 'a0X000000000001AAA' }
        };

        element.handleVendorProgramGroupChange(mockEvent);

        expect(element.selectedVendorProgramGroup).toBe('a0X000000000001AAA');
    });

    it('handles requirement group selection change', () => {
        const element = createElement('c-onboarding-status-rules-engine', {
            is: OnboardingStatusRulesEngine
        });
        document.body.appendChild(element);

        const mockEvent = {
            detail: { value: 'a0X000000000003AAA' }
        };

        element.handleRequirementGroupChange(mockEvent);

        expect(element.selectedRequirementGroup).toBe('a0X000000000003AAA');
    });

    it('loads rules when both groups are selected', async () => {
        getRules.mockResolvedValue(mockRules);

        const element = createElement('c-onboarding-status-rules-engine', {
            is: OnboardingStatusRulesEngine
        });
        element.selectedVendorProgramGroup = 'a0X000000000001AAA';
        element.selectedRequirementGroup = 'a0X000000000003AAA';
        document.body.appendChild(element);

        element.loadRules();

        await new Promise(resolve => setTimeout(resolve, 0));

        expect(getRules).toHaveBeenCalledWith({
            vendorProgramGroupId: 'a0X000000000001AAA',
            requirementGroupId: 'a0X000000000003AAA'
        });
        expect(element.rules).toEqual(mockRules);
    });

    it('saves rules and reloads', async () => {
        getRules.mockResolvedValue(mockRules);
        saveRules.mockResolvedValue();

        const element = createElement('c-onboarding-status-rules-engine', {
            is: OnboardingStatusRulesEngine
        });
        element.selectedVendorProgramGroup = 'a0X000000000001AAA';
        element.selectedRequirementGroup = 'a0X000000000003AAA';
        element.rules = mockRules;
        document.body.appendChild(element);

        const mockEvent = {
            detail: {
                draftValues: [
                    {
                        Id: 'a0X000000000005AAA',
                        Resulting_Status__c: 'Denied'
                    }
                ]
            }
        };

        await element.handleSave(mockEvent);

        expect(saveRules).toHaveBeenCalledWith({
            rules: mockEvent.detail.draftValues
        });
        expect(getRules).toHaveBeenCalled();
        expect(element.draftValues).toEqual([]);
    });

    it('has correct column configuration', () => {
        const element = createElement('c-onboarding-status-rules-engine', {
            is: OnboardingStatusRulesEngine
        });
        document.body.appendChild(element);

        expect(element.columns).toHaveLength(4);
        expect(element.columns[0].fieldName).toBe('Requirement__c');
        expect(element.columns[1].fieldName).toBe('Resulting_Status__c');
        expect(element.columns[2].fieldName).toBe('Evaluation_Logic__c');
        expect(element.columns[3].fieldName).toBe('Custom_Evaluation_Logic__c');
    });
});

