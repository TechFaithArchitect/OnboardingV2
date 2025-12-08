trigger FSL_ErrorAlertTrigger on FSL_Error_Alert__e (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        FSL_ErrorAlertTriggerHelper.afterInsert(Trigger.new);
    }
}