/**
* @description       : 
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 12-06-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
trigger PV_ExceptionTrigger on Exception__c (before insert , before update , after insert){

    if(trigger.isBefore && trigger.isInsert) {
       PV_ExceptionTriggerHandler.exceptionAfterInsert(Trigger.New);
    }
 
}