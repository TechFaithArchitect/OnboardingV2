@isTest
public class POE_GetOpportunitiesByWaypointOrderTest {
    @TestSetup
    static void makeData() {
        Account testAcc = new Account(
            Name = 'Test',
            ShippingStreet = 'Test Street',
            POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com'
        );
        insert testAcc;

        Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
        insert userContact;

        Profile p = TestHelper.getGeneralProfile();
        User u = new User(
            Alias = 'standt',
            Email = '11052082standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            ContactId = userContact.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = '11052022GDGstandarduser@testorg.com'
        );
        insert u;

        Opportunity opp1 = new Opportunity(
            Name = 'TEST1',
            CloseDate = System.today(),
            OwnerId = u.Id,
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp1;
        Opportunity opp2 = new Opportunity(
            Name = 'TEST2',
            CloseDate = System.today(),
            OwnerId = u.Id,
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp2;
        Opportunity opp3 = new Opportunity(
            Name = 'TEST3',
            CloseDate = System.today(),
            OwnerId = u.Id,
            AccountId = testAcc.Id,
            StageName = 'Qualification',
            Maps_PostalCode__c = '72212'
        );
        insert opp3;

        maps__Route__c route = new maps__Route__c(
            maps__Date__c = System.today(),
            maps__User__c = u.Id,
            name = 'Test route'
        );
        insert route;

        maps__Waypoint__c waypoint1 = new maps__Waypoint__c(
            maps__Route__c = route.Id,
            maps__SortOrder__c = 1,
            maps__Opportunity__c = opp1.Id,
            maps__BaseObject__c = 'Opportunity'
        );
        insert waypoint1;

        maps__Waypoint__c waypoint2 = new maps__Waypoint__c(
            maps__Route__c = route.Id,
            maps__SortOrder__c = 2,
            maps__Opportunity__c = opp2.Id
        );
        insert waypoint2;
    }

    @isTest
    private static void testOppWithWaypoint() {
        List<Opportunity> opps = [SELECT Id,Name FROM Opportunity];
        Opportunity opp = opps[0];
        User user = [SELECT Id FROM User WHERE Name = 'Testing'];
        Map<Integer, Opportunity> testMap = POE_GetOpportunitiesByWaypointOrder.getOpportunitiesByWaypointOrder(opp.Id);
        System.assertEquals(1, testMap.size(), 'testOppWithWaypoint');
    }

    @isTest
    private static void testOppWithoutWaypoint() {
        List<Opportunity> opps = [SELECT Id,Name FROM Opportunity];
        Opportunity opp = opps[2];
        User user = [SELECT Id FROM User WHERE Name = 'Testing'];
        Map<Integer, Opportunity> testMap = POE_GetOpportunitiesByWaypointOrder.getOpportunitiesByWaypointOrder(opp.Id);
        System.assertEquals(1, testMap.size(), 'testOppWithoutWaypoint');
    }
}