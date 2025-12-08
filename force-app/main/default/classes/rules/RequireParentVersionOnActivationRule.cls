public class RequireParentVersionOnActivationRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newList = (List<Vendor_Program_Recipient_Group__c>) newRecords;

        Set<Id> programIds = new Set<Id>();
        for (Vendor_Program_Recipient_Group__c rec : newList) {
            if (rec.Vendor_Program__c != null) {
                programIds.add(rec.Vendor_Program__c);
            }
        }

        Map<Id, Integer> existingCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Vendor_Program__c programId, COUNT(Id) cnt
            FROM Vendor_Program_Recipient_Group__c
            WHERE Vendor_Program__c IN :programIds
            GROUP BY Vendor_Program__c
        ]) {
            existingCounts.put((Id) ar.get('programId'), (Integer) ar.get('cnt'));
        }

        for (Vendor_Program_Recipient_Group__c rec : newList) {
            Boolean needsLink = rec.Status__c != 'Draft' && rec.Parent_Version__c == null;
            Integer existing = existingCounts.get(rec.Vendor_Program__c);

            if (needsLink && existing != null && existing > 0) {
                rec.addError('Non-draft versions must reference a parent version.');
            }
        }
    }
}

