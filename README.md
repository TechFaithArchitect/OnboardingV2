# Onboarding V2 - Salesforce Application

A comprehensive, metadata-driven onboarding system for managing vendor program onboarding processes in Salesforce. This application provides a flexible, configurable framework for guiding users through structured onboarding flows with full auditability and progress tracking.

## 📚 Documentation

Complete documentation is available in the [`docs/`](./docs/) directory:

### 📋 Recent Updates

- **[DRY Refactoring Changelog](./docs/reports/CHANGELOG-dry-refactoring.md)** - Comprehensive refactoring eliminating ~700+ lines of duplicate code across all wizard step components
- **[Wizard UX Improvements Changelog](./docs/reports/CHANGELOG-wizard-ux-improvements.md)** - Latest improvements including required fields visibility, form validation, and progress saving fixes

- **[Architecture Overview](./docs/architecture/overview.md)** - System architecture and design patterns
- **[Data Model](./docs/architecture/data-model.md)** - Custom objects and relationships
- **[Components](./docs/components/)** - Lightning Web Components documentation
- **[Apex Classes](./docs/components/apex-classes.md)** - Service layer and business logic
- **[Flows](./docs/processes/flows.md)** - Automation and business processes
- **[Onboarding Process](./docs/processes/onboarding-process.md)** - Main onboarding workflow
- **[Status Rules Engine](./docs/processes/status-evaluation.md)** - Rules-based status evaluation
- **[Setup Guide](./docs/setup/installation.md)** - Installation and configuration

## 🚀 Quick Start

1. Deploy the metadata to your Salesforce org
2. Configure onboarding processes via Custom Objects
3. Assign processes to Vendor Programs
4. Create a Lightning Home Page and add the `onboardingHomeDashboard` component
5. Add `vendorProgramOnboardingFlow` component to Vendor Program Lightning Record Pages

## 📁 Project Structure
force-app/
├── main/default/
│ ├── classes/ # Apex classes (services, controllers, handlers)
│ ├── lwc/ # Lightning Web Components
│ ├── flows/ # Salesforce Flows
│ ├── triggers/ # Apex triggers
│ └── objects/ # Custom object metadata
└── unpackaged/ # Additional metadata

## 🔗 Related Documentation

- [Onboarding Application Framework](./Onboarding_Application_Documentation.txt)
- [Core Concepts](./Onboarding%20Core%20Concepts%20and%20Purpose.docx)
- [Rules Engine Summary](./Onboarding%20Rules%20Engine%20Executive%20Summary.docx)
- [Vendor Program Documentation](./Vendor_Program_Onboarding_Documentation.docx)

## 🛠️ Development

This is a Salesforce DX project. See the [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm) for setup instructions.

## 📝 License

[Your License Here]
