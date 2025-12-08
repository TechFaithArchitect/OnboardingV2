@isTest
private class RecipientGroupResolverTest {

    @isTest
    static void testResolveUsersFromRecipientGroupMemberships() {
        // Create two test users
        User user1 = TestDataFactory.createStandardUser(true);
        User user2 = TestDataFactory.createStandardUser(true);

        // Create an active Vendor and Vendor Program
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        // Create two recipient groups
        Recipient_Group__c recipientGroup1 = TestDataFactory.createRecipientGroup(true, true);
        Recipient_Group__c recipientGroup2 = TestDataFactory.createRecipientGroup(true, true);

        // Link both groups to the vendor program
        insert new List<Vendor_Program_Recipient_Group__c>{
            new Vendor_Program_Recipient_Group__c(
                Vendor_Program__c = vendorProgram.Id,
                Recipient_Group__c = recipientGroup1.Id,
                Is_Active__c = true
            ),
            new Vendor_Program_Recipient_Group__c(
                Vendor_Program__c = vendorProgram.Id,
                Recipient_Group__c = recipientGroup2.Id,
                Is_Active__c = true
            )
        };

        // Add both users as members (direct user membership only for now)
        insert new List<Recipient_Group_Member__c>{
            new Recipient_Group_Member__c(
                Recipient_Group__c = recipientGroup1.Id,
                Recipient_User__c = user1.Id,
                Member_Type__c = 'User'
            ),
            new Recipient_Group_Member__c(
                Recipient_Group__c = recipientGroup2.Id,
                Recipient_User__c = user2.Id,
                Member_Type__c = 'User'
            )
        };

        // Act
        Test.startTest();
        List<User> result = RecipientGroupResolver.resolveUsersForVendorProgram(vendorProgram.Id);
        Test.stopTest();

        // Assert
        Set<Id> resultUserIds = new Map<Id, User>(result).keySet();

        System.assertEquals(2, resultUserIds.size(), 'Should return two unique users');
        System.assert(resultUserIds.contains(user1.Id), 'Should include user1');
        System.assert(resultUserIds.contains(user2.Id), 'Should include user2');
    }

}
