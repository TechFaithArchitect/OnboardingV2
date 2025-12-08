trigger PV_OrderPartsTrigger on Line_Item__c ( after delete ) {
    PV_OrderPartsTriggerHandler.handleAfterDelete( Trigger.oldMap );
}