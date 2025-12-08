public class OnboardingAppTriggerHandler {
/*
    public static void run(
        List<Vendor_Customization__c> newList,
        Map<Id, Vendor_Customization__c> oldMap
    ) {
        autoCorrectInvalidActiveDrafts(newList);
        enforceOneActivePerParent(newList);
        enforceVersionLinkage(newList);
    }

    private static void autoCorrectInvalidActiveDrafts(List<Vendor_Customization__c> newList) {
        for (Vendor_Customization__c record : newList) {
            if (record.Status__c == 'Draft' && record.Is_Active__c) {
                record.Is_Active__c = false;
            }
        }
    }

    private static void enforceOneActivePerParent(List<Vendor_Customization__c> newList) {
        Set<Id> parentIds = new Set<Id>();
        for (Vendor_Customization__c record : newList) {
            if (record.Previous_Version__c != null) {
                parentIds.add(record.Previous_Version__c);
            }
        }

        if (parentIds.isEmpty()) return;

        Map<Id, Integer> activeCountByParent = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Previous_Version__c parentId, COUNT(Id) cnt
            FROM Vendor_Customization__c
            WHERE Is_Active__c = true
            AND Previous_Version__c IN :parentIds
            GROUP BY Previous_Version__c
        ]) {
            activeCountByParent.put((Id) ar.get('parentId'), (Integer) ar.get('cnt'));
        }

        // Add from current DML batch
        for (Vendor_Customization__c record : newList) {
            if (record.Is_Active__c && record.Previous_Version__c != null) {
                Id parentId = record.Previous_Version__c;
                Integer current = activeCountByParent.containsKey(parentId)
                    ? activeCountByParent.get(parentId)
                    : 0;
                activeCountByParent.put(parentId, current + 1);
            }
        }

        // Validate
        for (Vendor_Customization__c record : newList) {
            if (record.Is_Active__c && record.Previous_Version__c != null) {
                if (activeCountByParent.get(record.Previous_Version__c) > 1) {
                    record.addError('Only one active version is allowed per Vendor Program.');
                }
            }
        }
    }

    private static void enforceVersionLinkage(List<Vendor_Customization__c> newList) {
        for (Vendor_Customization__c record : newList) {
            Boolean isNonDraft = record.Status__c != 'Draft';
            Boolean isRootVersion = record.Previous_Version__c == null;

            if (isNonDraft && isRootVersion) {
                Integer childCount = [
                    SELECT COUNT()
                    FROM Vendor_Customization__c
                    WHERE Previous_Version__c = :record.Id
                ];

                if (childCount > 0) {
                    record.addError('Non-draft versions must reference a parent version.');
                }
            }
        }
    }
    */
}