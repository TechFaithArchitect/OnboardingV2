public class OnlyOneActiveRecGrpPerPrgrmRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newList = (List<Vendor_Program_Recipient_Group__c>) newRecords;

        Set<Id> parentIds = new Set<Id>();
        for (Vendor_Program_Recipient_Group__c rec : newList) {
            if (rec.Parent_Version__c != null) {
                parentIds.add(rec.Parent_Version__c);
            }
        }

        Map<Id, Integer> activeCountByParent = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Parent_Version__c parentId, COUNT(Id) cnt
            FROM Vendor_Program_Recipient_Group__c
            WHERE Is_Active__c = true
            AND Parent_Version__c IN :parentIds
            GROUP BY Parent_Version__c
        ]) {
            activeCountByParent.put((Id) ar.get('parentId'), (Integer) ar.get('cnt'));
        }

        for (Vendor_Program_Recipient_Group__c rec : newList) {
            if (rec.Is_Active__c && rec.Parent_Version__c != null) {
                Id parentId = rec.Parent_Version__c;
                Integer current = activeCountByParent.get(parentId) != null ? activeCountByParent.get(parentId) : 0;
                activeCountByParent.put(parentId, current + 1);
            }
        }

        for (Vendor_Program_Recipient_Group__c rec : newList) {
            if (rec.Is_Active__c && rec.Parent_Version__c != null) {
                if (activeCountByParent.get(rec.Parent_Version__c) > 1) {
                    rec.addError('Only one active version is allowed per Recipient Group.');
                }
            }
        }
    }
}