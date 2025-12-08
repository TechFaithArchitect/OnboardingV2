import { createElement } from '@lwc/engine-dom';
import OnboardingFlowEngine from 'c/onboardingFlowEngine';
import getStagesForProcess from '@salesforce/apex/OnboardingApplicationService.getStagesForProcess';
import getProgress from '@salesforce/apex/OnboardingApplicationService.getProgress';
import getProcessDetails from '@salesforce/apex/OnboardingApplicationService.getProcessDetails';
import saveProgress from '@salesforce/apex/OnboardingApplicationService.saveProgress';
import isCurrentUserAdmin from '@salesforce/apex/OnboardingApplicationService.isCurrentUserAdmin';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/OnboardingApplicationService.getStagesForProcess',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingApplicationService.getProgress',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingApplicationService.getProcessDetails',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingApplicationService.saveProgress',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingApplicationService.isCurrentUserAdmin',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-onboarding-flow-engine', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    const mockStages = [
        {
            Id: 'a0X000000000001AAA',
            Name: 'Stage 1',
            Label__c: 'Vendor Selection',
            Display_Order__c: 1,
            Onboarding_Component_Library__r: {
                Component_API_Name__c: 'vendorProgramOnboardingVendor'
            }
        },
        {
            Id: 'a0X000000000002AAA',
            Name: 'Stage 2',
            Label__c: 'Program Setup',
            Display_Order__c: 2,
            Onboarding_Component_Library__r: {
                Component_API_Name__c: 'vendorProgramOnboardingVendorProgramCreate'
            }
        }
    ];

    const mockProcessDetails = {
        Id: 'a0X000000000000AAA',
        Name: 'Standard Onboarding Process',
        Description__c: 'Test process'
    };

    it('renders component with processId and vendorProgramId', () => {
        const element = createElement('c-onboarding-flow-engine', {
            is: OnboardingFlowEngine
        });
        element.processId = 'a0X000000000000AAA';
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        expect(element.processId).toBe('a0X000000000000AAA');
        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });

    it('initializes flow and loads stages on connectedCallback', async () => {
        getStagesForProcess.mockResolvedValue(mockStages);
        getProgress.mockResolvedValue(null);
        getProcessDetails.mockResolvedValue(mockProcessDetails);

        const element = createElement('c-onboarding-flow-engine', {
            is: OnboardingFlowEngine
        });
        element.processId = 'a0X000000000000AAA';
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        // Wait for async operations
        await new Promise(resolve => setTimeout(resolve, 0));

        expect(getStagesForProcess).toHaveBeenCalledWith({ processId: 'a0X000000000000AAA' });
        expect(element.stages).toEqual(mockStages);
        expect(element.processName).toBe('Standard Onboarding Process');
        expect(element.loaded).toBe(true);
    });

    it('resumes from saved progress if exists', async () => {
        const mockProgress = {
            Id: 'a0X000000000003AAA',
            Current_Stage__c: 'a0X000000000002AAA'
        };

        getStagesForProcess.mockResolvedValue(mockStages);
        getProgress.mockResolvedValue(mockProgress);
        getProcessDetails.mockResolvedValue(mockProcessDetails);

        const element = createElement('c-onboarding-flow-engine', {
            is: OnboardingFlowEngine
        });
        element.processId = 'a0X000000000000AAA';
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        expect(element.activeStageIndex).toBe(1); // Should resume at stage 2
    });

    it('computes activeStage correctly', async () => {
        getStagesForProcess.mockResolvedValue(mockStages);
        getProgress.mockResolvedValue(null);
        getProcessDetails.mockResolvedValue(mockProcessDetails);

        const element = createElement('c-onboarding-flow-engine', {
            is: OnboardingFlowEngine
        });
        element.processId = 'a0X000000000000AAA';
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        expect(element.activeStage).toEqual(mockStages[0]);
        expect(element.activeStageLabel).toBe('Vendor Selection');
        expect(element.activeComponentName).toBe('vendorProgramOnboardingVendor');
    });

    it('handles next stage navigation', async () => {
        getStagesForProcess.mockResolvedValue(mockStages);
        getProgress.mockResolvedValue(null);
        getProcessDetails.mockResolvedValue(mockProcessDetails);
        saveProgress.mockResolvedValue('a0X000000000003AAA');

        const element = createElement('c-onboarding-flow-engine', {
            is: OnboardingFlowEngine
        });
        element.processId = 'a0X000000000000AAA';
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        // Simulate next event
        const nextEvent = new CustomEvent('next', { detail: {} });
        await element.handleNext(nextEvent);

        expect(element.activeStageIndex).toBe(1);
        expect(saveProgress).toHaveBeenCalled();
    });

    it('handles back navigation', async () => {
        getStagesForProcess.mockResolvedValue(mockStages);
        getProgress.mockResolvedValue(null);
        getProcessDetails.mockResolvedValue(mockProcessDetails);
        saveProgress.mockResolvedValue('a0X000000000003AAA');

        const element = createElement('c-onboarding-flow-engine', {
            is: OnboardingFlowEngine
        });
        element.processId = 'a0X000000000000AAA';
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        // Move to stage 2 first
        element.activeStageIndex = 1;
        await new Promise(resolve => setTimeout(resolve, 0));

        // Then go back
        await element.handleBack();

        expect(element.activeStageIndex).toBe(0);
        expect(saveProgress).toHaveBeenCalled();
    });

    it('does not navigate back when at first stage', async () => {
        getStagesForProcess.mockResolvedValue(mockStages);
        getProgress.mockResolvedValue(null);
        getProcessDetails.mockResolvedValue(mockProcessDetails);

        const element = createElement('c-onboarding-flow-engine', {
            is: OnboardingFlowEngine
        });
        element.processId = 'a0X000000000000AAA';
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        await element.handleBack();

        expect(element.activeStageIndex).toBe(0);
    });

    it('handles errors during initialization', async () => {
        const mockError = new Error('Test error');
        getStagesForProcess.mockRejectedValue(mockError);

        const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

        const element = createElement('c-onboarding-flow-engine', {
            is: OnboardingFlowEngine
        });
        element.processId = 'a0X000000000000AAA';
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await new Promise(resolve => setTimeout(resolve, 0));

        expect(consoleSpy).toHaveBeenCalledWith('Error initializing onboarding flow:', mockError);
        expect(element.loaded).toBe(true);

        consoleSpy.mockRestore();
    });
});

