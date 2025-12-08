import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasAdminPermission from '@salesforce/customPermission/OnboardingAppAdmin';
import getMyActiveOnboarding from '@salesforce/apex/OnboardingHomeDashboardController.getMyActiveOnboarding';
import getOnboardingSummary from '@salesforce/apex/OnboardingHomeDashboardController.getOnboardingSummary';
import getEligibleAccounts from '@salesforce/apex/OnboardingHomeDashboardController.getEligibleAccounts';
import getRecentActivity from '@salesforce/apex/OnboardingHomeDashboardController.getRecentActivity';
import getVendorProgramMetrics from '@salesforce/apex/OnboardingHomeDashboardController.getVendorProgramMetrics';
import getBlockedOnboardingCount from '@salesforce/apex/OnboardingHomeDashboardController.getBlockedOnboardingCount';
import getTeamOnboarding from '@salesforce/apex/OnboardingHomeDashboardController.getTeamOnboarding';
import getVendorsWithPrograms from '@salesforce/apex/OnboardingHomeDashboardController.getVendorsWithPrograms';
import searchVendorsWithPrograms from '@salesforce/apex/OnboardingHomeDashboardController.searchVendorsWithPrograms';
import searchVendors from '@salesforce/apex/VendorOnboardingWizardController.searchVendors';
import createVendor from '@salesforce/apex/VendorOnboardingWizardController.createVendor';
import createVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgram';
import searchVendorPrograms from '@salesforce/apex/VendorOnboardingWizardController.searchVendorPrograms';
import getRecentVendorPrograms from '@salesforce/apex/VendorOnboardingWizardController.getRecentVendorPrograms';
import getDefaultVendorProgramOnboardingProcessId from '@salesforce/apex/OnboardingApplicationService.getDefaultVendorProgramOnboardingProcessId';
import initializeVendorProgramOnboarding from '@salesforce/apex/VendorOnboardingWizardController.initializeVendorProgramOnboarding';
import syncComponentLibrary from '@salesforce/apex/VendorOnboardingWizardController.syncComponentLibrary';
import initializeDefaultProcess from '@salesforce/apex/VendorOnboardingWizardController.initializeDefaultProcess';

export default class OnboardingHomeDashboard extends NavigationMixin(LightningElement) {
    // Filter state
    @track filters = {
        timeRange: 'LAST_90_DAYS',
        vendors: [],
        programs: [],
        view: 'MY_VIEW'
    };

    // Tab state
    @track activeTab = 'my-onboarding';

    // Data state
    @track activeOnboarding = [];
    @track eligibleAccounts = [];
    @track recentActivity = [];
    @track summary = {};
    @track vendorSummary = {};
    @track vendorPrograms = [];
    @track vendorProgramMetrics = [];
    @track blockedCount = 0;
    @track teamQueue = [];
    
    // Always show blocking indicators in work queues
    showBlockingIndicators = true;
    
    @track isLoading = true;
    @track showStartModal = false;
    @track selectedAccountId = null;
    
    // Vendor Program Onboarding Modal
    @track showVendorProgramModal = false;
    @track vendorProgramModalStep = 'treeGrid'; // 'treeGrid' | 'vendorSelection' | 'vendorProgramSelection'
    @track vendors = [];
    @track selectedVendorId = null;
    @track vendorSearchText = '';
    @track newVendorName = '';
    @track isVendorSearching = false;
    @track isCreatingVendor = false;
    @track isSyncingComponentLibrary = false;

    // Wizard Modal
    @track showWizardModal = false;
    @track wizardVendorProgramId = null;
    @track isInitializingProcess = false;
    
    // Vendor Program Selection
    @track vendorPrograms = [];
    @track recentVendorPrograms = [];
    @track selectedVendorProgramId = null;
    @track vendorProgramSearchText = '';
    @track isVendorProgramSearching = false;

    // Vendor Hierarchy Tree Grid
    @track vendorHierarchy = [];
    @track vendorSearchText = '';
    @track vendorSearchTimeout;
    @track isVendorHierarchyLoading = false;
    @track expandedVendorRows = [];
    @track isResumingOnboarding = false;

    // Column definitions for active onboarding table
    activeOnboardingColumns = [
        { label: 'Account', fieldName: 'AccountName', type: 'text' },
        { label: 'Vendor Program', fieldName: 'VendorProgramName', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Last Modified', fieldName: 'LastModifiedDate', type: 'date',
          typeAttributes: { 
              year: 'numeric',
              month: 'short', 
              day: '2-digit',
              hour: '2-digit',
              minute: '2-digit'
          }
        },
        { label: 'Created By', fieldName: 'CreatedByName', type: 'text' },
        { 
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Resume', name: 'resume' }
                ]
            }
        }
    ];

    // Column definitions for eligible accounts table
    eligibleAccountsColumns = [
        { label: 'Account Name', fieldName: 'Name', type: 'text' },
        { label: 'Territory', fieldName: 'Territory', type: 'text' },
        { label: 'Region', fieldName: 'Region', type: 'text' },
        { label: 'Eligible Vendors', fieldName: 'EligibleVendorCount', type: 'number' },
        { 
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Start Onboarding', name: 'start' },
                    { label: 'View Account', name: 'view' }
                ]
            }
        }
    ];

    // Column definitions for vendor hierarchy tree grid
    vendorHierarchyColumns = [
        { 
            label: 'Name / Label', 
            fieldName: 'displayName', 
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'rowClass' }
            }
        },
        { 
            label: 'Status', 
            fieldName: 'status', 
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'statusClass' }
            }
        },
        { 
            label: 'Programs', 
            fieldName: 'programCount', 
            type: 'number',
            typeAttributes: {
                minimumFractionDigits: 0
            }
        },
        { 
            label: 'Retail Option', 
            fieldName: 'retailOption', 
            type: 'text'
        },
        { 
            label: 'Business Vertical', 
            fieldName: 'businessVertical', 
            type: 'text'
        },
        { 
            label: 'Last Modified', 
            fieldName: 'lastModifiedDate', 
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
            label: 'Modified By', 
            fieldName: 'lastModifiedBy', 
            type: 'text'
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Edit', name: 'edit' }
                ]
            }
        }
    ];

    // Computed properties for wire parameters
    // These need to return undefined (not null) for @wire to work correctly with optional parameters
    get timeFilterParam() {
        return this.filters && this.filters.timeRange ? this.filters.timeRange : 'LAST_90_DAYS';
    }

    get vendorFilterParam() {
        if (!this.filters || !this.filters.vendors || this.filters.vendors.length === 0) {
            return null;
        }
        return this.filters.vendors;
    }

    get programFilterParam() {
        if (!this.filters || !this.filters.programs || this.filters.programs.length === 0) {
            return null;
        }
        return this.filters.programs;
    }

    get viewFilterParam() {
        return this.filters && this.filters.view ? this.filters.view : 'MY_VIEW';
    }

    @wire(getMyActiveOnboarding, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam',
        viewFilter: '$viewFilterParam'
    })
    wiredActiveOnboarding({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            this.activeOnboarding = (data || []).map(ob => ({
                ...ob,
                LastModifiedDate: ob.LastModifiedDate ? new Date(ob.LastModifiedDate) : null
            }));
            this.isLoading = false;
        } else if (error) {
            // Only show error if there's an actual server error, not just empty results
            this.showToast('Error', 'Failed to load active onboarding records.', 'error');
            this.isLoading = false;
        }
    }

    @wire(getOnboardingSummary, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam',
        viewFilter: '$viewFilterParam'
    })
    wiredSummary({ error, data }) {
        if (data) {
            this.summary = data;
        } else if (error) {
            // Silently fail - summary is not critical
        }
    }

    @wire(getEligibleAccounts, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredEligibleAccounts({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            this.eligibleAccounts = data || [];
        } else if (error) {
            // Only show error if there's an actual server error, not just empty results
            this.showToast('Error', 'Failed to load eligible accounts.', 'error');
        }
    }

    @wire(getRecentActivity, {
        recordLimit: 10,
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredRecentActivity({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            this.recentActivity = (data || []).map(ob => ({
                ...ob,
                LastModifiedDate: ob.LastModifiedDate ? new Date(ob.LastModifiedDate) : null
            }));
        } else if (error) {
            // Silently fail - recent activity is not critical
        }
    }

    @wire(getVendorProgramMetrics, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam'
    })
    wiredVendorProgramMetrics({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            const programs = data || [];
            this.vendorPrograms = programs;
            // Build vendor summary
            this.vendorSummary = {
                Active: programs.filter(p => p.Active && p.Status === 'Active').length,
                Draft: programs.filter(p => p.Status === 'Draft').length,
                Total: programs.length
            };
        } else if (error) {
            console.error('Error loading vendor program metrics:', error);
        }
    }

    @wire(getBlockedOnboardingCount, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredBlockedCount({ error, data }) {
        if (data !== undefined) {
            this.blockedCount = data;
        } else if (error) {
            console.error('Error loading blocked count:', error);
        }
    }

    @wire(getTeamOnboarding, {
        viewFilter: '$viewFilterParam',
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredTeamQueue({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            this.teamQueue = (data || []).map(ob => ({
                ...ob,
                LastModifiedDate: ob.LastModifiedDate ? new Date(ob.LastModifiedDate) : null
            }));
        } else if (error) {
            console.error('Error loading team queue:', error);
        }
    }

    @wire(getVendorsWithPrograms)
    wiredVendorHierarchy({ error, data }) {
        if (data) {
            this.processVendorHierarchy(data);
            this.isVendorHierarchyLoading = false;
        } else if (error) {
            this.showToast('Error', 'Failed to load vendors and programs.', 'error');
            this.isVendorHierarchyLoading = false;
        }
    }

    processVendorHierarchy(data) {
        this.vendorHierarchy = data.map(vendor => {
            const vendorRow = {
                id: vendor.id,
                name: vendor.name,
                displayName: vendor.name, // For vendors, show name
                status: vendor.status,
                programCount: vendor.programCount,
                recordType: vendor.recordType,
                lastModifiedDate: vendor.lastModifiedDate ? new Date(vendor.lastModifiedDate) : null,
                rowClass: 'slds-text-heading_small',
                statusClass: vendor.status === 'Active' ? 'slds-text-color_success' : 'slds-text-color_weak',
                _children: vendor.children ? vendor.children.map(program => ({
                    id: program.id,
                    name: program.name,
                    label: program.label || '',
                    displayName: program.label || program.name, // For programs, show Label (or fallback to name)
                    status: program.status || 'Draft',
                    programCount: null,
                    recordType: program.recordType,
                    retailOption: program.retailOption || '',
                    businessVertical: program.businessVertical || '',
                    lastModifiedDate: program.lastModifiedDate ? new Date(program.lastModifiedDate) : null,
                    lastModifiedBy: program.lastModifiedBy || '',
                    parentId: program.parentId,
                    rowClass: 'slds-text-body_regular',
                    statusClass: this.getStatusClass(program.status),
                    _children: null
                })) : []
            };
            return vendorRow;
        });
    }

    getStatusClass(status) {
        if (!status) return '';
        const statusLower = status.toLowerCase();
        if (statusLower === 'active') return 'slds-text-color_success';
        if (statusLower === 'draft') return 'slds-text-color_weak';
        if (statusLower === 'inactive') return 'slds-text-color_error';
        return '';
    }

    handleVendorSearchChange(event) {
        const searchValue = event.target.value || '';
        this.vendorSearchText = searchValue;

        if (this.vendorSearchTimeout) {
            clearTimeout(this.vendorSearchTimeout);
        }

        if (!searchValue || searchValue.trim().length === 0) {
            // Clear search and reload all vendors
            this.vendorSearchTimeout = setTimeout(() => {
                this.loadVendorHierarchy();
            }, 300);
            return;
        }

        // Debounce search
        this.isVendorHierarchyLoading = true;
        this.vendorSearchTimeout = setTimeout(() => {
            this.searchVendorHierarchy(searchValue.trim());
        }, 500);
    }

    async loadVendorHierarchy() {
        try {
            this.isVendorHierarchyLoading = true;
            const data = await getVendorsWithPrograms();
            this.processVendorHierarchy(data);
        } catch (error) {
            this.showToast('Error', 'Failed to load vendors and programs.', 'error');
        } finally {
            this.isVendorHierarchyLoading = false;
        }
    }

    async searchVendorHierarchy(searchText) {
        try {
            const data = await searchVendorsWithPrograms({ searchText: searchText });
            this.processVendorHierarchy(data);
        } catch (error) {
            this.showToast('Error', 'Failed to search vendors and programs.', 'error');
        } finally {
            this.isVendorHierarchyLoading = false;
        }
    }

    handleVendorHierarchyRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'edit') {
            // Resume onboarding process from where it was left off
            // Only proceed if it's a program (not a vendor row)
            if (row.recordType === 'program') {
                this.resumeVendorProgramOnboarding(row.id);
            } else {
                // If clicked on vendor row, show message
                this.showToast('Info', 'Please select a specific program to edit.', 'info');
            }
        }
    }

    // Resume onboarding - this is called from the tree grid "Edit" action
    // Simply open the wizard modal with the vendor program ID
    // The wizard modal will handle initialization and routing to the correct stage
    resumeVendorProgramOnboarding(vendorProgramId) {
        // Pass the vendorProgramId to the wizard modal
        // It will skip selection and go straight to onboarding for this program
        this.wizardVendorProgramId = vendorProgramId;
        this.showWizardModal = true;
    }

    async startVendorProgramOnboarding(vendorProgramId) {
        try {
            // Get the default process ID
            const processId = await getDefaultVendorProgramOnboardingProcessId();
            
            if (!processId) {
                this.showToast('Error', 'No onboarding process found. Please initialize the default process first.', 'error');
                return;
            }

            // Initialize onboarding for this vendor program
            const result = await initializeVendorProgramOnboarding({ 
                vendorProgramId: vendorProgramId,
                processId: processId
            });

            if (result && result.onboardingId) {
                // Navigate to the onboarding flow
                this[NavigationMixin.Navigate]({
                    type: 'standard__component',
                    attributes: {
                        componentName: 'c__vendorProgramOnboardingFlow'
                    },
                    state: {
                        vendorProgramId: vendorProgramId
                    }
                });
            }
        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to start onboarding. ' + errorMessage, 'error');
        }
    }

    createProgramForVendor(vendorId) {
        // Open the vendor program modal with vendor pre-selected
        this.selectedVendorId = vendorId;
        this.showVendorProgramModal = true;
        this.vendorProgramModalStep = 'vendorSelection';
    }

    // Getters for summary cards (kept for backward compatibility if needed)
    get notStartedCount() {
        return this.summary['Not Started'] || 0;
    }

    get inProcessCount() {
        return this.summary['In Process'] || 0;
    }

    get pendingReviewCount() {
        return this.summary['Pending Initial Review'] || 0;
    }

    get completeCount() {
        return this.summary['Complete'] || this.summary['Setup Complete'] || 0;
    }

    get totalCount() {
        return this.summary['Total'] || 0;
    }

    get eligibleAccountsCount() {
        return this.eligibleAccounts.length;
    }

    get onboardingSummary() {
        return this.summary;
    }

    get eligibleAccountsOptions() {
        return this.eligibleAccounts.map(acc => ({
            label: acc.Name + (acc.Territory ? ' - ' + acc.Territory : ''),
            value: acc.Id
        }));
    }

    // Vendor Program Modal Step Getters
    get isTreeGridStep() {
        return this.vendorProgramModalStep === 'treeGrid';
    }

    get isVendorSelectionStep() {
        return this.vendorProgramModalStep === 'vendorSelection';
    }

    get isVendorProgramSelectionStep() {
        return this.vendorProgramModalStep === 'vendorProgramSelection';
    }

    get vendorProgramOptions() {
        return this.vendorPrograms.map(vp => ({
            label: `${vp.Name} - ${vp.Vendor__r?.Name || 'N/A'} (${vp.Status__c || 'Draft'})`,
            value: vp.Id,
            subtitle: vp.Vendor__r?.Name || ''
        }));
    }

    get recentVendorProgramOptions() {
        return this.recentVendorPrograms.map(vp => ({
            label: `${vp.Name} - ${vp.Vendor__r?.Name || 'N/A'} (${vp.Status__c || 'Draft'})`,
            value: vp.Id,
            subtitle: vp.Vendor__r?.Name || ''
        }));
    }

    get canProceedWithVendorProgram() {
        return !!this.selectedVendorProgramId;
    }

    get cannotProceedWithVendorProgram() {
        return !this.canProceedWithVendorProgram;
    }

    get selectedVendorName() {
        if (!this.selectedVendorId) return '';
        // Find vendor name from vendors list
        const vendor = this.vendors.find(v => v.Id === this.selectedVendorId);
        if (vendor) return vendor.Name;
        // Or return new vendor name if it was just created
        if (this.newVendorName) return this.newVendorName;
        return 'Selected Vendor';
    }

    handleCreateVendorChange(event) {
        this.newVendorName = event.target.value;
    }

    // Filter change handler
    handleFilterChange(event) {
        const { filterType, value } = event.detail;
        
        // Convert single values to arrays for vendor/program filters
        if (filterType === 'vendors' || filterType === 'programs') {
            this.filters[filterType] = value && value.length > 0 ? value : [];
        } else {
            this.filters[filterType] = value;
        }
        
        // Wire methods will automatically refresh when reactive parameters change
    }

    // Tab change handler
    handleTabChange(event) {
        this.activeTab = event.detail.value;
    }

    // KPI tile click handler
    handleKpiTileClick(event) {
        const { metricKey } = event.detail;
        if (metricKey === 'blocked') {
            this.activeTab = 'my-onboarding';
            // Could set a local flag to highlight blocked rows only
        } else if (metricKey === 'activeOnboarding') {
            this.activeTab = 'my-onboarding';
        } else if (metricKey === 'completed') {
            this.activeTab = 'my-onboarding';
        } else if (metricKey === 'activePrograms') {
            this.activeTab = 'programs';
        } else if (metricKey === 'dealersOnboarded') {
            this.activeTab = 'eligible';
        }
    }

    // Component event handlers
    handleViewOnboarding(event) {
        const recordId = event.detail.recordId;
        this.navigateToRecord(recordId);
    }

    handleResumeOnboarding(event) {
        const recordId = event.detail.recordId;
        this.navigateToRecord(recordId);
        // In future, you can pass state to focus on the flow/requirements panel
    }

    handleViewRequirements(event) {
        const recordId = event.detail.recordId;
        // Navigate to onboarding record anchored to requirements panel
        this.navigateToRecord(recordId);
    }

    handleViewProgram(event) {
        const programId = event.detail.programId;
        this.navigateToRecord(programId);
    }

    handleLaunchWizard(event) {
        const programId = event.detail.programId;
        // Navigate to vendor program record and open wizard
        this.wizardVendorProgramId = programId;
        this.showWizardModal = true;
    }

    // Role-based visibility
    get showTeamTab() {
        return this.filters.view === 'MY_TEAM' || this.filters.view === 'ORG_WIDE';
    }

    get showTeamView() {
        // Check if user has permission to see team/org view
        // For now, return true - can be enhanced with permission checks
        return true;
    }

    get hasInsightsComponent() {
        // Insights component is now available
        return true;
    }

    get showAdminSection() {
        return hasAdminPermission === true;
    }

    // Admin quick links to list views
    navigateToValidationFailuresList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Validation_Failure__c',
                actionName: 'list'
            },
            state: { filterName: 'Recent' }
        });
    }

    navigateToMessagingIssuesList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Follow_Up_Queue__c',
                actionName: 'list'
            },
            state: { filterName: 'Recent' }
        });
    }

    navigateToOverrideAuditList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Onboarding_External_Override_Log__c',
                actionName: 'list'
            },
            state: { filterName: 'Recent' }
        });
    }

    // Admin navigation handlers
    handleManageRequirements() {
        // Navigate to requirements management page
        // This would typically be a list view or app page
        this.showToast('Info', 'Navigate to Requirements management page', 'info');
    }

    handleManageStatusRules() {
        // Navigate to status rules engine
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__onboardingStatusRulesEngine'
            }
        });
    }

    handleStageDependencies() {
        // Navigate to stage dependencies management
        this.showToast('Info', 'Navigate to Stage Dependencies management', 'info');
    }

    handleVendorProgramWizard() {
        // Open vendor program wizard
        this.handleStartVendorProgramOnboarding();
    }

    handleComponentLibrary() {
        // Navigate to component library list view
        this.showToast('Info', 'Navigate to Component Library', 'info');
    }

    // Handle row actions for active onboarding table
    handleActiveOnboardingRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'view') {
            this.navigateToRecord(row.Id);
        } else if (action.name === 'resume') {
            this.navigateToRecord(row.Id);
        }
    }

    // Handle row actions for eligible accounts table
    handleEligibleAccountsRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'start') {
            this.startOnboardingForAccount(row.Id);
        } else if (action.name === 'view') {
            this.navigateToRecord(row.Id);
        }
    }

    // Navigate to a record
    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    // Start onboarding for an account
    startOnboardingForAccount(accountId) {
        // Navigate to account record page with quick action
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                actionName: 'view'
            },
            state: {
                actionName: 'Vendor_Onboarding'
            }
        });
    }

    // Handle start dealer onboarding button
    handleStartDealerOnboarding() {
        this.showStartModal = true;
    }

    // Handle start vendor program onboarding button
    // Simply open the wizard modal - it will show the selection tree grid as the first step
    handleStartVendorProgramOnboarding() {
        // Don't pass vendorProgramId - this will show the selection screen first
        this.wizardVendorProgramId = null;
        this.showWizardModal = true;
    }

    // Reset vendor program modal state
    resetVendorProgramModal() {
        this.selectedVendorId = null;
        this.vendors = [];
        this.vendorSearchText = '';
        this.newVendorName = '';
    }

    // Close vendor program modal
    handleCloseVendorProgramModal() {
        this.showVendorProgramModal = false;
        this.vendorProgramModalStep = 'treeGrid';
        this.resetVendorProgramModal();
    }

    // Handle Create New button in tree grid
    handleCreateNewVendorProgram() {
        // Close tree grid modal and open vendor selection modal
        this.vendorProgramModalStep = 'vendorSelection';
    }

    // Load recent vendor programs
    async loadRecentVendorPrograms() {
        try {
            this.recentVendorPrograms = await getRecentVendorPrograms({ limitCount: 5 });
        } catch (error) {
            // Silently fail - recent vendor programs are not critical
        }
    }

    // Vendor Program Selection Methods
    handleVendorProgramSearchChange(event) {
        this.vendorProgramSearchText = event.target.value;
    }

    async handleSearchVendorPrograms() {
        const searchText = this.vendorProgramSearchText?.trim();
        if (!searchText || searchText.length < 2) {
            this.showToast('Search Required', 'Please enter at least 2 characters to search.', 'warning');
            return;
        }

        this.isVendorProgramSearching = true;
        try {
            this.vendorPrograms = await searchVendorPrograms({ vendorProgramNameSearchText: searchText });
            if (this.vendorPrograms.length === 0) {
                this.showToast('No Results', 'No vendor programs found matching your search.', 'info');
            }
        } catch (error) {
            this.showToast('Error', 'Failed to search vendor programs. Please try again.', 'error');
        } finally {
            this.isVendorProgramSearching = false;
        }
    }

    handleVendorProgramSelect(event) {
        this.selectedVendorProgramId = event.detail.value;
    }

    // Handle continue with selected vendor program
    async handleProceedWithVendorProgram() {
        if (!this.selectedVendorProgramId) {
            this.showToast('Vendor Program Required', 'Please select a vendor program to continue.', 'warning');
            return;
        }

        try {
            // Step 1: Get default process
            const processId = await getDefaultVendorProgramOnboardingProcessId();
            
            if (!processId) {
                this.showToast('Process Not Found', 'No Vendor Program Onboarding process found. Please click "Initialize Default Process" first.', 'warning');
                this.handleCloseVendorProgramModal();
                return;
            }

            // Step 2: Initialize onboarding for this vendor program (creates progress if it doesn't exist)
            await initializeVendorProgramOnboarding({
                vendorProgramId: this.selectedVendorProgramId,
                processId: processId
            });

            // Step 3: Close the vendor program selection modal
            this.handleCloseVendorProgramModal();

            // Step 4: Small delay to ensure progress record is committed
            await new Promise(resolve => setTimeout(resolve, 200));

            // Step 5: Open the wizard in a modal (screenflow-like experience)
            this.openWizardModal(this.selectedVendorProgramId);

        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to start onboarding flow. ' + errorMessage, 'error');
        }
    }

    // Vendor selection methods
    handleVendorSearchChange(event) {
        this.vendorSearchText = event.target.value;
    }

    async handleSearchVendors() {
        const searchText = this.vendorSearchText?.trim();
        if (!searchText || searchText.length < 2) {
            this.showToast('Search Required', 'Please enter at least 2 characters to search.', 'warning');
            return;
        }

        this.isVendorSearching = true;
        try {
            this.vendors = await searchVendors({ vendorNameSearchText: searchText });
            if (this.vendors.length === 0) {
                this.showToast('No Results', 'No vendors found matching your search.', 'info');
            }
        } catch (error) {
            this.showToast('Error', 'Failed to search vendors. Please try again.', 'error');
        } finally {
            this.isVendorSearching = false;
        }
    }

    handleVendorSelect(event) {
        this.selectedVendorId = event.detail.value;
        this.newVendorName = '';
    }

    async handleCreateVendor() {
        if (!this.newVendorName || this.newVendorName.trim().length === 0) {
            this.showToast('Name Required', 'Please enter a vendor name.', 'warning');
            return;
        }

        this.isCreatingVendor = true;
        try {
            const vendorId = await createVendor({ vendor: { Name: this.newVendorName.trim() } });
            this.selectedVendorId = vendorId;
            this.vendors = [];
            this.vendorSearchText = '';
            this.newVendorName = '';
            this.showToast('Success', 'Vendor created successfully.', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to create vendor. Please try again.', 'error');
        } finally {
            this.isCreatingVendor = false;
        }
    }

    get vendorOptions() {
        return this.vendors.map(v => ({
            label: v.Name,
            value: v.Id
        }));
    }

    get canProceedWithVendor() {
        return !!this.selectedVendorId;
    }

    get cannotProceedWithVendor() {
        return !this.canProceedWithVendor;
    }

    // Proceed to create vendor program with selected vendor and start onboarding flow
    async handleProceedWithVendor() {
        if (!this.selectedVendorId) {
            this.showToast('Vendor Required', 'Please select or create a vendor to continue.', 'warning');
            return;
        }

        try {
            // Step 1: Create Vendor Program
            const vendorProgramId = await createVendorProgram({
                vendorProgram: { Name: 'New Vendor Program' }, // Name will be set during wizard
                vendorId: this.selectedVendorId
            });

            // Step 2: Get default process and initialize onboarding
            const processId = await getDefaultVendorProgramOnboardingProcessId();
            
            if (!processId) {
                this.showToast('Process Not Found', 'No Vendor Program Onboarding process found. Please create one first or sync the component library.', 'warning');
                // Still navigate to vendor program record
                this.navigateToVendorProgram(vendorProgramId);
                return;
            }

            // Step 3: Initialize onboarding (creates progress record linking process to vendor program)
            await initializeVendorProgramOnboarding({
                vendorProgramId: vendorProgramId,
                processId: processId
            });

            // Step 4: Close vendor selection modal
            this.handleCloseVendorProgramModal();

            // Step 5: Small delay to ensure progress record is committed
            await new Promise(resolve => setTimeout(resolve, 200));

            // Step 6: Open the wizard in a modal (screenflow-like experience)
            this.openWizardModal(vendorProgramId);

        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to create vendor program and start onboarding. ' + errorMessage, 'error');
        }
    }

    // Open wizard in modal (screenflow-like experience)
    openWizardModal(vendorProgramId) {
        this.wizardVendorProgramId = vendorProgramId;
        this.showWizardModal = true;
    }

    // Close wizard modal
    handleCloseWizardModal() {
        this.showWizardModal = false;
        this.wizardVendorProgramId = null;
        // Refresh dashboard to show updated data
        this.handleRefresh();
    }

    // Handle wizard completion
    handleWizardComplete(event) {
        const vendorProgramId = event.detail?.vendorProgramId;
        this.showToast('Success', 'Vendor Program onboarding completed successfully!', 'success');
        this.handleCloseWizardModal();
    }

    // Navigate to vendor program record page (fallback/alternative)
    navigateToVendorProgram(vendorProgramId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: vendorProgramId,
                actionName: 'view'
            },
            state: {
                c__vendorProgramId: vendorProgramId,
                c__startWizard: 'true'
            }
        });
    }

    // Handle close modal
    handleCloseModal() {
        this.showStartModal = false;
        this.selectedAccountId = null;
    }

    // Handle back to tree grid in vendor program modal
    handleBackToTreeGrid() {
        this.vendorProgramModalStep = 'treeGrid';
        this.selectedVendorProgramId = null;
        this.vendorPrograms = [];
    }

    // Handle account selection in modal
    handleAccountSelect(event) {
        this.selectedAccountId = event.detail.value;
    }

    // Confirm and start onboarding
    handleConfirmStart() {
        if (this.selectedAccountId) {
            this.startOnboardingForAccount(this.selectedAccountId);
            this.handleCloseModal();
        } else {
            this.showToast('Selection Required', 'Please select an account to start onboarding.', 'warning');
        }
    }

    // Show toast message
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // Refresh data
    handleRefresh() {
        // Force refresh by updating tracked properties
        this.isLoading = true;
        // The @wire will automatically refresh when dependencies change
        // For now, just set loading state
        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
        // Also refresh vendor hierarchy
        this.loadVendorHierarchy();
    }

    // Sync Component Library
    async handleSyncComponentLibrary() {
        this.isSyncingComponentLibrary = true;
        try {
            const message = await syncComponentLibrary();
            this.showToast('Success', message, 'success');
        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to sync Component Library. ' + errorMessage, 'error');
        } finally {
            this.isSyncingComponentLibrary = false;
        }
    }

    // Initialize default Vendor Program Onboarding process
    async handleInitializeDefaultProcess() {
        this.isInitializingProcess = true;
        try {
            const message = await initializeDefaultProcess();
            this.showToast('Success', message, 'success');
            // Refresh the page after a short delay to ensure process is available
            setTimeout(() => {
                this.handleRefresh();
            }, 1000);
        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to initialize default process. ' + errorMessage, 'error');
        } finally {
            this.isInitializingProcess = false;
        }
    }
}
