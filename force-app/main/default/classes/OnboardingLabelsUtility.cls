public class OnboardingLabelsUtility {
    private static Map<String, String> labelMap = new Map<String, String>{
        'AgreementAutomation_Subject_Stale' => Label.AgreementAutomation_Subject_Stale,
        'AgreementAutomation_Subject_ToBeClosed' => Label.AgreementAutomation_Subject_ToBeClosed,
        'AgreementAutomation_Description_Stale' => Label.AgreementAutomation_Description_Stale,
        'AgreementAutomation_Description_ToBeClosed' => Label.AgreementAutomation_Description_ToBeClosed,

        'BackgroundCheck_Subject_Stale' => Label.BackgroundCheck_Subject_Stale,
        'BackgroundCheck_Subject_ToBeClosed' => Label.BackgroundCheck_Subject_ToBeClosed,
        'BackgroundCheck_Description_Stale' => Label.BackgroundCheck_Description_Stale,
        'BackgroundCheck_Description_ToBeClosed' => Label.BackgroundCheck_Description_ToBeClosed,

        'BusinessLicense_Subject_Stale' => Label.BusinessLicense_Subject_Stale,
        'BusinessLicense_Subject_ToBeClosed' => Label.BusinessLicense_Subject_ToBeClosed,
        'BusinessLicense_Description_Stale' => Label.BusinessLicense_Description_Stale,
        'BusinessLicense_Description_ToBeClosed' => Label.BusinessLicense_Description_ToBeClosed,

        'ClearingHouse_Subject_Stale' => Label.ClearingHouse_Subject_Stale,
        'ClearingHouse_Subject_ToBeClosed' => Label.ClearingHouse_Subject_ToBeClosed,
        'ClearingHouse_Description_Stale' => Label.ClearingHouse_Description_Stale,
        'ClearingHouse_Description_ToBeClosed' => Label.ClearingHouse_Description_ToBeClosed,

        'Contract_Subject_Stale' => Label.Contract_Subject_Stale,
        'Contract_Subject_ToBeClosed' => Label.Contract_Subject_ToBeClosed,
        'Contract_Description_Stale' => Label.Contract_Description_Stale,
        'Contract_Description_ToBeClosed' => Label.Contract_Description_ToBeClosed,

        'CreditCheck_Subject_Stale' => Label.CreditCheck_Subject_Stale,
        'CreditCheck_Subject_ToBeClosed' => Label.CreditCheck_Subject_ToBeClosed,
        'CreditCheck_Description_Stale' => Label.CreditCheck_Description_Stale,
        'CreditCheck_Description_ToBeClosed' => Label.CreditCheck_Description_ToBeClosed,

        'DealerCompliance_Subject_Stale' => Label.DealerCompliance_Subject_Stale,
        'DealerCompliance_Subject_ToBeClosed' => Label.DealerCompliance_Subject_ToBeClosed,
        'DealerCompliance_Description_Stale' => Label.DealerCompliance_Description_Stale,
        'DealerCompliance_Description_ToBeClosed' => Label.DealerCompliance_Description_ToBeClosed,

        'DriversLicense_Subject_Stale' => Label.DriversLicense_Subject_Stale,
        'DriversLicense_Subject_ToBeClosed' => Label.DriversLicense_Subject_ToBeClosed,
        'DriversLicense_Description_Stale' => Label.DriversLicense_Description_Stale,
        'DriversLicense_Description_ToBeClosed' => Label.DriversLicense_Description_ToBeClosed,

        'ERPSetupStatus_Subject_Stale' => Label.ERPSetupStatus_Subject_Stale,
        'ERPSetupStatus_Subject_ToBeClosed' => Label.ERPSetupStatus_Subject_ToBeClosed,
        'ERPSetupStatus_Description_Stale' => Label.ERPSetupStatus_Description_Stale,
        'ERPSetupStatus_Description_ToBeClosed' => Label.ERPSetupStatus_Description_ToBeClosed,

        'LaborForm_Subject_Stale' => Label.LaborForm_Subject_Stale,
        'LaborForm_Subject_ToBeClosed' => Label.LaborForm_Subject_ToBeClosed,
        'LaborForm_Description_Stale' => Label.LaborForm_Description_Stale,
        'LaborForm_Description_ToBeClosed' => Label.LaborForm_Description_ToBeClosed,

        'NetTerms_Subject_Stale' => Label.NetTerms_Subject_Stale,
        'NetTerms_Subject_ToBeClosed' => Label.NetTerms_Subject_ToBeClosed,
        'NetTerms_Description_Stale' => Label.NetTerms_Description_Stale,
        'NetTerms_Description_ToBeClosed' => Label.NetTerms_Description_ToBeClosed,

        'VendorOrderEntryPlatform_Subject_Stale' => Label.VendorOrderEntryPlatform_Subject_Stale,
        'VendorOrderEntryPlatform_Subject_ToBeClosed' => Label.VendorOrderEntryPlatform_Subject_ToBeClosed,
        'VendorOrderEntryPlatform_Description_Stale' => Label.VendorOrderEntryPlatform_Description_Stale,
        'VendorOrderEntryPlatform_Description_ToBeClosed' => Label.VendorOrderEntryPlatform_Description_ToBeClosed,

        'OnboardingAutomation_Subject_Stale' => Label.OnboardingAutomation_Subject_Stale,
        'OnboardingAutomation_Subject_ToBeClosed' => Label.OnboardingAutomation_Subject_ToBeClosed,
        'OnboardingAutomation_Description_Stale' => Label.OnboardingAutomation_Description_Stale,
        'OnboardingAutomation_Description_ToBeClosed' => Label.OnboardingAutomation_Description_ToBeClosed
    };

    public static String getLabel(String name) {
        if (Test.isRunningTest()) {
            return 'Test Label - ' + name;
        }
        return labelMap.containsKey(name) ? labelMap.get(name) : '[Missing Label: ' + name + ']';
    }
}