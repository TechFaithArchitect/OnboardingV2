public without sharing class NetworkMemberTriggerHandler extends TriggerHandler {
    private List<NetworkMember> newList;
    private List<NetworkMember> oldList;
    public static Boolean active = true;
    public NetworkMemberTriggerHelper helper;

    public NetworkMemberTriggerHandler() {
        this.newList = (List<NetworkMember>) Trigger.new;
        this.oldList = (List<NetworkMember>) Trigger.old;
        this.helper = new NetworkMemberTriggerHelper();
    }

    public override void afterInsert() {
        helper.updateMembership(newList, true);
    }

    public override void afterUpdate() {
        helper.updateMembership(newList, true);
    }

    public override void afterDelete() {
        helper.updateMembership(oldList, false);
    }
}