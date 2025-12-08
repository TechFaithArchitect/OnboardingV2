@isTest
public class POE_AddRepPermissionsQueueableTest {
    private static final List<String> PERMISSION_SET_GROUPS_TO_CHECK = new List<String>{
        POE_PermissionsUtility.OWNER_PSG_NO_MAPS,
        POE_PermissionsUtility.OWNER_PSG,
        POE_PermissionsUtility.PHONE_SALES_PS_GROUP_NAME,
        POE_PermissionsUtility.D2D_PS_GROUP_NAME
    };

    @TestSetup
    static void setup() {
        List<Id> psGroupIds = new List<Id>();
        for (PermissionSetGroup psGroup : [
            SELECT Id, Status
            FROM PermissionSetGroup
            WHERE DeveloperName IN :PERMISSION_SET_GROUPS_TO_CHECK
        ]) {
            if (psGroup.Status != 'Updated') {
                psGroupIds.add(psGroup.Id);
            }
        }
        if (!psGroupIds.isEmpty()) {
            Test.calculatePermissionSetGroup(psGroupIds);
        }

        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Account testAccount = new Account(Name = 'test');
            insert testAccount;

            Contact testOwnerFullContact = new Contact(
                AccountId = testAccount.Id,
                FirstName = 'test',
                LastName = 'Test Owner',
                POE_Representative_Type__c = 'Door To Door;Event;Retail;Phone Sales',
                POE_Functional_Role__c = 'Office Manager',
                POE_RO_Status__c = ''
            );
            insert testOwnerFullContact;

            Contact testAgentContact = new Contact(
                AccountId = testAccount.Id,
                FirstName = 'test',
                LastName = 'Test Agent',
                POE_Representative_Type__c = 'Door To Door;Phone Sales',
                POE_Functional_Role__c = 'Office Representative',
                POE_RO_Status__c = ''
            );
            insert testAgentContact;

            Profile p = TestHelper.getGeneralProfile();
            User ownerUser = new User(
                Alias = 'stanow',
                Email = '03062024AddRepPermissionsQueueableTestOW@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test Owner',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = testOwnerFullContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '03062024AddRepPermissionsQueueableTestOW@testorg.com'
            );
            User agentUser = new User(
                Alias = 'stanps',
                Email = '03062024AddRepPermissionsQueueableTestAG@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test Agent',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = testAgentContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '03062024AddRepPermissionsQueueableTestAG@testorg.com'
            );

            List<User> testUsers = new List<User>{ ownerUser, agentUser };
            insert testUsers;
        }
    }

    @isTest
    static void addAllPermissionsTest() {
        Contact testOwnerFullContact = [
            SELECT Id
            FROM Contact
            WHERE LastName = 'Test Owner'
            LIMIT 1
        ];
        User testUser = [
            SELECT Id
            FROM User
            WHERE ContactId = :testOwnerFullContact.Id
        ];

        Test.startTest();
        System.enqueueJob(new POE_AddRepPermissionsQueueable(testOwnerFullContact.Id, testUser.Id));
        Test.stopTest();

        Set<String> psasToCheck = new Set<String>{
            POE_PermissionsUtility.OWNER_PSG_NO_MAPS,
            POE_PermissionsUtility.OWNER_PERMISSION_SET_NAME,
            POE_PermissionsUtility.OWNER_PSG,
            POE_PermissionsUtility.PHONE_SALES_PS_NAME,
            POE_PermissionsUtility.PHONE_SALES_PS_GROUP_NAME,
            POE_PermissionsUtility.RESIDENTIAL_PS_NAME,
            POE_PermissionsUtility.COMMUNITY_NAMED_USER_PS_NAME,
            POE_PermissionsUtility.MAPS_USER_PS_NAME,
            POE_PermissionsUtility.SF_MAPS_PS_NAME,
            POE_PermissionsUtility.D2D_PS_GROUP_NAME
        };
        psasToCheck.addAll(POE_PermissionsUtility.CLICKER_PS_BY_REP_TYPE.values());

        for (PermissionSetAssignment psas : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id AND PermissionSet.Name IN :psasToCheck
        ]) {
            System.debug(psas.PermissionSet.Name);
        }

        Integer psasCount = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id AND PermissionSet.Name IN :psasToCheck
        ];
        Assert.areEqual(
            psasToCheck.size(),
            psasCount,
            'Some or all of the expected permission set assignments were not created.'
        );
    }

    @isTest
    static void addSomePermissionsTest() {
        Contact testAgentContact = [
            SELECT Id
            FROM Contact
            WHERE LastName = 'Test Agent'
            LIMIT 1
        ];
        User testUser = [
            SELECT Id
            FROM User
            WHERE ContactId = :testAgentContact.Id
        ];

        List<PermissionSetAssignment> startingPSAS = new List<PermissionSetAssignment>();
        for (PermissionSet ps : [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :POE_PermissionsUtility.MAPS_USER_PS_NAME
        ]) {
            startingPSAS.add(new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps.Id));
        }
        insert startingPSAS;
        System.runAs(testUser) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, testUser, POE_PermissionsUtility.PHONE_SALES_PS_GROUP_NAME);
        }

        Test.startTest();
        System.enqueueJob(new POE_AddRepPermissionsQueueable(testAgentContact.Id, testUser.Id));
        Test.stopTest();

        Set<String> psasToCheck = new Set<String>{
            POE_PermissionsUtility.PHONE_SALES_PS_GROUP_NAME,
            POE_PermissionsUtility.RESIDENTIAL_PS_NAME,
            POE_PermissionsUtility.COMMUNITY_NAMED_USER_PS_NAME,
            POE_PermissionsUtility.SF_MAPS_PS_NAME,
            POE_PermissionsUtility.D2D_PS_GROUP_NAME,
            POE_PermissionsUtility.PHONE_SALES_PS_NAME,
            POE_PermissionsUtility.MAPS_USER_PS_NAME
        };

        for (PermissionSetAssignment psas : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id AND PermissionSet.Name IN :psasToCheck
        ]) {
            System.debug(psas.PermissionSet.Name);
        }

        Integer psasCount = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id AND PermissionSet.Name IN :psasToCheck
        ];
        Assert.areEqual(
            psasToCheck.size(),
            psasCount,
            'Some or all of the expected permission set assignments were not created.'
        );
    }
}