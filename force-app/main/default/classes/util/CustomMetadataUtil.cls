/**
 * Utility for simple custom metadata retrieval with in-memory caching.
 */
public with sharing class CustomMetadataUtil {
    private static Map<String, SObject> cache = new Map<String, SObject>();

    public static SObject getByDeveloperName(Schema.SObjectType mdtType, String developerName) {
        if (mdtType == null || String.isBlank(developerName)) {
            return null;
        }
        String cacheKey = mdtType.getDescribe().getName() + ':' + developerName;
        if (cache.containsKey(cacheKey)) {
            return cache.get(cacheKey);
        }
        String soql = 'SELECT Id, DeveloperName, MasterLabel FROM ' +
                      mdtType.getDescribe().getName() +
                      ' WHERE DeveloperName = :developerName LIMIT 1';
        SObject record = null;
        try {
            List<SObject> results = Database.query(soql);
            record = results.isEmpty() ? null : results[0];
        } catch (Exception e) {
            System.debug('CustomMetadataUtil query failed: ' + e.getMessage());
        }
        cache.put(cacheKey, record);
        return record;
    }

    public static void clearCache() {
        cache.clear();
    }
}