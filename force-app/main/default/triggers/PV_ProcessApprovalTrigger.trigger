trigger PV_ProcessApprovalTrigger on Process_Approval__c (before update, after update) {
    if(trigger.isBefore && trigger.isUpdate){
        PV_ProcessApprovalTriggerHandler.processApprovalCallToUpdateSR(Trigger.new, Trigger.oldMap);
        //PV_ProcessApprovalTriggerHandler.processApprovalCallToCreateLocation(Trigger.new, Trigger.oldMap);
    }
    if(trigger.isAfter && trigger.isUpdate){
        PV_ProcessApprovalTriggerHandler.processApprovalCallToCreateLocation(Trigger.new, Trigger.oldMap);
    }
}