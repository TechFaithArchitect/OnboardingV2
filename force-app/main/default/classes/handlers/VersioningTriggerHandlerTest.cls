@isTest
private class VersioningTriggerHandlerTest {

    @isTest
    static void testSkipsVersioningWhenObjectIsNotVersioned() {
        // Arrange
        Vendor__c vendor = TestVendorProgramFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Vendor_Program_Group__c vendorProgramGroup = new Vendor_Program_Group__c(Name = 'Skip Test Group', Label__c = 'Skip Test Group Label');
        insert vendorProgramGroup;

        Vendor_Program_Group_Member__c vendorProgramGroupMember = new Vendor_Program_Group_Member__c(
            Required_Program__c = vendorProgram.Id,
            Vendor_Program_Group__c = vendorProgramGroup.Id
        );

        // Act
        Test.startTest();
        insert vendorProgramGroupMember;
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, vendorProgramGroupMember.Id, 'Insert should succeed with non-versioned object');
    }

    @isTest
    static void testSkipsUnknownObjectApiName() {
        Vendor_Customization__c draft = new Vendor_Customization__c(
            Status__c = 'Draft',
            Active__c = true
        );

        // Should return immediately because the object API name is not describable
        VersioningTriggerHandler.run(
            new List<SObject>{ draft },
            null,
            'Nonexistent__c'
        );

        System.assertEquals(true, draft.Active__c, 'Handler should not mutate records for unknown objects');
    }

    @isTest
    static void testSingleActivePerParentEnforced() {
        // Arrange
        Vendor__c vendor = TestVendorProgramFactory.createVendor(true);
        Vendor_Customization__c parentVendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        Vendor_Customization__c v1 = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = 'Active',
            Active__c = true,
            Previous_Version__c = parentVendorProgram.Id
        );
        Vendor_Customization__c v2 = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = 'Active',
            Active__c = true,
            Previous_Version__c = parentVendorProgram.Id
        );

        // Act & Assert
        Test.startTest();
        try {
            insert new List<Vendor_Customization__c>{ v1, v2 };
            System.assert(false, 'Expected error due to multiple active versions');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Only one active version is allowed'), 'Expected validation error');
        }
        Test.stopTest();
    }

    @isTest
    static void testExistingActiveCountsInAggregate() {
        Vendor__c vendor = TestVendorProgramFactory.createVendor(true);
        Vendor_Customization__c parentVendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Existing active child
        Vendor_Customization__c existingActive = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = 'Active',
            Active__c = true,
            Previous_Version__c = parentVendorProgram.Id
        );
        insert existingActive;

        // New active child referencing same parent should fail; aggregate should pick up existingActive
        Vendor_Customization__c secondActive = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = 'Active',
            Active__c = true,
            Previous_Version__c = parentVendorProgram.Id
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(secondActive, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Second active version should be rejected when one already exists');
        System.assert(
            result.getErrors()[0].getMessage().contains('Only one active version'),
            'Expected only one active version validation error'
        );
    }

    @isTest
    static void testRootActiveVersionWithoutParent_isAllowed() {
        // Arrange
        Vendor__c vendor = TestVendorProgramFactory.createVendor(true);

        Vendor_Customization__c orphanVendorProgram = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Active__c = true,
            Status__c = 'Active'
            
        );

        // Act
        Test.startTest();
        insert orphanVendorProgram;
        Test.stopTest();

        // Assert
        Vendor_Customization__c result = [
            SELECT Id, Status__c, Active__c, Previous_Version__c
            FROM Vendor_Customization__c
            WHERE Id = :orphanVendorProgram.Id
        ];

        System.assertEquals(true, result.Active__c, 'Should allow root active version without parent');
        System.assertEquals(null, result.Previous_Version__c, 'Should not be auto-linked');
    }

    @isTest
    static void testAutoCorrectsActiveDrafts() {
        // Arrange
        Vendor__c vendor = TestVendorProgramFactory.createVendor(true);

        Vendor_Customization__c draftVendorProgram = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Active__c = true,
            Status__c = 'Draft'
        );

        // Act
        Test.startTest();
        insert draftVendorProgram;
        Test.stopTest();

        // Assert
        draftVendorProgram = [SELECT Status__c, Active__c FROM Vendor_Customization__c WHERE Id = :draftVendorProgram.Id];
        System.assertEquals(false, draftVendorProgram.Active__c, 'Draft record should not be active');
    }
}
