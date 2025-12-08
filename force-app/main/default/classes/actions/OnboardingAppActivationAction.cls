public with sharing class OnboardingAppActivationAction {

    public class Request {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String objectApiName;
    }

    @AuraEnabled
    public static void activate(List<Request> requestList) {
        if (requestList == null || requestList.isEmpty()) {
            return;
        }

        // Validate all requests first
        for (Request req : requestList) {
            if (req.recordId == null || String.isBlank(req.objectApiName)) {
                throw new AuraHandledException('Object API Name and Record Id are required.');
            }
        }

        // Group requests by object type for bulk processing
        Map<String, Set<Id>> bulkRecords = new Map<String, Set<Id>>();
        Set<Id> vendorProgramIds = new Set<Id>();

        for (Request req : requestList) {
            // Vendor_Customization__c uses specialized service with bulk support
            if (req.objectApiName == 'Vendor_Customization__c') {
                vendorProgramIds.add(req.recordId);
            } else {
                // Group by object type for bulk processing
                if (!bulkRecords.containsKey(req.objectApiName)) {
                    bulkRecords.put(req.objectApiName, new Set<Id>());
                }
                bulkRecords.get(req.objectApiName).add(req.recordId);
            }
        }

        // Process vendor programs in bulk
        if (!vendorProgramIds.isEmpty()) {
            VendorProgramActivationService.activateBulk(vendorProgramIds);
        }

        // Process other object types in bulk
        if (!bulkRecords.isEmpty()) {
            OnboardingAppActivationService.activateRecordsBulk(bulkRecords);
        }
    }
}
