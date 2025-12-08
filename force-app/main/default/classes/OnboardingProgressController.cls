public with sharing class OnboardingProgressController {
    @AuraEnabled(cacheable=true)
    public static Integer getCompletionPercent(Id recordId) {
        List<Onboarding__c> onboardingRaw = [
            SELECT
                Contract__c,
                Agreement_Status__c,
                Assigned_Team__c,
                Background_Check_Status__c,
                Business_License_Status__c,
                Chuzo_Agreement_Status__c,
                Clearing_House_Status__c,
                Contract_Status__c,
                Compliance_Status__c,
                Credit_Check_Status__c,
                Drivers_Licenses_Status__c,
                ERP_Setup_Status__c,
                Labor_Form_Status__c,
                LearnUpon_Training_Status__c,
                Net_Terms_Status__c,
                Terms_Conditions_Status__c,
                Personal_Guarantee_Status__c,
                Vendor_Order_Entry_Setup_Status__c,
                Insurance_Status__c,
                Vendor_Customization__r.Retail_Option__c
            FROM Onboarding__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        List<Onboarding__c> onboardingList = (List<Onboarding__c>) Security.stripInaccessible(AccessType.READABLE, onboardingRaw).getRecords();
        if (onboardingList.isEmpty()) return 0;

        Onboarding__c onboarding = onboardingList[0];

        String contractType;
        if (onboarding.Contract__c != null) {
            List<Contract> contracts = [
                SELECT Contract_Type__c
                FROM Contract
                WHERE Id = :onboarding.Contract__c
                LIMIT 1
            ];
            if (!contracts.isEmpty()) {
                contractType = contracts[0].Contract_Type__c;
            }
        }

        Integer completeCount = 0;
        Integer total = 0;

        if (contractType == 'NDA') {
            // Only 2 fields matter for NDA
            total = 2;
            if (onboarding.Agreement_Status__c == 'Signed') {
                completeCount++;
            }
            if (onboarding.Contract_Status__c == 'Activated') {
                completeCount++;
            }
        } else if (contractType == 'Program Base Application - with Chuzo' || contractType == 'Program Base Application - with Chuzo (No Personal Guarantee)') {
            // Full logic for non-NDA
            total = 15;

            Map<String, String> standardFields = new Map<String, String>{
                'Agreement_Status__c' => onboarding.Agreement_Status__c,
                'Background_Check_Status__c' => onboarding.Background_Check_Status__c,
                'Business_License_Status__c' => onboarding.Business_License_Status__c,
                'Chuzo_Agreement_Status__c' => onboarding.Chuzo_Agreement_Status__c,
                'Clearing_House_Status__c' => onboarding.Clearing_House_Status__c,
                'Compliance_Status__c' => onboarding.Compliance_Status__c,
                'Contract_Status__c' => onboarding.Contract_Status__c,
                'Credit_Check_Status__c' => onboarding.Credit_Check_Status__c,
                'Drivers_Licenses_Status__c' => onboarding.Drivers_Licenses_Status__c,
                'ERP_Setup_Status__c' => onboarding.ERP_Setup_Status__c,
                'Labor_Form_Status__c' => onboarding.Labor_Form_Status__c,
                'LearnUpon_Training_Status__c' => onboarding.LearnUpon_Training_Status__c,
                'Net_Terms_Status__c' => onboarding.Net_Terms_Status__c,
                'Personal_Guarantee_Status__c' => onboarding.Personal_Guarantee_Status__c,
                'Terms_Conditions_Status__c' => onboarding.Terms_Conditions_Status__c  
            };
            if (onboarding.Agreement_Status__c == 'Signed') {
                completeCount++;
            }
            if (onboarding.Background_Check_Status__c == 'Complete' ||
                onboarding.Background_Check_Status__c == 'Waived') {
                completeCount++;
            }
            if (onboarding.Business_License_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.Chuzo_Agreement_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.Clearing_House_Status__c != null &&
                (onboarding.Clearing_House_Status__c == 'Accounting Approved' ||
                 onboarding.Clearing_House_Status__c == 'Onboarding Approved' ||
                 onboarding.Clearing_House_Status__c == 'Accounting Denied'   ||
                 onboarding.Clearing_House_Status__c == 'Check Vendor')) {
                completeCount++;
            }
            if (onboarding.Compliance_Status__c == 'Approved' ||
                onboarding.Compliance_Status__c == 'Approved Conditionally') {
                completeCount++;
            }
            if (onboarding.Contract_Status__c == 'Activated') {
                completeCount++;
            }
            if (onboarding.Credit_Check_Status__c == 'Complete' ||
                onboarding.Credit_Check_Status__c == 'Waived') {
                completeCount++;
            }
            if (onboarding.Drivers_Licenses_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.ERP_Setup_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.Clearing_House_Status__c != null &&(
                onboarding.Labor_Form_Status__c == 'Onboarding Approved' ||
                onboarding.Labor_Form_Status__c == 'Approved Box 1' ||
                onboarding.Labor_Form_Status__c == 'Approved Box 2')) {
                completeCount++;
            }
            if (onboarding.LearnUpon_Training_Status__c == 'Completed' ||
                onboarding.LearnUpon_Training_Status__c == 'Passed') {
                completeCount++;
            }
            if (onboarding.Net_Terms_Status__c == 'Approved' ||
                onboarding.Net_Terms_Status__c == 'N/A') {
                completeCount++;
            }
            if (onboarding.Personal_Guarantee_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.Terms_Conditions_Status__c == 'Complete') {
                completeCount++;
            }
        }
        else if (contractType == 'Program Base Application - without Chuzo') {
            // Full logic for non-NDA
            total = 13;

            Map<String, String> standardFields = new Map<String, String>{
                'Agreement_Status__c' => onboarding.Agreement_Status__c,
                'Background_Check_Status__c' => onboarding.Background_Check_Status__c,
                'Business_License_Status__c' => onboarding.Business_License_Status__c,
                'Clearing_House_Status__c' => onboarding.Clearing_House_Status__c,
                'Compliance_Status__c' => onboarding.Compliance_Status__c,
                'Contract_Status__c' => onboarding.Contract_Status__c,
                'Credit_Check_Status__c' => onboarding.Credit_Check_Status__c,
                'Drivers_Licenses_Status__c' => onboarding.Drivers_Licenses_Status__c,
                'ERP_Setup_Status__c' => onboarding.ERP_Setup_Status__c,
                'Labor_Form_Status__c' => onboarding.Labor_Form_Status__c,
                'Net_Terms_Status__c' => onboarding.Net_Terms_Status__c,
                'Terms_Conditions_Status__c' => onboarding.Terms_Conditions_Status__c,
                'Personal_Guarantee_Status__c' => onboarding.Personal_Guarantee_Status__c  
            };
            if (onboarding.Agreement_Status__c == 'Signed') {
                completeCount++;
            }
            if (onboarding.Background_Check_Status__c == 'Complete' ||
                onboarding.Background_Check_Status__c == 'Waived') {
                completeCount++;
            }
            if (onboarding.Business_License_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.Clearing_House_Status__c != null &&
                (onboarding.Clearing_House_Status__c == 'Accounting Approved' ||
                 onboarding.Clearing_House_Status__c == 'Onboarding Approved' ||
                 onboarding.Clearing_House_Status__c == 'Accounting Denied'   ||
                 onboarding.Clearing_House_Status__c == 'Check Vendor')) {
                completeCount++;
            }
            if (onboarding.Compliance_Status__c == 'Approved' ||
                onboarding.Compliance_Status__c == 'Approved Conditionally') {
                completeCount++;
            }
            if (onboarding.Contract_Status__c == 'Activated') {
                completeCount++;
            }
            if (onboarding.Credit_Check_Status__c == 'Complete' ||
                onboarding.Credit_Check_Status__c == 'Waived') {
                completeCount++;
            }
            if (onboarding.Drivers_Licenses_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.ERP_Setup_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.Clearing_House_Status__c != null &&(
                onboarding.Labor_Form_Status__c == 'Onboarding Approved' ||
                onboarding.Labor_Form_Status__c == 'Approved Box 1' ||
                onboarding.Labor_Form_Status__c == 'Approved Box 2')) {
                completeCount++;
            }
            if (onboarding.Net_Terms_Status__c == 'Approved' ||
                onboarding.Net_Terms_Status__c == 'N/A') {
                completeCount++;
            }
            if (onboarding.Personal_Guarantee_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.Terms_Conditions_Status__c == 'Complete') {
                completeCount++;
            }
        }
        else if(contractType == 'Vendor' && onboarding.Vendor_Customization__r.Retail_Option__c != 'Amendment') {
            total = 6;
            Map<String, String> standardFields = new Map<String, String>{
                'Agreement_Status__c' => onboarding.Agreement_Status__c,
                'Contract_Status__c' => onboarding.Contract_Status__c,
                'ERP_Setup_Status__c' => onboarding.ERP_Setup_Status__c,
                'Insurance_Status__c' => onboarding.Insurance_Status__c,
                'LearnUpon_Training_Status__c' => onboarding.LearnUpon_Training_Status__c,
                'Vendor_Order_Entry_Setup_Status__c' => onboarding.Vendor_Order_Entry_Setup_Status__c
            };
            if (onboarding.Agreement_Status__c == 'Signed') {
                completeCount++;
            }
            if (onboarding.Contract_Status__c == 'Activated') {
                completeCount++;
            }
            if (onboarding.ERP_Setup_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.Insurance_Status__c == 'Complete') {
                completeCount++;
            }
            if (onboarding.LearnUpon_Training_Status__c == 'Completed' ||
                onboarding.LearnUpon_Training_Status__c == 'Passed') {
                completeCount++;
            }   
            if (onboarding.Vendor_Order_Entry_Setup_Status__c == 'Complete') {
                completeCount++;
            }         
        }
        else if(contractType == 'Vendor' && onboarding.Vendor_Customization__r.Retail_Option__c == 'Amendment') {
            total = 1;
            Map<String, String> standardFields = new Map<String, String>{
                'Contract_Status__c' => onboarding.Contract_Status__c
            };
            if (onboarding.Contract_Status__c == 'Activated') {
                completeCount++;
            }         
        }
        if (total == 0) {
            return 0;
        }
        // Calculate percentage
        Integer percent = Math.round((Decimal.valueOf(completeCount) / total) * 100);
        return percent;
    }
}