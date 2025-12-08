public with sharing class VendorOnboardingFlowService {

    @InvocableMethod(label='Get Eligible Vendors for Onboarding')
    public static List<List<VendorOptionDTO>> getEligibleVendors(List<Id> accountIds) {
        List<List<VendorOptionDTO>> allResults = new List<List<VendorOptionDTO>>();
        VendorPrerequisiteEvaluator.PrereqMap prereqMap = VendorPrerequisiteEvaluator.getActivePrerequisites();

        for (Id accountId : accountIds) {
            List<VendorOptionDTO> result = new List<VendorOptionDTO>();

            // ✅ Get already onboarded vendor program IDs and the associated vendor IDs
            Set<Id> onboardedVendorIds = new Set<Id>();
            Set<Id> onboardedCustomizationIds = new Set<Id>();

            for (Onboarding__c onboarding : [
                SELECT Vendor_Customization__r.Vendor__c, Vendor_Customization__c
                FROM Onboarding__c
                WHERE Account__c = :accountId AND Vendor_Customization__c != null
            ]) {
                onboardedCustomizationIds.add(onboarding.Vendor_Customization__c);
                if (onboarding.Vendor_Customization__r.Vendor__c != null) {
                    onboardedVendorIds.add(onboarding.Vendor_Customization__r.Vendor__c);
                }
            }

            // ✅ Get eligible vendors (not onboarded yet)
            List<Vendor__c> eligibleVendors = [
                SELECT Id, Name
                FROM Vendor__c
                WHERE Active__c = true AND Id NOT IN :onboardedVendorIds
            ];

            Map<Id, Vendor__c> vendorMap = new Map<Id, Vendor__c>();
            for (Vendor__c v : eligibleVendors) {
                vendorMap.put(v.Id, v);
            }

            // ✅ Map retail options to business verticals per vendor
            Map<Id, Map<String, Set<String>>> vendorRetailMap = new Map<Id, Map<String, Set<String>>>();

            for (Vendor_Customization__c vc : [
                SELECT Id, Vendor__c, Retail_Option__c, Business_Vertical__c
                FROM Vendor_Customization__c
                WHERE Vendor__c IN :eligibleVendors
            ]) {
                // ✅ Prerequisite check
                if (!VendorPrerequisiteEvaluator.isCustomizationEligible(vc.Id, onboardedCustomizationIds, prereqMap)) {
                    continue;
                }

                if (String.isBlank(vc.Retail_Option__c)) continue;

                if (!vendorRetailMap.containsKey(vc.Vendor__c)) {
                    vendorRetailMap.put(vc.Vendor__c, new Map<String, Set<String>>());
                }

                Map<String, Set<String>> retailToVerticals = vendorRetailMap.get(vc.Vendor__c);

                if (!retailToVerticals.containsKey(vc.Retail_Option__c)) {
                    retailToVerticals.put(vc.Retail_Option__c, new Set<String>());
                }

                if (!String.isBlank(vc.Business_Vertical__c)) {
                    retailToVerticals.get(vc.Retail_Option__c).add(vc.Business_Vertical__c);
                }
            }

            // ✅ Build DTOs
            for (Id vendorId : vendorRetailMap.keySet()) {
                Vendor__c vendor = vendorMap.get(vendorId);
                Map<String, Set<String>> retailOptions = vendorRetailMap.get(vendorId);

                for (String retailOption : retailOptions.keySet()) {
                    VendorOptionDTO dto = new VendorOptionDTO();
                    dto.vendorId = vendor.Id;
                    dto.vendorName = vendor.Name;
                    dto.retailOption = retailOption;
                    dto.businessVerticals = new List<String>(retailOptions.get(retailOption));

                    result.add(dto);
                }
            }

            allResults.add(result);
        }

        return allResults;
    }
}