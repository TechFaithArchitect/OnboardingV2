global with sharing class POE_CreateNewFollowUpTask {
    @AuraEnabled(cacheable=false)
    global static Boolean createNewTask(
        String opportunityId,
        String description,
        DateTime followUpDateTime,
        Date dueDate,
        String subject
    ) {

        Opportunity relatedOpp = [SELECT Id, POE_Decision_Maker_Name__c, POE_Decision_Maker_Phone__c FROM Opportunity WHERE Id =:opportunityId LIMIT 1];

        Task newTask = new Task(
            WhatId = opportunityId,
            Description = description,
            Follow_Up_Date_Time__c = followUpDateTime,
            Subject = subject,
            ReminderDateTime = followUpDateTime.addMinutes(-15),
            IsReminderSet = true,
            ActivityDate = dueDate,
            Priority = 'Normal',
            Status = 'Open'
        );

        if(!String.isBlank(relatedOpp.POE_Decision_Maker_Name__c)) {
            newTask.Decision_Maker_Name__c = relatedOpp.POE_Decision_Maker_Name__c;
        }
        if(!String.isBlank(relatedOpp.POE_Decision_Maker_Phone__c)) {
            newTask.Decision_Maker_Phone__c = relatedOpp.POE_Decision_Maker_Phone__c;
        }

        try {
            insert newTask;
        } catch (DmlException e) {
            System.debug(e);
            return false;
        }
        return true;
    }
}