public with sharing class VendorCustomizationRepository {
    
    /**
     * Fetches a Vendor_Customization__c record by ID with standard fields.
     * @param recordId The record ID
     * @return The Vendor_Customization__c record
     */
    public static Vendor_Customization__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }
        List<Vendor_Customization__c> records = [
            SELECT Id, Status__c, Active__c, Previous_Version__c
            FROM Vendor_Customization__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }
    
    /**
     * Fetches multiple Vendor_Customization__c records by IDs.
     * @param recordIds Set of record IDs
     * @return List of Vendor_Customization__c records
     */
    public static List<Vendor_Customization__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new List<Vendor_Customization__c>();
        }
        return [
            SELECT Id, Status__c, Active__c, Previous_Version__c
            FROM Vendor_Customization__c
            WHERE Id IN :recordIds
        ];
    }
    
    /**
     * Fetches active sibling records by parent version ID.
     * @param parentVersionId The Previous_Version__c ID
     * @param excludeIds Set of IDs to exclude from results
     * @return List of active sibling Vendor_Customization__c records
     */
    public static List<Vendor_Customization__c> getActiveSiblingsByParentVersion(
        Id parentVersionId, 
        Set<Id> excludeIds
    ) {
        if (parentVersionId == null) {
            return new List<Vendor_Customization__c>();
        }
        
        if (excludeIds != null && !excludeIds.isEmpty()) {
            return [
                SELECT Id, Active__c, Previous_Version__c
                FROM Vendor_Customization__c
                WHERE Previous_Version__c = :parentVersionId
                AND Active__c = true
                AND Id NOT IN :excludeIds
            ];
        } else {
            return [
                SELECT Id, Active__c, Previous_Version__c
                FROM Vendor_Customization__c
                WHERE Previous_Version__c = :parentVersionId
                AND Active__c = true
            ];
        }
    }
    
    /**
     * Updates Vendor_Customization__c records.
     * @param records List of records to update
     */
    public static void updateRecords(List<Vendor_Customization__c> records) {
        if (records != null && !records.isEmpty()) {
            update records;
        }
    }
    
    /**
     * Updates a single Vendor_Customization__c record.
     * @param record The record to update
     */
    public static void updateRecord(Vendor_Customization__c record) {
        if (record != null) {
            update record;
        }
    }
    
    /**
     * Fetches a Vendor_Customization__c record by ID with basic fields (Id, Vendor__c, Name).
     * @param recordId The record ID
     * @return The Vendor_Customization__c record or null if not found
     */
    public static Vendor_Customization__c getBasicById(Id recordId) {
        if (recordId == null) {
            return null;
        }
        List<Vendor_Customization__c> records = [
            SELECT Id, Vendor__c, Name
            FROM Vendor_Customization__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }
    
    /**
     * Fetches a Vendor_Customization__c record by ID with metadata fields (ownership and timestamps).
     * @param recordId The record ID
     * @return The Vendor_Customization__c record or null if not found
     */
    public static Vendor_Customization__c getMetadataById(Id recordId) {
        if (recordId == null) {
            return null;
        }
        List<Vendor_Customization__c> records = [
            SELECT Id, Name, CreatedById, CreatedBy.Name, CreatedDate,
                   LastModifiedById, LastModifiedBy.Name, LastModifiedDate
            FROM Vendor_Customization__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }
}

