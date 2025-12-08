public with sharing class FSL_CommunicationsTimeline {
    public static final Integer QUERY_LIMIT = 15;

    @AuraEnabled
    public static List<FSL_CommunicationTimelineItem> getRecords(Id workOrderId, List<Id> excludeIds) {
        try {
            Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :workOrderId LIMIT 1].Id;

            List<List<FSL_CommunicationTimelineItem>> itemsList = new List<List<FSL_CommunicationTimelineItem>>();
            itemsList.add(FSL_CommTimelineMessageLog.getRecords(serviceAppointmentId, excludeIds, QUERY_LIMIT));
            itemsList.add(FSL_CommTimelineTask.getRecords(workOrderId, excludeIds, QUERY_LIMIT));
            itemsList.add(FSL_CommTimelineTask.getRecords(serviceAppointmentId, excludeIds, QUERY_LIMIT));
            itemsList.add(FSL_CommTimelineMessagingSession.getRecords(serviceAppointmentId, excludeIds, QUERY_LIMIT));

            Datetime mostRecentDate;
            for (List<FSL_CommunicationTimelineItem> items : itemsList) {
                if (items.size() == QUERY_LIMIT) {
                    Datetime newMostRecentDate = items[items.size() - 1].dateTimeValue;
                    mostRecentDate = (mostRecentDate == null || newMostRecentDate > mostRecentDate) ? newMostRecentDate : mostRecentDate;
                }
            }
            List<FSL_CommunicationTimelineItem> communicationTimelineItems = new List<FSL_CommunicationTimelineItem>();
            for (List<FSL_CommunicationTimelineItem> items : itemsList) {
                for (FSL_CommunicationTimelineItem item : items) {
                    if (mostRecentDate == null || item.dateTimeValue >= mostRecentDate) {
                        communicationTimelineItems.add(item);
                    }
                }
            }
            communicationTimelineItems.sort();
            return communicationTimelineItems;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}