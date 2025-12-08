/**
* @description       : Handler Class for PV_ServiceTerritoryTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver                 :  1.0  
* Date               : 03-08-2023
**/
trigger PV_ExceptionProductTrigger on Exception_Product__c (before insert,after insert) {
    
    if(Trigger.isInsert && Trigger.isBefore){
        PV_ExceptionProductTriggerHandler.handleBeforeInsert(trigger.New);
    }
    if(trigger.isInsert && trigger.isAfter){
        PV_ExceptionProductTriggerHandler.handleAfterInsert(trigger.New);
    }
    
}