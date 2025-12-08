public without sharing class PV_CreateStmGroupMembersHandler {
    public static void createGroupMembers(List<GroupMember> members) {
        insert members;
    }
    public static void deleteGroupMembers(List<GroupMember> members) {
        delete members;
    }
}