public with sharing class OnboardingAppVendorProgramReqRepo {

    public static List<Required_Credential__c> fetchRequiredCredentials(Id vendorProgramId) {
        return [
            SELECT Id, Name, Notes__c, Vendor_Customization__c, Is_Required__c, Sequence__c,
                   External_Contact_Credential_Type__c, External_Contact_Credential_Type__r.Name
            FROM Required_Credential__c
            WHERE Vendor_Customization__c = :vendorProgramId
        ];
    }

    public static List<Training_Requirement__c> fetchTrainingRequirements(Id vendorProgramId) {
        return [
            SELECT Id, Name, Training_System__c, Training_System__r.Name, Sequence__c, Vendor_Customization__c, Is_Required__c, Training_Code__c, External_Course_Code__c, External_Course_Name__c
            FROM Training_Requirement__c
            WHERE Vendor_Customization__c = :vendorProgramId
            ORDER BY Sequence__c NULLS LAST, Name
        ];
    }

    /**
     * Inserts a new Required Credential record.
     * @param record The Required_Credential__c record to insert
     * @return The Id of the inserted record
     */
    public static Id insertRequiredCredential(Required_Credential__c record) {
        insert record;
        return record.Id;
    }

    public static void updateRequiredCredentials(List<Required_Credential__c> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        update records;
    }

    /**
     * Inserts a new Training Requirement record.
     * @param record The Training_Requirement__c record to insert
     * @return The Id of the inserted record
     */
    public static Id insertTrainingRequirement(Training_Requirement__c record) {
        insert record;
        return record.Id;
    }
    
    /**
     * Fetches all active Training Systems for use in picklists.
     * @return List of active Training_System__c records
     */
    public static List<Training_System__c> fetchActiveTrainingSystems() {
        return [
            SELECT Id, Name, System_Type__c
            FROM Training_System__c
            WHERE Active__c = true
            ORDER BY Name
        ];
    }
    
    /**
     * Inserts a new Training System record.
     * @param record The Training_System__c record to insert
     * @return The Id of the inserted record
     */
    public static Id insertTrainingSystem(Training_System__c record) {
        insert record;
        return record.Id;
    }
    
    /**
     * Updates Training Requirements to mark them as required or not required.
     * @param trainingRequirementIds List of Training Requirement IDs to update
     * @param isRequired Whether the training requirements should be marked as required
     */
    public static void updateTrainingRequirementRequiredStatus(List<Id> trainingRequirementIds, Boolean isRequired) {
        List<Training_Requirement__c> requirements = new List<Training_Requirement__c>();
        for (Id reqId : trainingRequirementIds) {
            requirements.add(new Training_Requirement__c(
                Id = reqId,
                Is_Required__c = isRequired
            ));
        }
        if (!requirements.isEmpty()) {
            update requirements;
        }
    }
}