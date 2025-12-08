@isTest
public class TestOnboardingRequirementFactory {

    public static Onboarding_Requirement__c create(
        Boolean doInsert,
        Boolean completed,
        Boolean isInherited,
        Boolean isOverridden,
        Onboarding__c onboarding,
        String requirementType,
        Boolean requiresFiles,
        Integer sequence,
        String status,
        Vendor_Program_Requirement__c vendorProgramRequirement
    ) {
        Onboarding_Requirement__c onboardingRequirement = new Onboarding_Requirement__c(
            Completed__c = completed != null ? completed : false,
            Is_Inherited__c = isInherited != null ? isInherited : false,
            Is_Overridden__c = isOverridden != null ? isOverridden : false,
            Onboarding__c = onboarding != null ? onboarding.Id : null,
            Requirement_Type__c = String.isNotBlank(requirementType) ? requirementType : 'Status',
            Requires_Files__c = requiresFiles != null ? requiresFiles : false,
            Sequence__c = sequence != null ? sequence : 1,
            Status__c = String.isNotBlank(status) ? status : 'In Process',
            Vendor_Program_Requirement__c = vendorProgramRequirement != null ? vendorProgramRequirement.Id : null
        );

        TestDataFactoryUtil.maybeInsert(onboardingRequirement, doInsert);
        return onboardingRequirement;
    }

    public static Onboarding_Requirement__c create(
        Boolean doInsert,
        Onboarding__c onboarding,
        Vendor_Program_Requirement__c vendorProgramRequirement
    ) {
        return create(
            doInsert,
            false,      
            false,      
            false,      
            onboarding,
            'Status',   
            false,      
            1,          
            'In Process',
            vendorProgramRequirement
        );
    }

    public static Onboarding_Requirement__c create(Boolean doInsert) {
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Acct', doInsert),
            TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization,
            doInsert
        );

        Vendor_Program_Requirement__c vendorProgramRequirement = TestVendorProgramRequirementFactory.create(doInsert);

        return create(doInsert, onboarding, vendorProgramRequirement);
    }
}
