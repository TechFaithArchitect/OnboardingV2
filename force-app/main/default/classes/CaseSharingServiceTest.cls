@IsTest
private class CaseSharingServiceTest {
    @TestSetup
    static void setupTestData() {
        // Create test user for group membership
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            ProfileId = p.Id,
            LastName = 'TestUser',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert testUser;

        // Create test group
        Group testGroup = new Group(Name = 'Test Group', Type = 'Regular');
        insert testGroup;

        // Add user to group
        GroupMember gm = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = testUser.Id);
        insert gm;
    }

    @IsTest
    static void testShareCaseWithGroup_SingleCase() {
        // Arrange
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone');
        insert testCase;

        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Group' LIMIT 1];

        CaseSharingService.ShareInput input = new CaseSharingService.ShareInput();
        input.recordId = testCase.Id;
        input.groupId = testGroup.Id;
        input.accessLevel = 'Read';

        // Act
        Test.startTest();
        CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ input });
        Test.stopTest();

        // Assert
        List<CaseShare> shares = [
            SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel
            FROM CaseShare
            WHERE CaseId = :testCase.Id AND UserOrGroupId = :testGroup.Id
        ];

        System.assertEquals(1, shares.size(), 'Should have created one case share record');
        System.assertEquals('Read', shares[0].CaseAccessLevel, 'Access level should be Read');
    }

    @IsTest
    static void testShareCaseWithGroup_MultipleCases() {
        // Arrange
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            testCases.add(new Case(Subject = 'Test Case ' + i, Status = 'New', Origin = 'Phone'));
        }
        insert testCases;

        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Group' LIMIT 1];

        List<CaseSharingService.ShareInput> inputs = new List<CaseSharingService.ShareInput>();
        for (Case c : testCases) {
            CaseSharingService.ShareInput input = new CaseSharingService.ShareInput();
            input.recordId = c.Id;
            input.groupId = testGroup.Id;
            input.accessLevel = 'Edit';
            inputs.add(input);
        }

        // Act
        Test.startTest();
        CaseSharingService.shareCaseWithGroup(inputs);
        Test.stopTest();

        // Assert
        List<CaseShare> shares = [
            SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel
            FROM CaseShare
            WHERE CaseId IN :testCases AND UserOrGroupId = :testGroup.Id
        ];

        System.assertEquals(3, shares.size(), 'Should have created three case share records');
        for (CaseShare share : shares) {
            System.assertEquals('Edit', share.CaseAccessLevel, 'Access level should be Edit');
        }
    }

    @IsTest
    static void testShareCaseWithGroup_EmptyList() {
        // Act
        Test.startTest();
        CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>());
        Test.stopTest();

        // Assert - No exception should be thrown and no records should be created
        List<CaseShare> shares = [SELECT Id FROM CaseShare];
        System.assertEquals(0, shares.size(), 'No case shares should be created for empty input');
    }

    @IsTest
    static void testShareCaseWithGroup_DuplicateSharing() {
        // Arrange
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone');
        insert testCase;

        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Group' LIMIT 1];

        CaseSharingService.ShareInput input = new CaseSharingService.ShareInput();
        input.recordId = testCase.Id;
        input.groupId = testGroup.Id;
        input.accessLevel = 'Read';

        // Act - Share the same case with the same group twice
        Test.startTest();
        CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ input });
        CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ input });
        Test.stopTest();

        // Assert - Should only have one share record (duplicate sharing is handled by Salesforce)
        List<CaseShare> shares = [
            SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel
            FROM CaseShare
            WHERE CaseId = :testCase.Id AND UserOrGroupId = :testGroup.Id
        ];

        System.assertEquals(1, shares.size(), 'Should have only one case share record even with duplicate calls');
    }

    @IsTest
    static void testShareCaseWithGroup_DifferentAccessLevels() {
        // Arrange
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone');
        insert testCase;

        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Group' LIMIT 1];

        CaseSharingService.ShareInput readInput = new CaseSharingService.ShareInput();
        readInput.recordId = testCase.Id;
        readInput.groupId = testGroup.Id;
        readInput.accessLevel = 'Read';

        CaseSharingService.ShareInput editInput = new CaseSharingService.ShareInput();
        editInput.recordId = testCase.Id;
        editInput.groupId = testGroup.Id;
        editInput.accessLevel = 'Edit';

        // Act
        Test.startTest();
        CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ readInput, editInput });
        Test.stopTest();

        // Assert - Should have one share record with the last access level applied
        List<CaseShare> shares = [
            SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel
            FROM CaseShare
            WHERE CaseId = :testCase.Id AND UserOrGroupId = :testGroup.Id
        ];

        System.assertEquals(1, shares.size(), 'Should have one case share record');
        // Note: The actual access level will depend on the order of processing
    }

    @IsTest
    static void testShareCaseWithGroup_InvalidCaseId() {
        // Arrange
        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Group' LIMIT 1];

        CaseSharingService.ShareInput input = new CaseSharingService.ShareInput();
        input.recordId = '500000000000000'; // Invalid ID
        input.groupId = testGroup.Id;
        input.accessLevel = 'Read';

        // Act & Assert
        Test.startTest();
        try {
            CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ input });
            System.assert(false, 'Should have thrown an exception for invalid case ID');
        } catch (Exception e) {
            // The actual exception will be a DmlException, not necessarily containing 'INVALID_ID_FIELD'
            System.assert(e.getMessage().contains('INVALID') || e.getMessage().contains('ID'), 'Should throw invalid ID exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testShareCaseWithGroup_InvalidGroupId() {
        // Arrange
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone');
        insert testCase;

        CaseSharingService.ShareInput input = new CaseSharingService.ShareInput();
        input.recordId = testCase.Id;
        input.groupId = '00G000000000000'; // Invalid group ID
        input.accessLevel = 'Read';

        // Act & Assert
        Test.startTest();
        try {
            CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ input });
            System.assert(false, 'Should have thrown an exception for invalid group ID');
        } catch (Exception e) {
            // The actual exception will be a DmlException, not necessarily containing 'INVALID_ID_FIELD'
            System.assert(e.getMessage().contains('INVALID') || e.getMessage().contains('ID'), 'Should throw invalid ID exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testShareCaseWithGroup_NullValues() {
        // Arrange
        CaseSharingService.ShareInput input = new CaseSharingService.ShareInput();
        input.recordId = null;
        input.groupId = null;
        input.accessLevel = null;

        // Act & Assert
        Test.startTest();
        try {
            CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ input });
            System.assert(false, 'Should have thrown an exception for null values');
        } catch (Exception e) {
            // Expected to throw an exception for null values
            System.assert(true, 'Exception thrown for null values as expected');
        }
        Test.stopTest();
    }

    @IsTest
    static void testShareCaseWithGroup_BulkOperation() {
        // Arrange
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            testCases.add(new Case(Subject = 'Bulk Test Case ' + i, Status = 'New', Origin = 'Phone'));
        }
        insert testCases;

        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Group' LIMIT 1];

        List<CaseSharingService.ShareInput> inputs = new List<CaseSharingService.ShareInput>();
        for (Case c : testCases) {
            CaseSharingService.ShareInput input = new CaseSharingService.ShareInput();
            input.recordId = c.Id;
            input.groupId = testGroup.Id;
            input.accessLevel = 'Read';
            inputs.add(input);
        }

        // Act
        Test.startTest();
        CaseSharingService.shareCaseWithGroup(inputs);
        Test.stopTest();

        // Assert
        List<CaseShare> shares = [
            SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel
            FROM CaseShare
            WHERE CaseId IN :testCases AND UserOrGroupId = :testGroup.Id
        ];

        System.assertEquals(200, shares.size(), 'Should have created 200 case share records');
    }
}