@isTest
public class TestTrainingRequirementFactory {
    public static Training_Requirement__c create(Boolean doInsert, Vendor_Customization__c vendorProgram, Training_System__c trainingSystem) {
        Training_Requirement__c trainingRequirement = new Training_Requirement__c(
            External_Course_Code__c = 'TR-001',
            External_Course_Name__c = 'Test Course',
            Training_Code__c = 'INT-001',
            Is_Required__c = true,
            Sequence__c = 1,
            Training_System__c = trainingSystem.Id,
            Vendor_Customization__c = vendorProgram.Id
        );
        if (doInsert) insert trainingRequirement;
        return trainingRequirement;
    }
}
