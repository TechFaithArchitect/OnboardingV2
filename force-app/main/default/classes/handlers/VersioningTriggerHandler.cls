public with sharing class VersioningTriggerHandler {
    public static void run(
        List<SObject> newList,
        Map<Id, SObject> oldMap,
        String objectApiName
    ) {
        if (!supportsVersioning(objectApiName)) {
            return;
        }
        autoCorrectInvalidActiveDrafts(newList);
        enforceOneActivePerParent(newList, objectApiName);
    }

    public static void afterInsert(List<SObject> newList, String objectApiName) {
        // No post-insert logic currently required — left here for potential future use
    }

    private static void autoCorrectInvalidActiveDrafts(List<SObject> newList) {
        for (SObject record : newList) {
            String status = (String) record.get('Status__c');
            Boolean isActive = (Boolean) record.get('Active__c');
            
            // DRY Pattern: Sync Status__c with Active__c
            // When Status = 'Active', set Active__c = true
            if (status == 'Active' && (isActive == null || isActive == false)) {
                record.put('Active__c', true);
            }
            // When Status = 'Draft', set Active__c = false
            if (status == 'Draft' && isActive == true) {
                record.put('Active__c', false);
            }
        }
    }

    private static void enforceOneActivePerParent(List<SObject> newList, String objectApiName) {
        Set<Id> parentIds = new Set<Id>();
        for (SObject rec : newList) {
            Id p = (Id) rec.get('Previous_Version__c');
            if (p != null) parentIds.add(p);
        }
        if (parentIds.isEmpty()) return;

        Map<Id, Integer> activeCountByParent = new Map<Id, Integer>();
        String q = 'SELECT Previous_Version__c parentId, COUNT(Id) cnt ' +
                   'FROM ' + objectApiName +
                   ' WHERE Active__c = true AND Previous_Version__c IN :parentIds ' +
                   'GROUP BY Previous_Version__c';
        for (AggregateResult ar : Database.query(q)) {
            activeCountByParent.put((Id) ar.get('parentId'), (Integer) ar.get('cnt'));
        }

        for (SObject rec : newList) {
            if ((Boolean) rec.get('Active__c') == true && rec.get('Previous_Version__c') != null) {
                Id p = (Id) rec.get('Previous_Version__c');
                Integer currentCount = activeCountByParent.containsKey(p) ? activeCountByParent.get(p) : 0;
                activeCountByParent.put(p, currentCount + 1);
            }
        }

        for (SObject rec : newList) {
            Id p = (Id) rec.get('Previous_Version__c');
            Boolean willBeActive = (Boolean) rec.get('Active__c') == true;
            if (willBeActive && p != null) {
                Integer count = activeCountByParent.containsKey(p) ? activeCountByParent.get(p) : 0;
                if (count > 1) {
                    rec.addError('Only one active version is allowed per record lineage.');
                }
            }
        }
    }

    private static Boolean supportsVersioning(String objectApiName) {
        Schema.SObjectType typeInfo = Schema.getGlobalDescribe().get(objectApiName);
        if (typeInfo == null) {
            return false;
        }
        Map<String, Schema.SObjectField> fields = typeInfo.getDescribe().fields.getMap();

        return fields.containsKey('Status__c') &&
            fields.containsKey('Previous_Version__c') &&
            fields.containsKey('Active__c');
    }
}
