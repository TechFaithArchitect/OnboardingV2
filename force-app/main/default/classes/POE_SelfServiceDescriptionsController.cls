public with sharing class POE_SelfServiceDescriptionsController {
    @AuraEnabled
    public static List<Self_Service_Program_Description__mdt> getProgramDescriptionsMetadata() {
        return Self_Service_Program_Description__mdt.getAll().values();
    }
}