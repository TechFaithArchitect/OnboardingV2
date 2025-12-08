import { LightningElement, track } from 'lwc';
import getMessagingIssues from '@salesforce/apex/OnboardingAdminDashboardController.getMessagingIssues';
import retryMessaging from '@salesforce/apex/OnboardingAdminDashboardController.retryMessaging';
import dismissMessagingIssue from '@salesforce/apex/OnboardingAdminDashboardController.dismissMessagingIssue';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Type', fieldName: 'type' },
    { label: 'Status', fieldName: 'status' },
    { label: 'Onboarding', fieldName: 'onboardingName' },
    { label: 'Account', fieldName: 'accountName' },
    { label: 'Reason', fieldName: 'triggerReason' },
    { label: 'Attempts', fieldName: 'attemptCount', type: 'number' },
    { label: 'Last Attempt', fieldName: 'lastAttemptDate', type: 'date' },
    { label: 'Failures', fieldName: 'consecutiveFailures', type: 'number' },
    {
        type: 'button',
        typeAttributes: { label: 'Retry', name: 'retry', variant: 'brand' }
    },
    {
        type: 'button',
        typeAttributes: { label: 'Dismiss', name: 'dismiss', variant: 'neutral' }
    }
];

export default class MessagingIssuesPanel extends LightningElement {
    @track issues = [];
    @track dateRange = 'LAST_7_DAYS';
    @track status = '';
    @track type = '';
    @track isLoading = false;

    columns = columns;

    dateRangeOptions = [
        { label: 'Last 24 Hours', value: 'LAST_24_HOURS' },
        { label: 'Last 7 Days', value: 'LAST_7_DAYS' },
        { label: 'Last 30 Days', value: 'LAST_30_DAYS' },
        { label: 'All Time', value: 'ALL_TIME' }
    ];

    statusOptions = [
        { label: 'All', value: '' },
        { label: 'Failed', value: 'Failed' },
        { label: 'Pending', value: 'Pending' },
        { label: 'Pending Retry', value: 'Pending Retry' },
        { label: 'Resolved', value: 'Resolved' }
    ];

    typeOptions = [
        { label: 'All', value: '' },
        { label: 'Email', value: 'Email' },
        { label: 'SMS', value: 'SMS' },
        { label: 'In-App', value: 'In-App' },
        { label: 'Phone', value: 'Phone' }
    ];

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        try {
            const filters = {
                dateRange: this.dateRange,
                status: this.status || null,
                type: this.type || null
            };
            this.issues = await getMessagingIssues({ groupBy: null, filters });
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleDateRangeChange(event) {
        this.dateRange = event.detail.value;
        this.loadData();
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
        this.loadData();
    }

    handleTypeChange(event) {
        this.type = event.detail.value;
        this.loadData();
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'retry') {
            await this.retry(row.id);
        } else if (actionName === 'dismiss') {
            await this.dismiss(row.id);
        }
    }

    async retry(id) {
        try {
            await retryMessaging({ issueId: id });
            this.showToast('Success', 'Retry initiated', 'success');
            this.loadData();
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        }
    }

    async dismiss(id) {
        try {
            await dismissMessagingIssue({ issueId: id });
            this.showToast('Success', 'Issue dismissed', 'success');
            this.loadData();
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    formatError(err) {
        if (err && err.body && err.body.message) {
            return err.body.message;
        }
        return err && err.message ? err.message : 'Unknown error';
    }
}
