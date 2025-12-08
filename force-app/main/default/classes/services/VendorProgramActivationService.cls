public with sharing class VendorProgramActivationService {

    @AuraEnabled
    public static void activate(Id recordId) {
        ValidationHelper.requireId(recordId, 'Record ID');
        
        // Apply activation rules before activation
        List<OnboardingAppActivationRule> rules =
            OnboardingAppRuleRegistry.getActivationRulesForObject('Vendor_Customization__c');
        for (OnboardingAppActivationRule rule : rules) {
            rule.apply(recordId, 'Vendor_Customization__c');
        }

        Vendor_Customization__c record = VendorCustomizationRepository.getById(recordId);

        if (record.Status__c == 'Active') {
            // Program is already active - throw exception without debug log
            throw new AuraHandledException('Program is already active.');
        }

        // Deactivate siblings, enforce Vendor-specific constraints, do vendor-specific post-processing
        deactivateSiblings(record);
        record.Status__c = 'Active';
        record.Active__c = true;
        VendorCustomizationRepository.updateRecord(record);

        postActivate(record);
    }

    /**
     * Activates multiple vendor programs in bulk for better performance.
     *
     * @param recordIds Set of Vendor_Customization__c record IDs to activate
     */
    public static void activateBulk(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        // Apply activation rules in bulk
        List<OnboardingAppActivationRule> rules =
            OnboardingAppRuleRegistry.getActivationRulesForObject('Vendor_Customization__c');
        for (OnboardingAppActivationRule rule : rules) {
            rule.applyBulk(recordIds, 'Vendor_Customization__c');
        }

        // Query all records in one query
        List<Vendor_Customization__c> records = VendorCustomizationRepository.getByIds(recordIds);

        // Collect all parent version IDs for sibling deactivation
        Set<Id> parentVersionIds = new Set<Id>();
        for (Vendor_Customization__c record : records) {
            if (record.Status__c == 'Active') {
                throw new AuraHandledException('Program ' + record.Id + ' is already active.');
            }
            if (record.Previous_Version__c != null) {
                parentVersionIds.add(record.Previous_Version__c);
            }
        }

        // Deactivate all siblings in bulk
        if (!parentVersionIds.isEmpty()) {
            List<Vendor_Customization__c> siblingsToDeactivate = new List<Vendor_Customization__c>();
            for (Id parentVersionId : parentVersionIds) {
                List<Vendor_Customization__c> siblings = 
                    VendorCustomizationRepository.getActiveSiblingsByParentVersion(parentVersionId, recordIds);
                
                // Filter out the records being activated
                for (Vendor_Customization__c sibling : siblings) {
                    if (!recordIds.contains(sibling.Id)) {
                        sibling.Active__c = false;
                        siblingsToDeactivate.add(sibling);
                    }
                }
            }

            if (!siblingsToDeactivate.isEmpty()) {
                VendorCustomizationRepository.updateRecords(siblingsToDeactivate);
            }
        }

        // Activate all records
        for (Vendor_Customization__c record : records) {
            record.Status__c = 'Active';
            record.Active__c = true;
        }
        VendorCustomizationRepository.updateRecords(records);

        // Post-activation processing
        for (Vendor_Customization__c record : records) {
            postActivate(record);
        }
    }

    private static void deactivateSiblings(Vendor_Customization__c record) {
        if (record.Previous_Version__c == null) return;

        Set<Id> excludeIds = new Set<Id>{ record.Id };
        List<Vendor_Customization__c> siblings = 
            VendorCustomizationRepository.getActiveSiblingsByParentVersion(
                record.Previous_Version__c, 
                excludeIds
            );
        
        for (Vendor_Customization__c s : siblings) {
            s.Active__c = false;
        }
        if (!siblings.isEmpty()) {
            VendorCustomizationRepository.updateRecords(siblings);
        }
    }

    private static void postActivate(Vendor_Customization__c record) {
        // Vendor-specific business rules after activation.
        if (record == null) {
            return;
        }

        // Update activation metadata if fields exist.
        Map<String, Schema.SObjectField> fields = Vendor_Customization__c.SObjectType.getDescribe().fields.getMap();
        Boolean shouldUpdate = false;

        if (fields.containsKey('Activation_Date__c') && record.get('Activation_Date__c') == null) {
            record.put('Activation_Date__c', Date.today());
            shouldUpdate = true;
        }

        if (fields.containsKey('Activated_By__c') && record.get('Activated_By__c') == null) {
            record.put('Activated_By__c', UserInfo.getUserId());
            shouldUpdate = true;
        }

        if (fields.containsKey('Activation_Status__c')) {
            record.put('Activation_Status__c', 'Activated');
            shouldUpdate = true;
        }

        if (shouldUpdate) {
            VendorCustomizationRepository.updateRecord(record);
        }
    }
}