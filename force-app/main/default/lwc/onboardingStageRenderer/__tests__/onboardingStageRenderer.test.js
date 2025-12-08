import { createElement } from '@lwc/engine-dom';
import OnboardingStageRenderer from 'c/onboardingStageRenderer';

describe('c-onboarding-stage-renderer', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders component with componentName and context', () => {
        const element = createElement('c-onboarding-stage-renderer', {
            is: OnboardingStageRenderer
        });
        element.componentName = 'vendorProgramOnboardingVendor';
        element.context = {
            vendorProgramId: '001000000000000AAA',
            stageId: 'a0X000000000001AAA'
        };
        document.body.appendChild(element);

        expect(element.componentName).toBe('vendorProgramOnboardingVendor');
        expect(element.context.vendorProgramId).toBe('001000000000000AAA');
    });

    it('dispatches next event when child component fires next', () => {
        const element = createElement('c-onboarding-stage-renderer', {
            is: OnboardingStageRenderer
        });
        element.componentName = 'vendorProgramOnboardingVendor';
        element.context = {
            vendorProgramId: '001000000000000AAA',
            stageId: 'a0X000000000001AAA'
        };
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('next', handler);

        const nextEvent = new CustomEvent('next', {
            detail: { data: 'test' },
            bubbles: true
        });

        element.handleNext(nextEvent);

        expect(handler).toHaveBeenCalled();
    });

    it('dispatches back event when child component fires back', () => {
        const element = createElement('c-onboarding-stage-renderer', {
            is: OnboardingStageRenderer
        });
        element.componentName = 'vendorProgramOnboardingVendor';
        element.context = {
            vendorProgramId: '001000000000000AAA',
            stageId: 'a0X000000000001AAA'
        };
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('back', handler);

        const backEvent = new CustomEvent('back', {
            detail: { data: 'test' },
            bubbles: true
        });

        element.handleBack(backEvent);

        expect(handler).toHaveBeenCalled();
    });

    it('passes event detail through to parent', () => {
        const element = createElement('c-onboarding-stage-renderer', {
            is: OnboardingStageRenderer
        });
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('next', handler);

        const testDetail = { stageData: 'test data', completed: true };
        const nextEvent = new CustomEvent('next', {
            detail: testDetail,
            bubbles: true
        });

        element.handleNext(nextEvent);

        expect(handler).toHaveBeenCalledWith(
            expect.objectContaining({
                detail: testDetail
            })
        );
    });
});

