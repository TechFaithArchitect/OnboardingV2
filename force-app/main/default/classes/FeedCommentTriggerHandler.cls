public without sharing class FeedCommentTriggerHandler extends TriggerHandler {
    private List<FeedComment> newList;
    private List<FeedComment> oldList;
    public static Boolean active = true;
    public FeedCommentTriggerHelper helper;

    public FeedCommentTriggerHandler() {
        this.newList = (List<FeedComment>) Trigger.new;
        this.oldList = (List<FeedComment>) Trigger.old;
        this.helper = new FeedCommentTriggerHelper();
    }

    public override void afterInsert() {
        helper.handleAfterInsert(newList);
    }
}