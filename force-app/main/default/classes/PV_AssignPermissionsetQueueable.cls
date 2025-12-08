public class PV_AssignPermissionsetQueueable implements Queueable {
    User user = new User();
    String ResourceType;
    Contact contact;
    list<String> skillList;
    Date skilStartDate;
    Date directvExpiry;
    Date viasatExpiry;
    id paid;
    String imgurl;
    List<Shift> shiftsToCreate;
    String browserTimeZone;
    List<PV_ManageServiceResources.ServiceTerritoryMembership> stmlist = new List<PV_ManageServiceResources.ServiceTerritoryMembership>();

    public PV_AssignPermissionsetQueueable(User us, String Resource, Contact contact, List<PV_ManageServiceResources.ServiceTerritoryMembership> stmlist,
    List<String> skillList, Date startDate, Date directvExpiry,Date viasatExpiry,id paid, List<Shift> shiftsToCreate, String browserTimeZone) {
        this.user = us;
        this.ResourceType = Resource;
        this.contact = contact;
        this.stmlist = stmlist;
        this.skillList = skillList;
        this.skilStartDate = startDate;
        this.directvExpiry = directvExpiry;
        this.viasatExpiry = viasatExpiry;
        this.paid = paid;
        this.imgurl = imgurl;
        this.shiftsToCreate = shiftsToCreate;
        this.browserTimeZone = browserTimeZone;
    }
    
    public void execute(QueueableContext context) {
        Account account = [SELECT Id, Name, Business_Unit__c FROM Account WHERE Id = :contact.AccountId];
        String dispatcherUserRole = account.Name + ' Partner Manager';

        Permission_Set_Assignment__mdt permissionSetAssigment = [
            SELECT  Permission_Sets__c, Permission_Set_Licenses__c, Permission_Set_Group__c, Profile__c, Resource_Type__c
            FROM    Permission_Set_Assignment__mdt
            WHERE   Resource_Type__c = :ResourceType
            AND     Business_Unit__c = :account.Business_Unit__c
            LIMIT 1
        ];

        List<PermissionSetAssignment> permissionSetAssignmentList = [
            SELECT  PermissionSetGroupId, AssigneeId, PermissionSetId, PermissionSet.Name, PermissionSetGroup.DeveloperName
            FROM    PermissionSetAssignment
            WHERE   AssigneeId = :user.Id
        ];

        Map<Id, PermissionSetAssignment> psGroupAssigmentMap = new Map<Id, PermissionSetAssignment>();
        Map<Id, PermissionSetLicenseAssign> psLicenseAssigmentMap = new Map<Id, PermissionSetLicenseAssign>();
        Map<Id, PermissionSetAssignment> psAssigmentMap = new Map<Id, PermissionSetAssignment>();

        // Assign permission set group
        if (permissionSetAssigment.Permission_Set_Group__c != null) {
            String permissionSetGroupName = permissionSetAssigment.Permission_Set_Group__c;
            Id permissionSetGroupId = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName = :permissionSetGroupName].Id;
            psGroupAssigmentMap = assignPermissionSetGroup(permissionSetAssignmentList, permissionSetAssigment, user, permissionSetGroupId);
        }

        // Assign permission set license
        if (permissionSetAssigment.Permission_Set_Licenses__c != null) {
            List<String> permissionSetLicenseNames = permissionSetAssigment.Permission_Set_Licenses__c.split(',');
            List<PermissionSetLicense> newPermissionSetLicenses = [
                SELECT  Id, DeveloperName 
                FROM    PermissionSetLicense 
                WHERE   DeveloperName = :permissionSetLicenseNames
            ];
            psLicenseAssigmentMap = assignPermissionSetLicenses(newPermissionSetLicenses, user);
        }

        // Assign permission set
        if (permissionSetAssigment.Permission_Sets__c != null) {
            List<String> permissionSetNames = permissionSetAssigment.Permission_Sets__c.split(',');
            List<PermissionSet> newPermissionSets = [SELECT Id, Name FROM PermissionSet WHERE Name = :permissionSetNames];
            psAssigmentMap = assignPermissionSets(permissionSetAssignmentList, newPermissionSets, user);
        }
        
        try {
            if (!user.isActive) {
                user.isActive = true;
                update user;
            }
            if (psGroupAssigmentMap.values() != null) {
                insert psGroupAssigmentMap.values();
            }
            if (psLicenseAssigmentMap.values() != null) {
                insert psLicenseAssigmentMap.values();
            }
            if (psAssigmentMap.values() != null) {
                insert psAssigmentMap.values();
            }
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_AssignPermissionsetQueueable.class.getName(), e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        
        if (resourceType.contains('Dispatcher')) {
            user.UserRoleId = [SELECT Id FROM UserRole WHERE Name = :dispatcherUserRole].Id;
            update user;
            
            Set<Id> territoryIds = new Set<Id>();
            Set<String> groupnames = new Set<String>();
            List<GroupMember> GMlist = new List<GroupMember>();
            
            for (PV_ManageServiceResources.ServiceTerritoryMembership stmclass : stmlist) {
                territoryIds.add(stmclass.TerritoryId);
            }
            
            for (ServiceTerritory stm:[SELECT Id, Name FROM ServiceTerritory WHERE Id IN :territoryIds]) {
                groupnames.add(stm.Name);
            }
            
            for (Group gr: [SELECT Id FROM Group WHERE Name IN :groupnames]) {
                GroupMember GM = new GroupMember();
                GM.GroupId = gr.id;
                GM.UserOrGroupId = user.Id;
                GMList.add(GM);        
            }
            
            if (!GMList.IsEmpty()) {
                try {
                    insert GMList;
                } catch (Exception e) {
                    ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_AssignPermissionsetQueueable.class.getName(), e.getMessage());
                    throw new AuraHandledException(e.getMessage());
                }
            }
        }
        
        if (!Test.isRunningTest()) {
            if (resourceType != 'Dispatcher') {
                if (resourceType == 'Technician') {
                    String TechUserRole=[Select Name from Account where Id=:contact.AccountId].Name+' Partner User';
                    user.UserRoleId=[select Id from UserRole where Name =:TechUserRole].Id;
                    update user;
                }
                System.enqueueJob(new PV_CreateSRandSTMQueueable(user, resourceType, contact, stmlist, skillList, skilStartDate, directvExpiry, viasatExpiry, paid, shiftsToCreate, browserTimeZone));
            }
        }
    }

    public static Map<Id, PermissionSetAssignment> assignPermissionSetGroup(
        List<PermissionSetAssignment> permissionSetAssignmentList, Permission_Set_Assignment__mdt permissionSetAssigment, User user, Id permissionSetGroupId) {
        
        Boolean psGroupExist = false;
        PermissionSetAssignment permissionSetGroupAssignment = new PermissionSetAssignment();
        Map<Id, PermissionSetAssignment> psGroupAssigmentMap = new Map<Id, PermissionSetAssignment>();
        
        for (PermissionSetAssignment pst : permissionSetAssignmentList) {
            if (pst.PermissionSetGroup.DeveloperName == permissionSetAssigment.Permission_Set_Group__c) {
                psGroupExist = true;
            }
        }

        if (psGroupExist == false) {
            permissionSetGroupAssignment.AssigneeId = user.Id;
            permissionSetGroupAssignment.PermissionSetGroupId = permissionSetGroupId;
            psGroupAssigmentMap.put(user.Id, permissionSetGroupAssignment);
        }

        return psGroupAssigmentMap;
    }

    public static Map<Id, PermissionSetLicenseAssign> assignPermissionSetLicenses(List<PermissionSetLicense> newPermissionSetLicenses, User user) {
        List<PermissionSetLicenseAssign> permissionSetLicenseAssignmentList = [
            SELECT  Id, PermissionSetLicenseId, AssigneeId 
            FROM    PermissionSetLicenseAssign
            WHERE   AssigneeId = :user.Id
        ];

        Map<Id, PermissionSetLicenseAssign> psLicenseAssigmentMap = new Map<Id, PermissionSetLicenseAssign>();
        Set<Id> assignedPermissionLicenseSetIds = new Set<Id>();
        
        for (PermissionSetLicenseAssign permissionSetLicenseAssignment : permissionSetLicenseAssignmentList) {
            assignedPermissionLicenseSetIds.add(permissionSetLicenseAssignment.PermissionSetLicenseId);
        }

        for (PermissionSetLicense permissionSetLicense : newPermissionSetLicenses) {
            if (!assignedPermissionLicenseSetIds.contains(permissionSetLicense.Id)) {

                PermissionSetLicenseAssign newPermissionSetLicenseAssignment = new PermissionSetLicenseAssign(
                    AssigneeId = user.Id,
                    PermissionSetLicenseId = permissionSetLicense.Id
                );
                psLicenseAssigmentMap.put(permissionSetLicense.Id, newPermissionSetLicenseAssignment);
            }
        }

        return psLicenseAssigmentMap;
    }

    public static Map<Id, PermissionSetAssignment> assignPermissionSets(
        List<PermissionSetAssignment> permissionSetAssignmentList, List<PermissionSet> newPermissionSets, User user) {

        Map<Id, PermissionSetAssignment> psAssigmentMap = new Map<Id, PermissionSetAssignment>();
        Set<String> assignedPermissionSetNames = new Set<String>();
        
        for (PermissionSetAssignment permissionSetAssignment : permissionSetAssignmentList) {
            assignedPermissionSetNames.add(permissionSetAssignment.PermissionSet.Name);
        }

        for (PermissionSet permissionSet : newPermissionSets) {
            if (!assignedPermissionSetNames.contains(permissionSet.Name)) {
                PermissionSetAssignment newPermissionSetAssignment = new PermissionSetAssignment(
                    AssigneeId = user.Id,
                    PermissionSetId = permissionSet.Id
                );
                psAssigmentMap.put(permissionSet.Id, newPermissionSetAssignment);
            }
        }

        return psAssigmentMap;
    }
}