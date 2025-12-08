public without sharing class POE_PermissionsUtility {
    public static final String OWNER_PERMISSION_SET_NAME = 'Owner_Permission_Set';
    public static final String PHONE_SALES_PS_GROUP_NAME = 'Phone_Sales_Permission_Set_Group';
    public static final String D2D_PS_GROUP_NAME = 'Agent_Permission_Set_Group';
    public static final String RESIDENTIAL_PS_NAME = 'Chuzo_Agent_Residential';
    public static final String PHONE_SALES_PS_NAME = 'Chuzo_Agent_Phone_Sales';
    public static final String OWNER_PROFILE_NAME = 'Owner Profile';
    public static final String AGENT_FUNCTIONAL_ROLE = 'Office Representative';
    public static final String OWNER_PSG_NO_MAPS = 'Owner_Permissions_No_Maps';
    public static final String OWNER_PSG = 'Owner_Permission_Set_Group';
    public static final String COMMUNITY_NAMED_USER_PS_NAME = 'CommunityNamedUser';
    public static final String MAPS_USER_PS_NAME = 'MapsUser';
    public static final String SF_MAPS_PS_NAME = 'SFMaps';
    public static final String CHUZO_PARTNER_NAME = 'Chuzo_Partner';
    public static final List<String> OWNER_PS_GROUP_NAMES = new List<String>{ OWNER_PSG, OWNER_PSG_NO_MAPS };

    public static final Map<String, String> CLICKER_PS_BY_REP_TYPE = new Map<String, String>{
        'Event' => 'Clicker_Event',
        'Retail' => 'Clicker_Retail'
    };

    /**
     * Verifies that the running user is an Agent or an Owner user by checking the assigned
     * Permission Set Groups.
     * @return   return true if the user has any of the agent or owner Permission Set Groups
     *           assigned.
     */
    @AuraEnabled(cacheable=true)
    public static UserRoleInformation userIsAgentOrOwner() {
        try {
            UserRoleInformation roleInfo = userIsAgentOrOwner(new List<String>{ UserInfo.getUserId() })[0];

            return roleInfo;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @InvocableMethod(label='User is Agent or Owner')
    public static List<UserRoleInformation> userIsAgentOrOwner(List<String> userIds) {
        String userId = userIds[0];
        User userInformation = [
            SELECT Profile.Name, Contact.POE_Functional_Role__c
            FROM User
            WHERE Id = :userId
        ];
        String functionalRole = userInformation.Contact.POE_Functional_Role__c;
        Boolean isAgentRole = String.isNotBlank(functionalRole) && functionalRole.contains(AGENT_FUNCTIONAL_ROLE);

        List<String> permissionSetNameList = new List<String>{
            PHONE_SALES_PS_GROUP_NAME,
            D2D_PS_GROUP_NAME,
            RESIDENTIAL_PS_NAME,
            CHUZO_PARTNER_NAME
        };
        permissionSetNameList.addAll(OWNER_PS_GROUP_NAMES);
        permissionSetNameList.addAll(CLICKER_PS_BY_REP_TYPE.values());

        UserRoleInformation roleInformation = new UserRoleInformation();
        for (PermissionSetAssignment psAssignment : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSet.Name IN :permissionSetNameList
        ]) {
            String permSetName = psAssignment.PermissionSet.Name;

            roleInformation.isOwner =
                roleInformation.isOwner ||
                userInformation.Profile.Name == OWNER_PROFILE_NAME ||
                (!isAgentRole && OWNER_PS_GROUP_NAMES.contains(permSetName));

            roleInformation.isPhoneSales = roleInformation.isPhoneSales || permSetName == PHONE_SALES_PS_GROUP_NAME;
            roleInformation.isResidential =
                roleInformation.isResidential ||
                permSetName == D2D_PS_GROUP_NAME ||
                permSetName == RESIDENTIAL_PS_NAME;

            roleInformation.isAgent =
                roleInformation.isAgent ||
                (isAgentRole && (roleInformation.isPhoneSales || roleInformation.isResidential));
        }

        return new List<UserRoleInformation>{ roleInformation };
    }

    public static Map<String, Id> getPermissionsAndGroupsByName() {
        Map<String, Id> permSetOrGroupIdsByName = new Map<String, Id>();
        List<String> permissionSetGroupList = new List<String>{ D2D_PS_GROUP_NAME, PHONE_SALES_PS_GROUP_NAME };
        permissionSetGroupList.addAll(OWNER_PS_GROUP_NAMES);

        for (PermissionSetGroup psg : [
            SELECT Id, DeveloperName
            FROM PermissionSetGroup
            WHERE DeveloperName IN :permissionSetGroupList
        ]) {
            permSetOrGroupIdsByName.put(psg.DeveloperName, psg.Id);
        }

        List<String> permissionSetNameList = new List<String>{
            RESIDENTIAL_PS_NAME,
            PHONE_SALES_PS_NAME,
            COMMUNITY_NAMED_USER_PS_NAME,
            MAPS_USER_PS_NAME,
            SF_MAPS_PS_NAME,
            OWNER_PERMISSION_SET_NAME,
            CHUZO_PARTNER_NAME
        };
        permissionSetNameList.addAll(CLICKER_PS_BY_REP_TYPE.values());
        for (PermissionSet ps : [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name IN :permissionSetNameList
        ]) {
            permSetOrGroupIdsByName.put(ps.Name, ps.Id);
        }

        return permSetOrGroupIdsByName;
    }

    public class UserRoleInformation {
        @AuraEnabled
        @InvocableVariable
        public Boolean isOwner = false;
        @AuraEnabled
        @InvocableVariable
        public Boolean isAgent = false;
        @AuraEnabled
        @InvocableVariable
        public Boolean isPhoneSales = false;
        @AuraEnabled
        @InvocableVariable
        public Boolean isResidential = false;
    }
}