import { createElement } from '@lwc/engine-dom';
import OnboardingRequirementsPanel from 'c/onboardingRequirementsPanel';
import getRequirements from '@salesforce/apex/OnboardingRequirementsPanelController.getRequirements';
import updateRequirementStatuses from '@salesforce/apex/OnboardingRequirementsPanelController.updateRequirementStatuses';
import runRuleEvaluation from '@salesforce/apex/OnboardingRequirementsPanelController.runRuleEvaluation';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.getRequirements',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.updateRequirementStatuses',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.runRuleEvaluation',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-onboarding-requirements-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    const mockRequirements = [
        {
            Id: 'a0X000000000001AAA',
            Name: 'Requirement 1',
            Status: 'Not Started'
        },
        {
            Id: 'a0X000000000002AAA',
            Name: 'Requirement 2',
            Status: 'Incomplete'
        }
    ];

    it('renders component with recordId', () => {
        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        expect(element.recordId).toBe('a0X000000000000AAA');
    });

    it('loads requirements on connectedCallback', async () => {
        getRequirements.mockResolvedValue(mockRequirements);

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        expect(getRequirements).toHaveBeenCalledWith({ onboardingId: 'a0X000000000000AAA' });
        expect(element.requirements).toHaveLength(2);
        expect(element.requirements[0].Name).toBe('Requirement 1');
    });

    it('updates requirement status on change', async () => {
        getRequirements.mockResolvedValue(mockRequirements);

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        const mockEvent = {
            target: { name: 'a0X000000000001AAA' },
            detail: { value: 'Complete' }
        };

        element.handleStatusChange(mockEvent);

        const updatedReq = element.requirements.find(r => r.Id === 'a0X000000000001AAA');
        expect(updatedReq.Status).toBe('Complete');
    });

    it('submits requirements and runs rule evaluation', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        updateRequirementStatuses.mockResolvedValue();
        runRuleEvaluation.mockResolvedValue();

        const alertSpy = jest.spyOn(window, 'alert').mockImplementation();

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        await element.submit();

        expect(updateRequirementStatuses).toHaveBeenCalledWith({
            updates: element.requirements
        });
        expect(runRuleEvaluation).toHaveBeenCalledWith({
            onboardingId: 'a0X000000000000AAA'
        });
        expect(alertSpy).toHaveBeenCalledWith('Requirements updated. Onboarding status re-evaluated.');

        alertSpy.mockRestore();
    });

    it('handles errors during submit', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        updateRequirementStatuses.mockRejectedValue(new Error('Update failed'));

        const alertSpy = jest.spyOn(window, 'alert').mockImplementation();
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        await element.submit();

        expect(alertSpy).toHaveBeenCalledWith('An error occurred while processing.');
        expect(consoleSpy).toHaveBeenCalled();

        alertSpy.mockRestore();
        consoleSpy.mockRestore();
    });

    it('has correct status options', () => {
        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        document.body.appendChild(element);

        expect(element.statusOptions).toHaveLength(5);
        expect(element.statusOptions[0].value).toBe('Not Started');
        expect(element.statusOptions[1].value).toBe('Incomplete');
        expect(element.statusOptions[2].value).toBe('Complete');
        expect(element.statusOptions[3].value).toBe('Approved');
        expect(element.statusOptions[4].value).toBe('Denied');
    });
});

