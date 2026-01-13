import { createElement } from '@lwc/engine-dom';
import StatusEvaluationPreviewModal from 'c/statusEvaluationPreviewModal';
import previewStatusEvaluation from '@salesforce/apex/OnboardingStatusRulesEngineController.previewStatusEvaluation';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/OnboardingStatusRulesEngineController.previewStatusEvaluation',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-status-evaluation-preview-modal', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    const mockTraceData = [
        {
            engineId: 'a0X000000000001AAA',
            engineName: 'Engine 1',
            groupId: 'a0G000000000001AAA',
            groupName: 'Group 1',
            ruleNumber: 1,
            ruleName: 'Rule 1',
            requirementName: 'Requirement 1',
            expectedStatus: 'Complete',
            passed: true,
            resultingStatus: 'Approved',
            evaluationLogic: 'ALL',
            ruleOrder: 1
        },
        {
            engineId: 'a0X000000000001AAA',
            engineName: 'Engine 1',
            groupId: 'a0G000000000001AAA',
            groupName: 'Group 1',
            ruleNumber: 2,
            ruleName: 'Rule 2',
            requirementName: 'Requirement 2',
            expectedStatus: 'Complete',
            passed: false,
            shortCircuitReason: 'Rule evaluation failed',
            evaluationLogic: 'ALL',
            ruleOrder: 2
        }
    ];

    it('renders component', () => {
        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = false;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(element).toBeTruthy();
        });
    });

    it('displays modal when isOpen is true', async () => {
        previewStatusEvaluation.mockResolvedValue(mockTraceData);

        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        expect(element.isOpen).toBe(true);
        expect(element.onboardingId).toBe('a0X000000000000AAA');
    });

    it('loads trace data when onboardingId is provided', async () => {
        previewStatusEvaluation.mockResolvedValue(mockTraceData);

        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        // Verify wire adapter was called with correct parameters
        expect(previewStatusEvaluation).toHaveBeenCalled();
        
        // Verify trace data is processed with keys
        await Promise.resolve();
        expect(element.traceData.length).toBeGreaterThan(0);
        if (element.traceData.length > 0) {
            expect(element.traceData[0]).toHaveProperty('key');
        }
    });

    it('applies filters correctly', async () => {
        previewStatusEvaluation.mockResolvedValue(mockTraceData);

        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Set trace data and apply filter
        element.traceData = mockTraceData.map((trace, index) => ({
            ...trace,
            key: trace.engineId + '-' + (trace.ruleNumber || '') + '-' + index
        }));

        // Apply group filter
        const filterEvent = {
            target: {
                dataset: { field: 'groupName' },
                value: 'Group 1'
            }
        };
        element.filters = { groupName: 'Group 1', engineName: '', ruleNumber: '' };
        element.applyFilters();

        await Promise.resolve();

        // Verify filtered data
        expect(element.filteredTraceData.length).toBeGreaterThan(0);
        element.filteredTraceData.forEach(trace => {
            expect(trace.groupName).toContain('Group 1');
        });
    });

    it('handles empty trace data', async () => {
        previewStatusEvaluation.mockResolvedValue([]);

        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        expect(element.traceData).toEqual([]);
        expect(element.filteredTraceData).toEqual([]);
        expect(element.hasTraceData).toBe(false);
    });

    it('handles error when loading trace data', async () => {
        const error = new Error('Failed to load');
        previewStatusEvaluation.mockRejectedValue(error);

        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        
        let toastEvent;
        element.addEventListener('lightning__showtoast', (event) => {
            toastEvent = event.detail;
        });
        
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(element.traceData).toEqual([]);
        expect(element.filteredTraceData).toEqual([]);
    });

    it('exports CSV correctly', async () => {
        previewStatusEvaluation.mockResolvedValue(mockTraceData);

        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Set up trace data with keys
        element.traceData = mockTraceData.map((trace, index) => ({
            ...trace,
            key: trace.engineId + '-' + (trace.ruleNumber || '') + '-' + index
        }));
        element.filteredTraceData = element.traceData;

        // Mock document.createElement and URL.createObjectURL
        const mockLink = {
            setAttribute: jest.fn(),
            click: jest.fn(),
            style: {}
        };
        const createElementSpy = jest.spyOn(document, 'createElement').mockReturnValue(mockLink);
        const appendChildSpy = jest.spyOn(document.body, 'appendChild').mockImplementation(() => {});
        const removeChildSpy = jest.spyOn(document.body, 'removeChild').mockImplementation(() => {});
        global.URL.createObjectURL = jest.fn(() => 'blob:mock-url');
        global.Blob = jest.fn(() => ({}));

        element.handleExportCSV();

        expect(createElementSpy).toHaveBeenCalledWith('a');
        expect(mockLink.setAttribute).toHaveBeenCalledWith('href', 'blob:mock-url');
        expect(mockLink.setAttribute).toHaveBeenCalledWith('download', expect.stringContaining('evaluation-preview-'));
        expect(mockLink.click).toHaveBeenCalled();

        createElementSpy.mockRestore();
        appendChildSpy.mockRestore();
        removeChildSpy.mockRestore();
    });

    it('closes modal on close button click', async () => {
        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        
        let closeEvent;
        element.addEventListener('close', (event) => {
            closeEvent = event;
        });
        
        document.body.appendChild(element);

        await Promise.resolve();

        element.handleClose();

        expect(element.isOpen).toBe(false);
        expect(closeEvent).toBeTruthy();
    });

    it('has correct column configuration', () => {
        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const expectedColumns = [
                { label: 'Order', fieldName: 'ruleOrder', type: 'number', sortable: true },
                { label: 'Group', fieldName: 'groupName', type: 'text', sortable: true },
                { label: 'Engine', fieldName: 'engineName', type: 'text', sortable: true },
                { label: 'Rule #', fieldName: 'ruleNumber', type: 'number', sortable: true },
                { label: 'Requirement', fieldName: 'requirementName', type: 'text' },
                { label: 'Expected Status', fieldName: 'expectedStatus', type: 'text' },
                { label: 'Passed', fieldName: 'passed', type: 'boolean', sortable: true },
                { label: 'Evaluation Logic', fieldName: 'evaluationLogic', type: 'text' },
                { label: 'Resulting Status', fieldName: 'resultingStatus', type: 'text' },
                { label: 'Reason', fieldName: 'shortCircuitReason', type: 'text', wrapText: true }
            ];
            
            expect(element.columns.length).toBe(10);
            expect(element.columns[0].fieldName).toBe('ruleOrder');
            expect(element.columns[6].fieldName).toBe('passed');
            expect(element.columns[6].type).toBe('boolean');
        });
    });

    it('filters by engine name', async () => {
        previewStatusEvaluation.mockResolvedValue(mockTraceData);

        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        element.traceData = mockTraceData.map((trace, index) => ({
            ...trace,
            key: trace.engineId + '-' + (trace.ruleNumber || '') + '-' + index
        }));

        element.filters = { groupName: '', engineName: 'Engine 1', ruleNumber: '' };
        element.applyFilters();

        await Promise.resolve();

        expect(element.filteredTraceData.length).toBeGreaterThan(0);
        element.filteredTraceData.forEach(trace => {
            expect(trace.engineName).toContain('Engine 1');
        });
    });

    it('filters by rule number', async () => {
        previewStatusEvaluation.mockResolvedValue(mockTraceData);

        const element = createElement('c-status-evaluation-preview-modal', {
            is: StatusEvaluationPreviewModal
        });
        element.onboardingId = 'a0X000000000000AAA';
        element.isOpen = true;
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        element.traceData = mockTraceData.map((trace, index) => ({
            ...trace,
            key: trace.engineId + '-' + (trace.ruleNumber || '') + '-' + index
        }));

        element.filters = { groupName: '', engineName: '', ruleNumber: '1' };
        element.applyFilters();

        await Promise.resolve();

        expect(element.filteredTraceData.length).toBeGreaterThan(0);
        element.filteredTraceData.forEach(trace => {
            if (trace.ruleNumber) {
                expect(String(trace.ruleNumber)).toContain('1');
            }
        });
    });
});
