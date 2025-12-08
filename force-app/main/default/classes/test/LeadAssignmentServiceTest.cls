@IsTest
private class LeadAssignmentServiceTest {

    private static Territory_Assignments__c createTerritoryWithOwner(User owner) {
        Territory_Assignments__c territory = TestDataFactory.createTerritoryAssignmentWithUser(
            owner,
            'Onboarding_Rep__c',
            false
        );
        territory.OwnerId = owner.Id;
        insert territory;
        return territory;
    }

    @IsTest
    static void assignsOwnerFromZipTerritory() {
        User ownerUser = TestDataFactory.createStandardUser(true);
        Territory_Assignments__c territory = createTerritoryWithOwner(ownerUser);
        Zip_Code__c zip = TestZipCodeFactory.createZipCode(true, null, '12345');
        TestZipCodeFactory.createZipCodeTerritory(true, territory.Id, zip.Id);

        User creator = TestDataFactory.createStandardUser(true);

        System.runAs(creator) {
            Test.startTest();
            Lead ld = new Lead(LastName = 'Mapped', Company = 'Acme', PostalCode = '12345-6789');
            insert ld;
            Test.stopTest();

            ld = [SELECT OwnerId FROM Lead WHERE Id = :ld.Id];
            System.assertEquals(ownerUser.Id, ld.OwnerId, 'Lead owner should come from territory assignment');
        }
    }

    @IsTest
    static void defaultsToCreatorWhenNoZipMatch() {
        User creator = TestDataFactory.createStandardUser(true);

        System.runAs(creator) {
            Test.startTest();
            Lead ld = new Lead(LastName = 'NoMatch', Company = 'Acme', PostalCode = '99999');
            insert ld;
            Test.stopTest();

            ld = [SELECT OwnerId FROM Lead WHERE Id = :ld.Id];
            System.assertEquals(creator.Id, ld.OwnerId, 'Should fall back to creator when no ZIP mapping exists');
        }
    }

    @IsTest
    static void choosesFirstTerritoryWhenMultipleMappings() {
        User firstOwner = TestDataFactory.createStandardUser(true);
        User secondOwner = TestDataFactory.createStandardUser(true);

        Territory_Assignments__c firstTerritory = createTerritoryWithOwner(firstOwner);
        Territory_Assignments__c secondTerritory = createTerritoryWithOwner(secondOwner);

        Zip_Code__c zip = TestZipCodeFactory.createZipCode(true, null, '54321');
        TestZipCodeFactory.createZipCodeTerritory(true, firstTerritory.Id, zip.Id);
        TestZipCodeFactory.createZipCodeTerritory(true, secondTerritory.Id, zip.Id);

        User creator = TestDataFactory.createStandardUser(true);

        System.runAs(creator) {
            Test.startTest();
            Lead ld = new Lead(LastName = 'Multi', Company = 'Acme', PostalCode = '54321');
            insert ld;
            Test.stopTest();

            ld = [SELECT OwnerId FROM Lead WHERE Id = :ld.Id];
            System.assertEquals(firstOwner.Id, ld.OwnerId, 'Should pick the first territory assignment for the ZIP');
        }
    }

    @IsTest
    static void assignsOwnerForContact() {
        User ownerUser = TestDataFactory.createStandardUser(true);
        Territory_Assignments__c territory = createTerritoryWithOwner(ownerUser);
        Zip_Code__c zip = TestZipCodeFactory.createZipCode(true, null, '77777');
        TestZipCodeFactory.createZipCodeTerritory(true, territory.Id, zip.Id);

        User creator = TestDataFactory.createStandardUser(true);

        System.runAs(creator) {
            Test.startTest();
            Contact con = new Contact(LastName = 'Mapped', MailingPostalCode = '77777-1234');
            insert con;
            Test.stopTest();

            con = [SELECT OwnerId FROM Contact WHERE Id = :con.Id];
            System.assertEquals(ownerUser.Id, con.OwnerId, 'Contact owner should come from territory assignment');
        }
    }

    @IsTest
    static void assignsOwnerForAccount() {
        User ownerUser = TestDataFactory.createStandardUser(true);
        Territory_Assignments__c territory = createTerritoryWithOwner(ownerUser);
        Zip_Code__c zip = TestZipCodeFactory.createZipCode(true, null, '88888');
        TestZipCodeFactory.createZipCodeTerritory(true, territory.Id, zip.Id);

        User creator = TestDataFactory.createStandardUser(true);

        System.runAs(creator) {
            Test.startTest();
            Account acc = new Account(Name = 'Mapped Account', BillingPostalCode = '88888');
            insert acc;
            Test.stopTest();

            acc = [SELECT OwnerId FROM Account WHERE Id = :acc.Id];
            System.assertEquals(ownerUser.Id, acc.OwnerId, 'Account owner should come from territory assignment');
        }
    }

    @IsTest
    static void defaultsForContactWhenNoZipMatch() {
        User creator = TestDataFactory.createStandardUser(true);

        System.runAs(creator) {
            Test.startTest();
            Contact con = new Contact(LastName = 'NoMatch', MailingPostalCode = '00000');
            insert con;
            Test.stopTest();

            con = [SELECT OwnerId FROM Contact WHERE Id = :con.Id];
            System.assertEquals(creator.Id, con.OwnerId, 'Contact should fall back to creator when no mapping exists');
        }
    }

    @IsTest
    static void defaultsForAccountWhenNoZipMatch() {
        User creator = TestDataFactory.createStandardUser(true);

        System.runAs(creator) {
            Test.startTest();
            Account acc = new Account(Name = 'NoMatch Account', BillingPostalCode = '00000');
            insert acc;
            Test.stopTest();

            acc = [SELECT OwnerId FROM Account WHERE Id = :acc.Id];
            System.assertEquals(creator.Id, acc.OwnerId, 'Account should fall back to creator when no mapping exists');
        }
    }

    @IsTest
    static void reassignsWhenLeadPostalChanges() {
        User owner1 = TestDataFactory.createStandardUser(true);
        User owner2 = TestDataFactory.createStandardUser(true);

        String picklistDivision = getAnyPicklistValue('Division__c');
        String picklistRegion = getAnyPicklistValue('Region__c');
        String picklistTerritory = getAnyPicklistValue('Territory__c');

        Territory_Assignments__c ta1 = createTerritoryWithOwner(owner1);
        ta1.Division__c = picklistDivision;
        ta1.Region__c = picklistRegion;
        ta1.Territory__c = picklistTerritory;
        update ta1;

        Territory_Assignments__c ta2 = createTerritoryWithOwner(owner2);
        ta2.Division__c = picklistDivision;
        ta2.Region__c = picklistRegion;
        ta2.Territory__c = picklistTerritory;
        update ta2;

        Zip_Code__c zip1 = TestZipCodeFactory.createZipCode(true, '10101');
        Zip_Code__c zip2 = TestZipCodeFactory.createZipCode(true, '20202');

        TestZipCodeFactory.createZipCodeTerritory(true, ta1.Id, zip1.Id);
        TestZipCodeFactory.createZipCodeTerritory(true, ta2.Id, zip2.Id);

        User creator = TestDataFactory.createStandardUser(true);
        Lead ld;

        System.runAs(creator) {
            Test.startTest();
            ld = new Lead(LastName = 'ChangeZip', Company = 'Acme', PostalCode = '10101');
            insert ld;
            ld.PostalCode = '20202';
            update ld;
            Test.stopTest();
        }

        ld = [SELECT OwnerId, Division__c, Region__c, Territory__c FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(owner2.Id, ld.OwnerId, 'Lead owner should update when postal code changes to new mapped ZIP');
        System.assertEquals(picklistDivision, ld.Division__c, 'Division should map from territory assignment');
        System.assertEquals(picklistRegion, ld.Region__c, 'Region should map from territory assignment');
        System.assertEquals(picklistTerritory, ld.Territory__c, 'Territory should map from territory assignment');
    }

    private static String getAnyPicklistValue(String fieldName) {
        Schema.DescribeFieldResult dfr = Lead.SObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
        for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }
}