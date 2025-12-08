trigger PV_WorkOrderTrigger on WorkOrder (before insert, after insert,before update,after update) {
    If(trigger.isBefore && trigger.isInsert){
        PV_WorkOrderTriggerHandler.handleBeforeInsert( Trigger.New );
        PV_WorkOrderTriggerHandler.checkPreviosServiceAppt(Trigger.New );
        PV_WorkOrderTriggerHandler.calculateDaysSinceInstallation(Trigger.new);
    }
    If(trigger.isBefore && trigger.isUpdate){
        PV_WorkOrderTriggerHandler.handleBeforeInsert( Trigger.New );
        PV_WorkOrderTriggerHandler.checkPreviosServiceAppt(Trigger.New );
        PV_WorkOrderTriggerHandler.handleNotification(Trigger.New,Trigger.oldMap);
    }
    If(trigger.isAfter && trigger.isInsert){
        //PV_WorkOrderTriggerHandler.handleAfterInsert(Trigger.New);
        if(PV_FSL_Config__mdt.getInstance('Messaging_User_Creation').Is_Trigger_Enabled__c){
            PV_WorkOrderTriggerHandler.messagingUserCreation(Trigger.New);
        }
    }
     if (Trigger.isAfter && Trigger.isUpdate) {
        PV_WorkOrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}