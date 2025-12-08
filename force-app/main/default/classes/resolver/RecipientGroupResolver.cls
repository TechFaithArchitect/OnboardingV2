public with sharing class RecipientGroupResolver {
    public static List<User> resolveUsersForVendorProgram(Id vendorProgramId) {
        if (vendorProgramId == null) {
            return new List<User>();
        }

        Set<Id> userIds = new Set<Id>();

        // Step 1: Get all active group IDs linked to this Vendor Program
        Set<Id> groupIds = new Set<Id>();
        for (Vendor_Program_Recipient_Group__c link : [
            SELECT Recipient_Group__c
            FROM Vendor_Program_Recipient_Group__c
            WHERE Vendor_Program__c = :vendorProgramId
            AND Is_Active__c = true
        ]) {
            groupIds.add(link.Recipient_Group__c);
        }

        if (groupIds.isEmpty()) {
            return new List<User>();
        }

        // Step 2: Get users from the linked recipient groups
        for (Recipient_Group_Member__c member : [
            SELECT Recipient_User__c
            FROM Recipient_Group_Member__c
            WHERE Recipient_Group__c IN :groupIds
            AND Recipient_User__c != null
        ]) {
            userIds.add(member.Recipient_User__c);
        }

        if (userIds.isEmpty()) {
            return new List<User>();
        }

        // Step 3: Return fully hydrated User records with LIMIT for safety
        return [
            SELECT Id, Email
            FROM User
            WHERE Id IN :userIds
            AND Email != null
            LIMIT 1000
        ];

        // In RecipientGroupResolver
        // Optionally resolve additional user sources like:

        // TODO: Add logic to resolve Group__c → Users
        // TODO: Add logic to resolve Territory_Role_Assignment__c → Users
        // TODO: Add logic to resolve Public Group or Queue members
    }
}
