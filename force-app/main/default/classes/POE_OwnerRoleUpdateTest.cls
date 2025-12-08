@isTest
public with sharing class POE_OwnerRoleUpdateTest {
    @TestSetup
    static void makeData() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [
            SELECT Id, DeveloperName
            FROM UserRole
            WHERE DeveloperName = 'Sales_Supervisor'
            LIMIT 1
        ];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            // Set up DML options to bypass duplicate rules
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.DuplicateRuleHeader.AllowSave = true;
            dmlOpts.DuplicateRuleHeader.RunAsCurrentUser = false;

            Account testAcc = new Account(
                Name = 'Test' + Math.random(),
                ShippingStreet = 'Test Street' + Math.random(),
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com'
            );
            insert testAcc;

            // Create Contacts with duplicate rule bypass
            Contact userContact = new Contact(
                FirstName = 'test' + Math.random(),
                LastName = 'test' + Math.random(),
                Email = 'test' + Math.random() + '@gmail.com',
                AccountId = testAcc.Id,
                POE_Functional_Role__c = 'Office Manager'
            );
            userContact.setOptions(dmlOpts);

            Contact testContact1 = new Contact(
                FirstName = 'testCont' + Math.random(),
                LastName = 'testCont' + Math.random(),
                Email = 'test' + Math.random() + '@gmail.com',
                AccountId = testAcc.Id,
                POE_Functional_Role__c = 'Office Manager'
            );
            testContact1.setOptions(dmlOpts);

            Contact testContact2 = new Contact(
                FirstName = 'testCont2' + Math.random(),
                LastName = 'testCont2' + Math.random(),
                Email = 'test' + Math.random() + '@gmail.com',
                AccountId = testAcc.Id,
                POE_Functional_Role__c = 'Office Manager'
            );
            testContact2.setOptions(dmlOpts);

            insert new List<Contact>{ userContact, testContact1, testContact2 };

            Profile p = TestHelper.getGeneralProfile();
            User u = new User(
                Alias = 'stdt01',
                Email = '11052022standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '11052022GDGstandarduser@testorg.com'
            );
            User u2 = new User(
                Alias = 'stdt02',
                Email = '11034234standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing2',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = testContact1.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '110520333GDGstandarduser@testorg.com'
            );
            insert new List<User>{ u, u2 };

            List<PermissionSetGroup> permSetGroups = [
                SELECT Id, Status
                FROM PermissionSetGroup
                WHERE DeveloperName IN :POE_PermissionsUtility.OWNER_PS_GROUP_NAMES
                LIMIT 2
            ];

            List<Id> psgIds = new List<Id>();
            for (PermissionSetGroup psg : permSetGroups) {
                if (psg.Status != 'Updated') {
                    psgIds.add(psg.Id);
                }
            }

            if (!psgIds.isEmpty()) {
                Test.calculatePermissionSetGroup(psgIds);
            }

            List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
            permissionSetAssignments.add(
                new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetGroupId = permSetGroups[0].Id)
            );
            permissionSetAssignments.add(
                new PermissionSetAssignment(AssigneeId = u2.Id, PermissionSetGroupId = permSetGroups[1].Id)
            );
            insert permissionSetAssignments;
        }
    }

    @isTest
    public static void schedulableApexTest() {
        Test.startTest();
        POE_OwnerRoleUpdateSchedulable m = new POE_OwnerRoleUpdateSchedulable();
        String sch = '20 30 8 10 2 ?';
        String jobID = System.schedule('Schedulable', sch, m);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        POE_OwnerRoleUpdate role = new POE_OwnerRoleUpdate();
        Id batchInstanceId = Database.executeBatch(role);
        Test.stopTest();
        System.assertEquals(0, ct.TimesTriggered, 'Class was not scheduled.');
        System.assertEquals('20 30 8 10 2 ?', ct.CronExpression, 'Class was not scheduled.');
    }
}