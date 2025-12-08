public with sharing class FSL_CommunicationTimelineItem implements Comparable {
    @AuraEnabled public Id id;
    @AuraEnabled public String type;
    @AuraEnabled public Datetime dateTimeValue;
    @AuraEnabled public String dateTimeFormatted;
    @AuraEnabled public String fromValue;
    @AuraEnabled public String toValue;
    @AuraEnabled public String subject;
    @AuraEnabled public String body;
    @AuraEnabled public Boolean isInbound;

    public FSL_CommunicationTimelineItem(Id id, String type, Datetime dateTimeValue, String fromValue, String toValue, String subject, String body, Boolean isInbound) {
        this.id = id;
        this.dateTimeValue = dateTimeValue;
        this.dateTimeFormatted = dateTimeValue.format('M/d/yyyy - h:mm a', UserInfo.getTimeZone().getId());
        this.type = type;
        this.fromValue = fromValue;
        this.toValue = toValue;
        this.subject = subject;
        this.body = body;
        this.isInbound = isInbound;
    }

    public Integer compareTo(Object compareTo) {
        FSL_CommunicationTimelineItem compareToItem = (FSL_CommunicationTimelineItem) compareTo;
        return this.dateTimeValue.getTime() == compareToItem.dateTimeValue.getTime() ? 0 : (this.dateTimeValue.getTime() > compareToItem.dateTimeValue.getTime() ? -1 : 1);
    }

    public interface GetRecords {
        List<FSL_CommunicationTimelineItem> getRecords(Id recordId, List<Id> excludeIds, Integer queryLimit);
    }
}