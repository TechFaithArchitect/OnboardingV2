import { LightningElement, api } from 'lwc';

export default class OnboardingWorkQueue extends LightningElement {
    @api records = [];
    @api showBlockingIndicators = false;
    @api columns;

    defaultColumns = [
        { label: 'Account', fieldName: 'AccountName', type: 'text' },
        { label: 'Vendor Program', fieldName: 'VendorProgramName', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { 
            label: 'Age', 
            fieldName: 'AgeInDays', 
            type: 'number',
            cellAttributes: { class: { fieldName: 'ageClass' } }
        },
        { 
            label: 'Last Modified', 
            fieldName: 'LastModifiedDate', 
            type: 'date',
            typeAttributes: { 
                year: 'numeric',
                month: 'short', 
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            }
        },
        { 
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Resume', name: 'resume' },
                    { label: 'Requirements', name: 'viewrequirements' }
                ]
            }
        }
    ];

    get tableColumns() {
        return this.columns || this.defaultColumns;
    }

    get processedRecords() {
        if (!this.records || this.records.length === 0) {
            return [];
        }

        return this.records.map(record => {
            const processed = { ...record };
            
            // Calculate age if not present
            if (!processed.AgeInDays && processed.CreatedDate) {
                const createdDate = new Date(processed.CreatedDate);
                const today = new Date();
                processed.AgeInDays = Math.floor((today - createdDate) / (1000 * 60 * 60 * 24));
            }

            // Add row class for blocking indicators
            if (this.showBlockingIndicators) {
                if (processed.IsBlocked) {
                    processed.rowClass = 'blocked-row';
                } else if (processed.IsAtRisk) {
                    processed.rowClass = 'at-risk-row';
                } else {
                    processed.rowClass = 'normal-row';
                }
            } else {
                processed.rowClass = 'normal-row';
            }

            // Add age class
            if (processed.AgeInDays > 14) {
                processed.ageClass = 'slds-text-color_error';
            } else if (processed.AgeInDays > 7) {
                processed.ageClass = 'slds-text-color_warning';
            } else {
                processed.ageClass = '';
            }

            return processed;
        });
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        const eventName = action.name === 'view' ? 'view' : 
                         action.name === 'resume' ? 'resume' : 
                         'viewrequirements';
        
        this.dispatchEvent(
            new CustomEvent(eventName, {
                detail: {
                    recordId: row.Id,
                    record: row
                },
                bubbles: true,
                composed: true
            })
        );
    }
}

