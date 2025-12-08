public with sharing class FSL_CommTimelineMessagingSession implements FSL_CommunicationTimelineItem.GetRecords {

    public static List<FSL_CommunicationTimelineItem> getRecords(Id recordId, List<Id> excludeIds, Integer queryLimit) {
        List<FSL_CommunicationTimelineItem> items = new List<FSL_CommunicationTimelineItem>();
        Map<Id, MessagingSession> messagingSessionById = new Map<Id, MessagingSession>([
            SELECT
                Id,
                StartTime,
                ChannelKey,
                MessagingEndUser.Name
            FROM MessagingSession
            WHERE Service_Appointment__c = :recordId
                AND Id NOT IN :excludeIds
            ORDER BY StartTime DESC
            LIMIT :queryLimit
        ]);
        for (ConversationEntry conversationEntry : [
            SELECT
                Id,
                ConversationId,
                Message,
                Actor.Name
            FROM ConversationEntry
            WHERE ConversationId IN :messagingSessionById.keySet()
        ]) {
            MessagingSession messagingSession = messagingSessionById.get(conversationEntry.ConversationId);
            items.add(new FSL_CommunicationTimelineItem(
                messagingSession.Id,
                'SMS',
                messagingSession.StartTime,
                messagingSession.ChannelKey,
                messagingSession.MessagingEndUser.Name,
                '',
                conversationEntry.Message,
                conversationEntry.Actor.Name != NULL
            ));
        }
        return items;
    }
}