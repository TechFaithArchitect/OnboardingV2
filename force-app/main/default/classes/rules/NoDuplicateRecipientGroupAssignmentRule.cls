public class NoDuplicateRecipientGroupAssignmentRule implements OnboardingAppValidationRule {

    public void validate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> records = (List<Vendor_Program_Recipient_Group__c>) newList;
        Map<Id, Vendor_Program_Recipient_Group__c> oldRecs = (Map<Id, Vendor_Program_Recipient_Group__c>) oldMap;

        Set<Id> programIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        Map<String, Id> keyToExisting = new Map<String, Id>();
        Set<String> seenKeys = new Set<String>();

        for (Vendor_Program_Recipient_Group__c rec : records) {
            if (rec.Vendor_Program__c != null && rec.Recipient_Group__c != null) {
                programIds.add(rec.Vendor_Program__c);
                groupIds.add(rec.Recipient_Group__c);
            }
        }

        if (!programIds.isEmpty() && !groupIds.isEmpty()) {
            for (Vendor_Program_Recipient_Group__c rec : [
                SELECT Id, Vendor_Program__c, Recipient_Group__c
                FROM Vendor_Program_Recipient_Group__c
                WHERE Vendor_Program__c IN :programIds
                AND Recipient_Group__c IN :groupIds
                AND (Is_Active__c = true OR Status__c = 'Active')
            ]) {
                String key = rec.Vendor_Program__c + ':' + rec.Recipient_Group__c;
                keyToExisting.put(key, rec.Id);
            }
        }

        for (Vendor_Program_Recipient_Group__c rec : records) {
            if (rec.Vendor_Program__c == null || rec.Recipient_Group__c == null) continue;

            String key = rec.Vendor_Program__c + ':' + rec.Recipient_Group__c;
            Id existingId = keyToExisting.get(key);

            Boolean isChanged = oldRecs == null || 
                oldRecs.get(rec.Id) == null || 
                oldRecs.get(rec.Id).Vendor_Program__c != rec.Vendor_Program__c || 
                oldRecs.get(rec.Id).Recipient_Group__c != rec.Recipient_Group__c;

            if (seenKeys.contains(key)) {
                rec.addError('This Vendor Program already has this Recipient Group assigned (same transaction).');
            } else if (existingId != null && (rec.Id == null || rec.Id != existingId) && isChanged) {
                rec.addError('This Vendor Program already has this Recipient Group assigned.');
            }

            seenKeys.add(key);
        }
    }
}

