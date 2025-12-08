public with sharing class FSL_CommTimelineMessageLog implements FSL_CommunicationTimelineItem.GetRecords {

    public static List<FSL_CommunicationTimelineItem> getRecords(Id recordId, List<Id> excludeIds, Integer queryLimit) {
        List<FSL_CommunicationTimelineItem> items = new List<FSL_CommunicationTimelineItem>();
        for (Message_Log__c messageLog : [
            SELECT
                Id,
                Sent_Date__c,
                CreatedBy.Name,
                Contact__r.Name,
                To__c,
                Body__c,
                Direction__c
            FROM Message_Log__c
            WHERE Service_Appointment__c = :recordId
                AND Id NOT IN :excludeIds
            ORDER BY Sent_Date__c DESC
            LIMIT :queryLimit
        ]) {
            items.add(new FSL_CommunicationTimelineItem(
                messageLog.Id,
                'SMS',
                messageLog.Sent_Date__c,
                messageLog.Direction__c == 'Inbound' ? messageLog.Contact__r.Name : messageLog.CreatedBy.Name,
                messageLog.To__c,
                '',
                messageLog.Body__c,
                messageLog.Direction__c == 'Inbound'
            ));
        }
        return items;
    }
}