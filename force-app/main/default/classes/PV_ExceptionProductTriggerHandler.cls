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
public class PV_ExceptionProductTriggerHandler {
    
    //unlocks exception record approval to insert products into exception related list 
    public static void handleBeforeInsert(List<Exception_Product__c> exceptionProductList){
        try{
            for(Exception_Product__c exceptionProduct:exceptionProductList){
                if(Approval.isLocked(exceptionProduct.Exception__c)){
                    Approval.unlock(exceptionProduct.Exception__c);
                }
            }
        }
        catch (Exception ex) {
            ExceptionUtil.publishException('PV_ExceptionProductTriggerHandler.handleBeforeInsert', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            
        }
    }
    
    //locks exception record after product insert 
    public static void handleAfterInsert(List<Exception_Product__c> exceptionProductList){
       
            for(Exception_Product__c exceptionProduct:exceptionProductList){
                Approval.lock(exceptionProduct.Exception__c);
            }
        

    }
}