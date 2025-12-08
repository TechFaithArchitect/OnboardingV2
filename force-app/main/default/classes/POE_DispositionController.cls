public without sharing class POE_DispositionController {
    @AuraEnabled(cacheable=false)
    public static List<Task> getTasks(String recordId) {
        List<Task> tasks = new List<Task>();
        tasks = [
            SELECT
                Id,
                WhatId,
                Priority,
                ActivityDate,
                Subject,
                Description,
                Follow_Up_Date_Time__c,
                Decision_Maker_Name__c,
                Decision_Maker_Phone__c
            FROM Task
            WHERE WhatId = :recordId AND Status = 'Open'
        ];
        System.debug(tasks);
        return tasks;
    }
}