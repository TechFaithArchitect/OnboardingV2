/**
 * Assigns owners for Lead, Contact, and Account based on Zip → Territory Assignment mapping.
 * Falls back to the creating user when no mapping is found.
 */
public with sharing class LeadAssignmentService {

    /**
     * Bulk-safe assignment for Leads.
     */
    public static void assignOwners(List<Lead> leads) {
        assignOwnersInternal((List<SObject>) leads, 'PostalCode');
    }

    /**
     * Bulk-safe assignment for Contacts.
     */
    public static void assignOwnersForContacts(List<Contact> contacts) {
        assignOwnersInternal((List<SObject>) contacts, 'MailingPostalCode');
    }

    /**
     * Bulk-safe assignment for Accounts.
     */
    public static void assignOwnersForAccounts(List<Account> accounts) {
        assignOwnersInternal((List<SObject>) accounts, 'BillingPostalCode');
    }

    /**
     * Core assignment logic shared across Lead/Contact/Account.
     * @param records SObjects to assign
     * @param postalField API name of the postal code field to read
     */
    private static void assignOwnersInternal(List<SObject> records, String postalField) {
        if (records == null || records.isEmpty()) {
            return;
        }

        Map<String, List<SObject>> recordsByZip = new Map<String, List<SObject>>();

        for (SObject record : records) {
            String normalized = normalizePostalCode((String) record.get(postalField));
            if (String.isNotBlank(normalized)) {
                if (!recordsByZip.containsKey(normalized)) {
                    recordsByZip.put(normalized, new List<SObject>());
                }
                recordsByZip.get(normalized).add(record);
            } else if ((Id) record.get('OwnerId') == null) {
                // Default assignment: Created By user (same as current user in before insert)
                record.put('OwnerId', UserInfo.getUserId());
            }
        }

        if (recordsByZip.isEmpty()) {
            return;
        }

        Map<String, ZipCodeTerritoryAssignment> zipToAssignment = resolveAssignments(recordsByZip.keySet());

        for (String zip : recordsByZip.keySet()) {
            ZipCodeTerritoryAssignment assignment = zipToAssignment.get(zip);
            Id ownerId = assignment != null ? assignment.ownerId : null;
            for (SObject record : recordsByZip.get(zip)) {
                if (ownerId != null) {
                    record.put('OwnerId', ownerId);
                } else if ((Id) record.get('OwnerId') == null) {
                    record.put('OwnerId', UserInfo.getUserId());
                }
                applyTerritoryFields(record, assignment);
            }
        }
    }

    /**
     * Looks up the first Territory Assignment owner for each ZIP.
     * @param normalizedZips 5-digit ZIP codes
     * @return Map of ZIP text to Owner Id
     */
    @TestVisible
    private static Map<String, ZipCodeTerritoryAssignment> resolveAssignments(Set<String> normalizedZips) {
        Map<Id, List<String>> zipIdToKeys = new Map<Id, List<String>>();
        for (Zip_Code__c zip : ZipCodeRepository.getByPostalCodes(normalizedZips)) {
            List<String> keys = new List<String>();
            String postalFieldVal = (String) zip.get('Postal_Code__c');
            String delFieldVal = (String) zip.get('Zip_Code_del__c');
            if (String.isNotBlank(delFieldVal)) {
                keys.add(delFieldVal);
            }
            if (String.isNotBlank(postalFieldVal)) {
                keys.add(postalFieldVal);
            }
            if (String.isNotBlank(zip.Name)) {
                keys.add(zip.Name);
            }
            if (!keys.isEmpty()) {
                zipIdToKeys.put(zip.Id, keys);
            }
        }

        if (zipIdToKeys.isEmpty()) {
            return new Map<String, ZipCodeTerritoryAssignment>();
        }

        Map<String, ZipCodeTerritoryAssignment> zipToAssignment = new Map<String, ZipCodeTerritoryAssignment>();

        Map<Id, ZipCodeTerritoryAssignment> zipIdToAssignment =
            ZipCodeTerritoryRepository.getFirstAssignmentByZipIds(zipIdToKeys.keySet());

        for (Id zipId : zipIdToAssignment.keySet()) {
            List<String> keys = zipIdToKeys.get(zipId);
            if (keys == null) continue;
            for (String key : keys) {
                if (!zipToAssignment.containsKey(key)) {
                    zipToAssignment.put(key, zipIdToAssignment.get(zipId));
                }
            }
        }

        return zipToAssignment;
    }

    /**
     * Normalizes postal codes to 5-digit ZIP values.
     * @param postalCode Raw Lead.PostalCode
     * @return 5-digit ZIP or null if not derivable
     */
    @TestVisible
    private static String normalizePostalCode(String postalCode) {
        if (String.isBlank(postalCode)) {
            return null;
        }
        String digitsOnly = postalCode.replaceAll('[^0-9]', '');
        if (String.isBlank(digitsOnly) || digitsOnly.length() < 5) {
            return null;
        }
        return digitsOnly.substring(0, 5);
    }

    @TestVisible
    private static void applyTerritoryFields(SObject record, ZipCodeTerritoryAssignment assignment) {
        if (assignment == null || record == null || record.getSObjectType() != Lead.SObjectType) {
            return;
        }

        Map<String, Set<String>> allowedValues = getPicklistValues(Lead.SObjectType,
            new Set<String>{ 'Division__c', 'Region__c', 'Territory__c' });

        setPicklistIfAllowed(record, 'Division__c', assignment.division, allowedValues);
        setPicklistIfAllowed(record, 'Region__c', assignment.region, allowedValues);
        setPicklistIfAllowed(record, 'Territory__c', assignment.territory, allowedValues);
    }

    private static void setPicklistIfAllowed(SObject record, String fieldName, String value, Map<String, Set<String>> allowedValues) {
        if (String.isBlank(value)) {
            return;
        }
        Set<String> allowed = allowedValues.get(fieldName);
        if (allowed != null && allowed.contains(value)) {
            record.put(fieldName, value);
        }
    }

    @TestVisible
    private static Map<String, Set<String>> getPicklistValues(Schema.SObjectType sobjectType, Set<String> fieldNames) {
        Map<String, Set<String>> results = new Map<String, Set<String>>();
        if (sobjectType == null || fieldNames == null || fieldNames.isEmpty()) {
            return results;
        }
        Map<String, Schema.SObjectField> fields = sobjectType.getDescribe().fields.getMap();
        for (String fieldName : fieldNames) {
            if (!fields.containsKey(fieldName)) {
                continue;
            }
            Schema.DescribeFieldResult dfr = fields.get(fieldName).getDescribe();
            if (dfr.getType() != Schema.DisplayType.Picklist) {
                continue;
            }
            Set<String> values = new Set<String>();
            for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                values.add(entry.getValue());
            }
            results.put(fieldName, values);
        }
        return results;
    }
}