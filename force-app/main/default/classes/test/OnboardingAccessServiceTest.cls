@IsTest
private class OnboardingAccessServiceTest {

    // ============================================================================
    // VIEW FILTER TESTS
    // ============================================================================

    @IsTest
    static void testGetUserIdsForViewFilter_myView() {
        Test.startTest();
        Set<Id> ids = OnboardingAccessService.getUserIdsForViewFilter('MY_VIEW');
        Test.stopTest();

        System.assertEquals(1, ids.size(), 'MY_VIEW should only return the current user');
        System.assert(ids.contains(UserInfo.getUserId()), 'Current user should be included');
    }

    @IsTest
    static void testGetUserIdsForViewFilter_myView_default() {
        Test.startTest();
        Set<Id> ids = OnboardingAccessService.getUserIdsForViewFilter(null);
        Test.stopTest();

        System.assertEquals(1, ids.size(), 'Null filter should default to MY_VIEW');
        System.assert(ids.contains(UserInfo.getUserId()), 'Current user should be included');
    }

    @IsTest
    static void testGetUserIdsForViewFilter_myView_blank() {
        Test.startTest();
        Set<Id> ids = OnboardingAccessService.getUserIdsForViewFilter('');
        Test.stopTest();

        System.assertEquals(1, ids.size(), 'Blank filter should default to MY_VIEW');
        System.assert(ids.contains(UserInfo.getUserId()), 'Current user should be included');
    }

    @IsTest
    static void testGetUserIdsForViewFilter_orgWide() {
        Test.startTest();
        Set<Id> ids = OnboardingAccessService.getUserIdsForViewFilter('ORG_WIDE');
        Test.stopTest();

        System.assertEquals(0, ids.size(), 'ORG_WIDE should return an empty set (no owner filter)');
    }

    // ============================================================================
    // ACCOUNT OWNERSHIP TESTS - Direct Account Owner
    // ============================================================================

    @IsTest
    static void testGetAccountIdsForOwners_accountOwner() {
        // Create test user and account owned by that user
        User testUser = TestDataFactory.createStandardUser(true);
        Account testAccount = new Account(Name = 'Test Account', OwnerId = testUser.Id);
        insert testAccount;

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(1, accountIds.size(), 'Should return 1 account');
        System.assert(accountIds.contains(testAccount.Id), 'Should include the owned account');
    }

    @IsTest
    static void testGetAccountIdsForOwners_multipleAccounts() {
        // Create test user and multiple accounts owned by that user
        User testUser = TestDataFactory.createStandardUser(true);
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i, OwnerId = testUser.Id));
        }
        insert accounts;

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(5, accountIds.size(), 'Should return 5 accounts');
        for (Account acc : accounts) {
            System.assert(accountIds.contains(acc.Id), 'Should include account: ' + acc.Name);
        }
    }

    @IsTest
    static void testGetAccountIdsForOwners_emptyUserSet() {
        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, accountIds.size(), 'Empty user set should return empty account set');
    }

    @IsTest
    static void testGetAccountIdsForOwners_nullUserSet() {
        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(null);
        Test.stopTest();

        System.assertEquals(0, accountIds.size(), 'Null user set should return empty account set');
    }

    // ============================================================================
    // ACCOUNT OWNERSHIP TESTS - Territory Assignment via Junction
    // ============================================================================

    @IsTest
    static void testGetAccountIdsForOwners_territoryAssignmentViaJunction() {
        // Create complete setup: User → Territory Assignment → Junction → Zip Code → Account
        User testUser = TestDataFactory.createStandardUser(true);
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Territory Assignment with Onboarding Rep
        Territory_Assignments__c territoryAssignment = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser, 
            'Onboarding_Rep__c', 
            true
        );

        // Create Zip Code (Account has lookup TO Zip Code, not the other way around)
        Zip_Code__c zipCode = TestZipCodeFactory.createZipCode(true, '12345');
        // Link Account to Zip Code
        testAccount.Zip_Code__c = zipCode.Id;
        update testAccount;

        // Create Junction linking Territory Assignment to Zip Code
        Zip_Code_Territory__c junction = TestZipCodeFactory.createZipCodeTerritory(
            true,
            territoryAssignment.Id,
            zipCode.Id
        );

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assert(accountIds.contains(testAccount.Id), 
            'Should return account linked via Territory Assignment → Junction → Zip Code');
    }

    @IsTest
    static void testGetAccountIdsForOwners_baseAppOBRepViaJunction() {
        // Test Base_App_OB_Rep__c field instead of Onboarding_Rep__c
        User testUser = TestDataFactory.createStandardUser(true);
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Territory_Assignments__c territoryAssignment = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser, 
            'Base_App_OB_Rep__c', 
            true
        );

        Zip_Code__c zipCode = TestZipCodeFactory.createZipCode(true, '12345');
        testAccount.Zip_Code__c = zipCode.Id;
        update testAccount;
        Zip_Code_Territory__c junction = TestZipCodeFactory.createZipCodeTerritory(
            true,
            territoryAssignment.Id,
            zipCode.Id
        );

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assert(accountIds.contains(testAccount.Id), 
            'Should return account linked via Base_App_OB_Rep__c → Junction → Zip Code');
    }

    @IsTest
    static void testGetAccountIdsForOwners_multipleZipCodesPerTerritory() {
        // Test multiple zip codes linked to same territory assignment
        User testUser = TestDataFactory.createStandardUser(true);
        Territory_Assignments__c territoryAssignment = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser, 
            'Onboarding_Rep__c', 
            true
        );

        List<Account> accounts = new List<Account>();
        List<Zip_Code__c> zipCodes = new List<Zip_Code__c>();
        List<Zip_Code_Territory__c> junctions = new List<Zip_Code_Territory__c>();

        for (Integer i = 0; i < 3; i++) {
            Account acc = new Account(Name = 'Test Account ' + i);
            accounts.add(acc);
        }
        insert accounts;

        for (Integer i = 0; i < accounts.size(); i++) {
            Zip_Code__c zipCode = TestZipCodeFactory.createZipCode(false, '12345');
            zipCodes.add(zipCode);
        }
        insert zipCodes;
        
        // Link Accounts to Zip Codes (Account has lookup TO Zip Code)
        for (Integer i = 0; i < accounts.size(); i++) {
            accounts[i].Zip_Code__c = zipCodes[i].Id;
        }
        update accounts;

        for (Zip_Code__c zipCode : zipCodes) {
            Zip_Code_Territory__c junction = TestZipCodeFactory.createZipCodeTerritory(
                false,
                territoryAssignment.Id,
                zipCode.Id
            );
            junctions.add(junction);
        }
        insert junctions;

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(3, accountIds.size(), 'Should return all 3 accounts');
        for (Account acc : accounts) {
            System.assert(accountIds.contains(acc.Id), 'Should include account: ' + acc.Name);
        }
    }

    @IsTest
    static void testGetAccountIdsForOwners_multipleTerritoriesForSameAccount() {
        // Test same account linked via multiple territory assignments
        User testUser1 = TestDataFactory.createStandardUser(true);
        User testUser2 = TestDataFactory.createStandardUser(true);
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Territory_Assignments__c ta1 = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser1, 'Onboarding_Rep__c', true);
        Territory_Assignments__c ta2 = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser2, 'Base_App_OB_Rep__c', true);

        Zip_Code__c zipCode = TestZipCodeFactory.createZipCode(true, '12345');
        testAccount.Zip_Code__c = zipCode.Id;
        update testAccount;
        
        Zip_Code_Territory__c junction1 = TestZipCodeFactory.createZipCodeTerritory(true, ta1.Id, zipCode.Id);
        Zip_Code_Territory__c junction2 = TestZipCodeFactory.createZipCodeTerritory(true, ta2.Id, zipCode.Id);

        Test.startTest();
        Set<Id> accountIds1 = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser1.Id });
        Set<Id> accountIds2 = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser2.Id });
        Set<Id> accountIdsBoth = OnboardingAccessService.getAccountIdsForOwners(
            new Set<Id>{ testUser1.Id, testUser2.Id });
        Test.stopTest();

        System.assert(accountIds1.contains(testAccount.Id), 'User1 should see account');
        System.assert(accountIds2.contains(testAccount.Id), 'User2 should see account');
        System.assertEquals(1, accountIdsBoth.size(), 'Both users should see same account (deduplicated)');
        System.assert(accountIdsBoth.contains(testAccount.Id), 'Both users should see the account');
    }

    @IsTest
    static void testGetAccountIdsForOwners_combinedOwnerAndTerritory() {
        // Test account owned by user AND linked via territory assignment
        User testUser = TestDataFactory.createStandardUser(true);
        Account testAccount = new Account(Name = 'Test Account', OwnerId = testUser.Id);
        insert testAccount;

        Territory_Assignments__c territoryAssignment = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser, 'Onboarding_Rep__c', true);
        
        Zip_Code__c zipCode = TestZipCodeFactory.createZipCode(true, '12345');
        testAccount.Zip_Code__c = zipCode.Id;
        update testAccount;
        Zip_Code_Territory__c junction = TestZipCodeFactory.createZipCodeTerritory(
            true, territoryAssignment.Id, zipCode.Id);

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(1, accountIds.size(), 'Should return 1 account (deduplicated)');
        System.assert(accountIds.contains(testAccount.Id), 'Should include the account');
    }

    @IsTest
    static void testGetAccountIdsForOwners_noZipCodeLinked() {
        // Test territory assignment with no zip codes linked
        User testUser = TestDataFactory.createStandardUser(true);
        Territory_Assignments__c territoryAssignment = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser, 'Onboarding_Rep__c', true);

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(0, accountIds.size(), 'Should return empty set when no zip codes linked');
    }

    @IsTest
    static void testGetAccountIdsForOwners_zipCodeWithoutAccount() {
        // Test zip code with no account linked
        User testUser = TestDataFactory.createStandardUser(true);
        Territory_Assignments__c territoryAssignment = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser, 'Onboarding_Rep__c', true);

        Zip_Code__c zipCode = TestZipCodeFactory.createZipCode(true, '12345');
        // No Account linked to this Zip Code
        Zip_Code_Territory__c junction = TestZipCodeFactory.createZipCodeTerritory(
            true, territoryAssignment.Id, zipCode.Id);

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(0, accountIds.size(), 'Should return empty set when zip code has no account');
    }

    // ============================================================================
    // PERFORMANCE TESTS
    // ============================================================================

    @IsTest
    static void testGetAccountIdsForOwners_performance_largeDataSet() {
        // Test performance with large dataset
        User testUser = TestDataFactory.createStandardUser(true);
        Territory_Assignments__c territoryAssignment = TestDataFactory.createTerritoryAssignmentWithUser(
            testUser, 'Onboarding_Rep__c', true);

        // Create 100 accounts with zip codes
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;

        List<Zip_Code__c> zipCodes = new List<Zip_Code__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            zipCodes.add(TestZipCodeFactory.createZipCode(false, '12345'));
        }
        insert zipCodes;
        
        // Link Accounts to Zip Codes (Account has lookup TO Zip Code)
        for (Integer i = 0; i < accounts.size(); i++) {
            accounts[i].Zip_Code__c = zipCodes[i].Id;
        }
        update accounts;

        List<Zip_Code_Territory__c> junctions = new List<Zip_Code_Territory__c>();
        for (Zip_Code__c zipCode : zipCodes) {
            junctions.add(TestZipCodeFactory.createZipCodeTerritory(
                false, territoryAssignment.Id, zipCode.Id));
        }
        insert junctions;

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(100, accountIds.size(), 'Should return all 100 accounts');
        // Verify performance: should complete within governor limits
        System.assert(Limits.getQueries() < 10, 
            'Should use efficient queries (actual: ' + Limits.getQueries() + ')');
    }

    // ============================================================================
    // DEPRECATED METHOD TESTS
    // ============================================================================

    @IsTest
    static void testBuildOwnerClause_emptySet() {
        Test.startTest();
        String clause = OnboardingAccessService.buildOwnerClauseForOnboarding(new Set<Id>());
        Test.stopTest();

        System.assertEquals('', clause, 'Empty user set should return empty clause');
    }

    @IsTest
    static void testBuildOwnerClause_nonEmpty() {
        Set<Id> ids = new Set<Id>{ UserInfo.getUserId() };

        Test.startTest();
        String clause = OnboardingAccessService.buildOwnerClauseForOnboarding(ids);
        Test.stopTest();

        System.assertNotEquals('', clause, 'Non-empty user set should return a clause');
        System.assert(clause.contains('Account__r.OwnerId'), 'Clause should reference Account__r.OwnerId');
        // Note: Deprecated method no longer includes Territory_Assignments__c in SOQL
    }
}