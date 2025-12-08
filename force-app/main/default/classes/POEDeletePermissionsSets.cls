public without sharing class POEDeletePermissionsSets {
    @testVisible
    private static Boolean throwException = false;

    @InvocableMethod(label='Delete Permissions' description='Deletes all previous permissions assigned to the User')
    public static void deletePermissions(List<String> userId) {

        List<PermissionSetAssignment> permSets = [
            SELECT AssigneeId, PermissionSetGroupId, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userId AND PermissionSet.IsOwnedByProfile = FALSE AND PermissionSetGroup.DeveloperName != 'Owner_Permission_Set_Group' AND PermissionSetGroup.DeveloperName != 'Owner_Permissions_No_Maps'
        ];
        try {
            if (throwException) {
                throw new CustomException();
            }

            delete permSets;
        } catch (Exception e) {
            throw e;
        }
    }
}