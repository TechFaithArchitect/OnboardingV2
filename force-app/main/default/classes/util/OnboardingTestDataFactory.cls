/**
 * Convenience factory for common onboarding test setups.
 * Wraps existing TestDataFactory helpers with opinionated defaults.
 */
public with sharing class OnboardingTestDataFactory {

    public class RequirementContext {
        public Account account;
        public Vendor__c vendor;
        public Vendor_Customization__c vendorProgram;
        public Onboarding__c onboarding;
        public Onboarding_Requirement__c requirement;
        public Requirement_Field__c requirementField;
    }

    public static RequirementContext createRequirementContext(Boolean doInsert) {
        RequirementContext ctx = new RequirementContext();
        ctx.account = TestDataFactory.createAccount('Onboarding Account', doInsert);
        ctx.vendor = TestVendorFactory.createVendor(doInsert);
        ctx.vendorProgram = TestVendorProgramFactory.createVendorCustomization(ctx.vendor, 'Active', true, null, doInsert);
        ctx.onboarding = TestOnboardingFactory.create(ctx.account, ctx.vendorProgram, doInsert);
        ctx.requirement = TestOnboardingRequirementFactory.create(doInsert, ctx.onboarding, null);
        ctx.requirementField = new Requirement_Field__c(
            Field_API_Name__c = 'Test_Field__c',
            Required__c = false,
            Validation_Type__c = 'None'
        );
        if (doInsert) {
            insert ctx.requirementField;
        }
        return ctx;
    }
}
