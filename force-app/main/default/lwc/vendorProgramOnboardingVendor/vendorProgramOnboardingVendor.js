import { api, track, wire } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import searchVendors from '@salesforce/apex/VendorOnboardingWizardController.searchVendors';
import createVendorApex from '@salesforce/apex/VendorOnboardingWizardController.createVendor';

export default class VendorProgramOnboardingStepOne extends OnboardingStepBase {
  stepName = 'Select or Create Vendor';
  
  @track searchText = '';
  @track vendorOptions = [];
  @track selectedVendorId = '';
  @track newVendorName = '';
  @track nextDisabled = true;
  @track isLoading = false;

  // Debounce timer for autocomplete
  searchTimeout;
  @track debouncedSearchText = '';

  // Wire adapter for autocomplete - updates when debouncedSearchText changes
  @wire(searchVendors, { vendorNameSearchText: '$debouncedSearchText' })
  wiredVendors({ error, data }) {
    if (data) {
      this.vendorOptions = data.map(v => ({
        label: v.Name,
        value: v.Id
      }));
      this.isLoading = false;
    } else if (error) {
      this.handleError(error, 'Failed to search vendors');
      this.vendorOptions = [];
      this.isLoading = false;
    } else {
      // Still loading or no data yet
      if (this.debouncedSearchText && this.debouncedSearchText.length >= 2) {
        // We're waiting for results
      } else {
        // No search text, clear options
        this.vendorOptions = [];
        this.isLoading = false;
      }
    }
  }

  handleSearchChange(e) {
    // This handles typing in the input field
    const searchValue = e.target.value || '';
    this.searchText = searchValue;
    
    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    // If search text is cleared, clear options
    if (!searchValue || searchValue.trim().length === 0) {
      this.debouncedSearchText = '';
      this.vendorOptions = [];
      this.selectedVendorId = '';
      this.nextDisabled = true;
      this.dispatchValidationState();
      return;
    }

    // Debounce: wait 300ms after user stops typing before searching
    // Require at least 2 characters for autocomplete
    if (searchValue.trim().length >= 2) {
      this.isLoading = true;
      this.searchTimeout = setTimeout(() => {
        this.debouncedSearchText = searchValue.trim();
      }, 300);
    } else {
      this.debouncedSearchText = '';
      this.vendorOptions = [];
      this.selectedVendorId = '';
      this.nextDisabled = true;
      this.dispatchValidationState();
    }
  }

  handleNewVendorChange(e) {
    this.newVendorName = e.target.value;
  }

  handleVendorSelect(e) {
    this.selectedVendorId = e.detail.value;
    this.newVendorName = '';
    this.nextDisabled = false;
    this.dispatchValidationState();
    
    // Update search text to show selected vendor name
    const selectedOption = this.vendorOptions.find(opt => opt.value === e.detail.value);
    if (selectedOption) {
      this.searchText = selectedOption.label;
    }
    
    // Clear the search timeout since selection was made
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
  }

  async createVendor() {
    if (!this.newVendorName || this.newVendorName.trim().length === 0) return;
    try {
      const vendorId = await createVendorApex({ vendor: { Name: this.newVendorName.trim() } });
      this.selectedVendorId = vendorId;
      this.searchText = this.newVendorName.trim();
      this.vendorOptions = [{
        label: this.newVendorName.trim(),
        value: vendorId
      }];
      this.newVendorName = ''; // Clear input
      this.nextDisabled = false;
      this.dispatchValidationState();
    } catch (err) {
      this.handleError(err, 'Failed to create vendor');
    }
  }

  get canProceed() {
    return !this.nextDisabled;
  }

  proceedToNext() {
    this.dispatchNextEvent({
      vendorId: this.selectedVendorId
    });
  }

  get vendorCountText() {
    const count = this.vendorOptions.length;
    return `${count} vendor${count === 1 ? '' : 's'} found`;
  }

  get hasSearchResults() {
    return this.vendorOptions.length > 0 && this.searchText && this.searchText.trim().length >= 2;
  }

  get hasNoResults() {
    return this.vendorOptions.length === 0 && this.searchText && this.searchText.trim().length >= 2 && !this.isLoading;
  }
}
