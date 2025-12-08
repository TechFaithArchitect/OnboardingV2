public class POE_OwnerRoleUpdate implements Database.Batchable<sObject> {

    private static final List<String> OWNER_PERMISSION_SET_GROUP_NAMES = POE_PermissionsUtility.OWNER_PS_GROUP_NAMES;

    public Database.querylocator start(Database.BatchableContext BC) {
        String query;
        if (!Test.isRunningTest()) {
            query = 'SELECT Id, UserRoleId, Account.Name FROM User WHERE AccountId != NULL AND UserRoleId != NULL AND Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name IN :OWNER_PERMISSION_SET_GROUP_NAMES)';
        } else {
            query = 'SELECT Id, UserRoleId, Account.Name FROM User WHERE AccountId != NULL AND UserRoleId != NULL AND Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name IN :OWNER_PERMISSION_SET_GROUP_NAMES) LIMIT 10';
        }
 
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<User> updateUsers = new List<User>();
        Map<String, String> roleIdByName = new Map<String, String>();
        List<String> roles = new List<String>();

        for (sObject a : scope) {
            User s = (User) a;
            roles.add(s.Account.Name + ' Partner Manager');
        }

        List<UserRole> userRoles = [SELECT Id, Name FROM UserRole WHERE Name IN :roles];
        for (UserRole us : userRoles) {
            roleIdByName.put(us.Name, us.Id);
        }

        for (sObject a : scope) {
            User s = (User) a;
            if (s.UserRoleId != roleIdByName.get(s.Account.Name + ' Partner Manager')) {
                s.UserRoleId = roleIdByName.get(s.Account.Name + ' Partner Manager');
            }
            updateUsers.add(s);
        }
        System.debug(updateUsers);

        Database.update(updateUsers, false);
    }

    public void finish(Database.BatchableContext BC) {
    }
}