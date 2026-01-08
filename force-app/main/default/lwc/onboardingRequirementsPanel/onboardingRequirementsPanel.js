import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { extractErrorMessage } from "c/utils";
import getRequirements from "@salesforce/apex/OnboardingRequirementsPanelController.getRequirements";
import getInvalidFieldValues from "@salesforce/apex/OnboardingRequirementsPanelController.getInvalidFieldValues";
import updateRequirementStatuses from "@salesforce/apex/OnboardingRequirementsPanelController.updateRequirementStatuses";
import runRuleEvaluation from "@salesforce/apex/OnboardingRequirementsPanelController.runRuleEvaluation";
import rerunValidation from "@salesforce/apex/OnboardingRequirementsPanelController.rerunValidation";

export default class OnboardingRequirementsPanel extends LightningElement {
  @api recordId; // Set automatically on a Record Page
  @track requirements = [];
  @track invalidFields = [];
  @track loading = true;

  statusOptions = [
    { label: "Not Started", value: "Not Started" },
    { label: "Incomplete", value: "Incomplete" },
    { label: "Complete", value: "Complete" },
    { label: "Approved", value: "Approved" },
    { label: "Denied", value: "Denied" }
  ];

  connectedCallback() {
    this.loadData();
  }

  async loadData() {
    this.loading = true;
    try {
      const [requirements, invalidFieldValues] = await Promise.all([
        getRequirements({ onboardingId: this.recordId }),
        getInvalidFieldValues({ onboardingId: this.recordId })
      ]);
      this.requirements = (requirements || []).map((requirement) => ({
        ...requirement
      }));
      this.invalidFields = invalidFieldValues || [];
    } catch (error) {
      this.showToast(
        "Error",
        extractErrorMessage(error, "Failed to load onboarding requirements."),
        "error"
      );
      this.requirements = [];
      this.invalidFields = [];
    } finally {
      this.loading = false;
    }
  }

  handleStatusChange(event) {
    const id = event.target.name;
    const value = event.detail.value;
    const requirement = this.requirements.find((r) => r.Id === id);
    if (requirement) requirement.Status = value;
  }

  async submit() {
    if (!this.requirements || !this.requirements.length) {
      return;
    }

    try {
      await updateRequirementStatuses({ updates: this.requirements });
      await runRuleEvaluation({ onboardingId: this.recordId });
      await this.loadData();
      this.showToast(
        "Success",
        "Requirement statuses updated and rules evaluated.",
        "success"
      );
    } catch (error) {
      this.showToast(
        "Error",
        extractErrorMessage(
          error,
          "An error occurred while processing requirements."
        ),
        "error"
      );
    }
  }

  async rerunSelected() {
    const ids = (this.invalidFields || []).map((f) => f.fieldValueId);
    if (!ids.length) {
      return;
    }
    try {
      await rerunValidation({ fieldValueIds: ids });
      await this.loadData();
      this.showToast(
        "Success",
        "Validation re-run for invalid fields.",
        "success"
      );
    } catch (error) {
      this.showToast(
        "Error",
        extractErrorMessage(
          error,
          "An error occurred while re-running validation."
        ),
        "error"
      );
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
}
