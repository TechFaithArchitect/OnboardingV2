public class PreventDupRecGrpAssignmentRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newRecords = 
            (List<Vendor_Program_Recipient_Group__c>) newList;

        Set<Id> programIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        Map<String, Id> keyToExisting = new Map<String, Id>();
        Set<String> keysSeenThisBatch = new Set<String>();

        // Extract keys
        for (Vendor_Program_Recipient_Group__c rec : newRecords) {
            if (rec.Vendor_Program__c != null && rec.Recipient_Group__c != null) {
                programIds.add(rec.Vendor_Program__c);
                groupIds.add(rec.Recipient_Group__c);
            }
        }

        // Fetch existing assignments
        List<Vendor_Program_Recipient_Group__c> existing = [
            SELECT Id, Vendor_Program__c, Recipient_Group__c
            FROM Vendor_Program_Recipient_Group__c
            WHERE Vendor_Program__c IN :programIds
            AND Recipient_Group__c IN :groupIds
            AND (Is_Active__c = true OR Status__c = 'Active')
        ];

        for (Vendor_Program_Recipient_Group__c rec : existing) {
            String key = rec.Vendor_Program__c + ':' + rec.Recipient_Group__c;
            keyToExisting.put(key, rec.Id);
        }

        for (Vendor_Program_Recipient_Group__c rec : newRecords) {
            if (rec.Vendor_Program__c != null && rec.Recipient_Group__c != null) {
                String key = rec.Vendor_Program__c + ':' + rec.Recipient_Group__c;
                Id existingId = keyToExisting.get(key);

                Boolean isChanged = oldMap == null || 
                    oldMap.get(rec.Id) == null || 
                    oldMap.get(rec.Id).get('Vendor_Program__c') != rec.Vendor_Program__c ||
                    oldMap.get(rec.Id).get('Recipient_Group__c') != rec.Recipient_Group__c;

                if (keysSeenThisBatch.contains(key)) {
                    rec.addError('This Vendor Program already has this Recipient Group assigned in this transaction.');
                } else if (existingId != null && (rec.Id == null || rec.Id != existingId) && isChanged) {
                    rec.addError('This Vendor Program already has this Recipient Group assigned.');
                }

                keysSeenThisBatch.add(key);
            }
        }
    }
}

