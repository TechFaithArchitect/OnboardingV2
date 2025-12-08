public with sharing class FSL_CommTimelineTask implements FSL_CommunicationTimelineItem.GetRecords {

    public static List<FSL_CommunicationTimelineItem> getRecords(Id recordId, List<Id> excludeIds, Integer queryLimit) {
        List<FSL_CommunicationTimelineItem> items = new List<FSL_CommunicationTimelineItem>();
        for (Task task : [
            SELECT
                Id,
                CreatedDate,
                Type,
                CreatedBy.Name,
                Who.Name,
                Subject,
                Description
            FROM Task
            WHERE WhatId = :recordId
                AND Id NOT IN :excludeIds
            ORDER BY CreatedDate DESC
            LIMIT :queryLimit
        ]) {
            items.add(new FSL_CommunicationTimelineItem(
                task.Id,
                task.Type,
                task.CreatedDate,
                task.CreatedBy.Name,
                task.Who.Name,
                task.Subject,
                task.Description,
                false
            ));
        }
        return items;
    }
}