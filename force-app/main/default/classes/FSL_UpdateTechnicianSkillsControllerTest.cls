@isTest
public class FSL_UpdateTechnicianSkillsControllerTest {
    public static final String DEALER_RECORD_TYPE = 'POE_Dealer';

    @testSetup
    static void makeData() {
        RecordType dealerRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = :DEALER_RECORD_TYPE];

        Account account = new Account(
            Name = 'Test Account',
            Available_FSL_Vendors__c = 'T-Mobile;WOW',
            RecordTypeId = dealerRecordType.Id
        );
        insert account;

        Contact contact = PV_TestDataFactory.createContact('Test', 'Contact', true, account);
        User user = PV_TestDataFactory.createTechnicianUser(true, contact);

        System.runAs(user) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, user, 'FSL_Technician');
        }

        ServiceResource serviceResource = new ServiceResource(
            Name = 'Test Technician',
            AccountId = account.Id,
            Vendor_Type__c = 'T-Mobile',
            RelatedRecordId = user.Id,
            IsActive = true
        );
        insert serviceResource;

        Skill tMobileSkill = [
            SELECT  Id, DeveloperName, MasterLabel
            FROM    Skill
            WHERE   DeveloperName = 'T_Mobile_Fixed_Wireless'
            LIMIT 1
        ];

        ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill(
            ServiceResourceId = serviceResource.Id,
            SkillId = tMobileSkill.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = null
        );
        insert serviceResourceSkill;
    }

    @isTest
    static void getAccountVendorsTest() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<String> vendors = FSL_UpdateTechnicianSkillsController.getAccountVendors(testAccount.Id);
        Assert.areEqual(2, vendors.size());
        Assert.isTrue(vendors.contains('T-Mobile'));
        Assert.isTrue(vendors.contains('WOW'));
    }

    @isTest
    static void getTechnicianVendorsTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        String vendorString = FSL_UpdateTechnicianSkillsController.getTechnicianVendors(serviceResource.Id);
        Assert.areEqual('T-Mobile', vendorString);
    }

    @isTest
    static void getActiveTechnicianSkillIdsTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        List<Id> activeSkillIds = FSL_UpdateTechnicianSkillsController.getActiveTechnicianSkillIds(serviceResource.Id);
        Assert.areEqual(1, activeSkillIds.size(), 'There should be one active skill');
    }

    @isTest
    static void updateTechnicianSkillsTestAddAndRemoveSkill() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];

        Skill tMobileSkill = [
            SELECT Id, DeveloperName, MasterLabel
            FROM Skill
            WHERE DeveloperName = 'T_Mobile_Fixed_Wireless'
            LIMIT 1
        ];

        Skill wowSkill = [
            SELECT Id, DeveloperName, MasterLabel
            FROM Skill
            WHERE DeveloperName = 'Cable_Construction'
            LIMIT 1
        ];

        List<FSL_UpdateTechnicianSkillsController.SkillWrapper> skillWrappers = new List<FSL_UpdateTechnicianSkillsController.SkillWrapper>();

        FSL_UpdateTechnicianSkillsController.SkillWrapper tMobileWrapper = new FSL_UpdateTechnicianSkillsController.SkillWrapper();
        tMobileWrapper.Id = tMobileSkill.Id;
        tMobileWrapper.DeveloperName = tMobileSkill.DeveloperName;
        tMobileWrapper.MasterLabel = tMobileSkill.MasterLabel;
        tMobileWrapper.isSelected = false;
        skillWrappers.add(tMobileWrapper);

        FSL_UpdateTechnicianSkillsController.SkillWrapper wowWrapper = new FSL_UpdateTechnicianSkillsController.SkillWrapper();
        wowWrapper.Id = wowSkill.Id;
        wowWrapper.DeveloperName = wowSkill.DeveloperName;
        wowWrapper.MasterLabel = wowSkill.MasterLabel;
        wowWrapper.isSelected = true;
        skillWrappers.add(wowWrapper);

        Test.startTest();
        FSL_UpdateTechnicianSkillsController.updateTechnicianSkills(
            serviceResource.Id,
            Date.today(),
            JSON.serialize(skillWrappers)
        );
        Test.stopTest();

        List<ServiceResourceSkill> updatedSkills = [
            SELECT SkillId, EffectiveEndDate
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :serviceResource.Id
        ];

        Boolean foundEndDated = false;
        for (ServiceResourceSkill skill : updatedSkills) {
            if (skill.EffectiveEndDate != null) {
                foundEndDated = true;
                break;
            }
        }

        Assert.isTrue(updatedSkills.size() >= 2, 'There should be at least two skills (one removed, one added)');
        Assert.isTrue(foundEndDated, 'At least one skill should have been end-dated');
    }

    @isTest
    static void updateTechnicianVendorsTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        FSL_UpdateTechnicianSkillsController.updateTechnicianVendors(serviceResource.Id, 'WOW');

        ServiceResource updated = [SELECT Vendor_Type__c FROM ServiceResource WHERE Id = :serviceResource.Id];
        Assert.areEqual('WOW', updated.Vendor_Type__c);
    }

    @isTest
    static void updateSkillsTestUpdateSkill() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        Skill wowSkill = [
            SELECT  Id, DeveloperName
            FROM    Skill
            WHERE   DeveloperName = 'Cable_Construction'
            LIMIT 1
        ];

        ServiceResourceSkill endDatedSkill = new ServiceResourceSkill(
            ServiceResourceId = serviceResource.Id,
            SkillId = wowSkill.Id,
            EffectiveStartDate = Date.today().addDays(-20),
            EffectiveEndDate = Date.today().addDays(-10)
        );
        insert endDatedSkill;

        Test.startTest();
        FSL_UpdateTechnicianSkillsController.updateSkills(serviceResource.Id, new List<String>{ wowSkill.DeveloperName }, 'Update');
        Test.stopTest();

        ServiceResourceSkill updated = [
            SELECT  EffectiveEndDate
            FROM    ServiceResourceSkill
            WHERE   Id = :endDatedSkill.Id
        ];
        
        Assert.areEqual(null, updated.EffectiveEndDate, 'Skill should have been reactivated');
    }

    @isTest
    static void updateSkillsTestRemoveSkill() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        Skill tMobileSkill = [
            SELECT  Id, DeveloperName
            FROM    Skill
            WHERE   DeveloperName = 'T_Mobile_Fixed_Wireless'
            LIMIT 1
        ];

        Test.startTest();
        FSL_UpdateTechnicianSkillsController.updateSkills(
            serviceResource.Id,
            new List<String>{ tMobileSkill.DeveloperName },
            'Remove'
        );
        Test.stopTest();

        List<ServiceResourceSkill> updated = [
            SELECT  EffectiveEndDate 
            FROM    ServiceResourceSkill
            WHERE   ServiceResourceId = :serviceResource.Id 
            AND     SkillId = :tMobileSkill.Id
        ];
        
        Assert.areNotEqual(null, updated[0].EffectiveEndDate, 'Skill should have been end-dated');
    }

    @isTest
    static void updateSkillsTestFutureStartDate() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        Skill wowSkill = [
            SELECT  Id, DeveloperName
            FROM    Skill
            WHERE   DeveloperName = 'Cable_Construction'
            LIMIT 1
        ];

        ServiceResourceSkill futureSkill = new ServiceResourceSkill(
            ServiceResourceId = serviceResource.Id,
            SkillId = wowSkill.Id,
            EffectiveStartDate = Date.today().addDays(3),
            EffectiveEndDate = null
        );
        insert futureSkill;

        Test.startTest();
        FSL_UpdateTechnicianSkillsController.updateSkills(serviceResource.Id, new List<String>{ wowSkill.DeveloperName }, 'Remove');
        Test.stopTest();

        ServiceResourceSkill updated = [
            SELECT  EffectiveStartDate, EffectiveEndDate
            FROM    ServiceResourceSkill
            WHERE   Id = :futureSkill.Id
        ];

        Assert.areEqual(Date.today(), updated.EffectiveStartDate.date(), 'Start date should have been updated to now');
        Assert.areNotEqual(null, updated.EffectiveEndDate, 'End date should have been set');
    }
}