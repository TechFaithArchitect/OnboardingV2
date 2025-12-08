@isTest
public class PV_CreateStmControllerTest {
    @TestSetup
    static void makeTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = PV_TestDataFactory.createAccount('Test Account', true);
            contact con = PV_TestDataFactory.createContact('Test', 'contact_01', true, acc);
            OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'NY-01', opHrs);
            ServiceTerritory pst1 = PV_TestDataFactory.createParentServiceTerritory(true, 'NY-02', opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(
                true,
                acc,
                pst
            );
            ServiceTerritory childServiceTerritory1 = PV_TestDataFactory.createServiceTerritoryForAccount(
                true,
                acc,
                pst1
            );
            User usr = PV_TestDataFactory.createTechnicianUser(true, con);
            System.runAs(usr) {
                PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            }
            ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true, acc, con, usr);
            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(
                true,
                ServiceRes,
                childServiceTerritory,
                'P'
            );
        }

        Group g = new Group();
        g.Name = 'testGroup';

        insert g;
    }
    @IsTest
    static void testManageStm() {
        Test.startTest();
        list<ServiceResource> serviceResourceList = PV_CreateStmController.getResourceList([SELECT Id FROM Account].Id);
        Test.stopTest();
        System.assertEquals(1, serviceResourceList.size(), 'Resources were not fetched.');
    }

    @isTest
    static void getStmAsscociatedWithResourceTest() {
        Test.startTest();
        list<PV_CreateStmController.ResourceWrapper> wrapperList = PV_CreateStmController.getStmAsscociatedWithResource(
            [SELECT Id FROM ServiceResource]
            .Id,
            [SELECT Id FROM Account]
            .Id
        );
        Test.stopTest();
        System.assertEquals(2, wrapperList.size(), 'Resources were not fetched.');
    }

    @isTest
    static void getStmAsscociatedWithResourceDispatchersTest() {
        Test.startTest();
        list<PV_CreateStmController.DispatcherWrapper> wrapperList = PV_CreateStmController.getStmAsscociatedWithResourceDispatchers(
            [SELECT Id FROM Contact]
            .Id,
            [SELECT Id FROM Account]
            .Id
        );
        Test.stopTest();
        System.assertEquals(false, wrapperList.isEmpty(), 'Resources were not fetched.');
    }

    @isTest
    public static void testProcessMemberships() {
        User u = [SELECT Id FROM USER LIMIT 1];
        List<Map<String, String>> members = new List<Map<String, String>>();
        Map<String, String> member1 = new Map<String, String>();
        member1.put('groupName', 'testGroup');
        member1.put('userId', u.Id);
        member1.put('isTerritoryMember', 'true');
        members.add(member1);

        Test.startTest();
        PV_CreateStmController.processMemberships(members);
        Test.stopTest();
        List<Group> groups = [SELECT Id, Name FROM Group WHERE Name = 'testGroup'];
        System.assertEquals(false, groups.isEmpty(), 'Group was not created.');
    }

    @isTest
    static void upsertStm() {
    
        ServiceResource testResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceTerritory testTerritory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceTerritoryMember existingStm = [SELECT Id, ServiceTerritoryId FROM ServiceTerritoryMember LIMIT 1];

        List<Map<String, String>> resourceRegionList = new List<Map<String, String>>{
            new Map<String, String>{
                'serviceTerritoryId' => testTerritory.Id,
                'serviceTerritoryMemberId' => existingStm.Id,
                'isChecked' => 'true', 
                'EndDate' => null
            }
        };

        Test.startTest();
        String result = PV_CreateStmController.upsertStm(resourceRegionList, testResource.Id, System.today());
        Test.stopTest();

        System.assertEquals('Success', result, 'Expected Success response');
    }

    @isTest
    static void getSTMAddressTest() {
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        Test.startTest();
        List<ServiceTerritoryMember> members = PV_CreateStmController.getSTMAddress(resource.Id);
        Test.stopTest();
        System.assertEquals(false, members[0].Address == null, 'Address was not fetched correctly.');
    }

    @isTest
    static void updateSTMAddressTest() {
        Id memberId = [SELECT Id FROM ServiceTerritoryMember LIMIT 1].Id;
        Map<String, Object> addressMap = new Map<String, Object>{
            'street' => '416 Mission St',
            'city' => 'San Francisco',
            'state' => 'California',
            'stateCode' => 'CA',
            'zip' => '94105',
            'country' => 'United States',
            'countryCode' => 'US'
        };
        Test.startTest();
        ServiceTerritoryMember member = PV_CreateStmController.updateSTMAddress(memberId, addressMap);
        Test.stopTest();
        System.assertEquals('San Francisco', member.City, 'City was not correctly updated.');
        System.assertEquals('416 Mission St', member.Street, 'Street was not correctly updated.');
    }
}