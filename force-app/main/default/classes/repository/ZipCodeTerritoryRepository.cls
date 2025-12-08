public with sharing class ZipCodeTerritoryRepository {

    /**
     * Returns the first Territory Assignment (owner + metadata) for each Zip Code Id.
     * Ordering uses CreatedDate/Id to make selection deterministic.
     * @param zipCodeIds set of Zip_Code__c Ids
     * @return Map of Zip_Code__c Id to ZipCodeTerritoryAssignment
     */
    public static Map<Id, ZipCodeTerritoryAssignment> getFirstAssignmentByZipIds(Set<Id> zipCodeIds) {
        Map<Id, ZipCodeTerritoryAssignment> zipToAssignment = new Map<Id, ZipCodeTerritoryAssignment>();
        if (zipCodeIds == null || zipCodeIds.isEmpty()) {
            return zipToAssignment;
        }

        for (Zip_Code_Territory__c junction : [
            SELECT Zip_Code__c,
                   Territory_Assignments__r.OwnerId,
                   Territory_Assignments__r.Division__c,
                   Territory_Assignments__r.Region__c,
                   Territory_Assignments__r.Territory__c
            FROM Zip_Code_Territory__c
            WHERE Zip_Code__c IN :zipCodeIds
              AND Territory_Assignments__r.OwnerId != null
            ORDER BY Zip_Code__c ASC, CreatedDate ASC, Id ASC
        ]) {
            if (!zipToAssignment.containsKey(junction.Zip_Code__c)) {
                zipToAssignment.put(
                    junction.Zip_Code__c,
                    new ZipCodeTerritoryAssignment(
                        junction.Territory_Assignments__r.OwnerId,
                        junction.Territory_Assignments__r.Division__c,
                        junction.Territory_Assignments__r.Region__c,
                        junction.Territory_Assignments__r.Territory__c
                    )
                );
            }
        }

        return zipToAssignment;
    }
}
