public without sharing class FSL_TypeformTriggerHandler {
    
    public static void assignWorkOrder(List<Typeform_Responses__c> responses) {
        
       	Set<Id> responseOrderIds = new Set<Id>();
       
        for(Typeform_Responses__c response : responses) {
            
            response.Work_Order__c = response.Work_Order_Id__c;
            
            responseOrderIds.add(response.Work_Order_Id__c);
        }
        
        List<WorkOrder> orders = [SELECT Id, Typeform_Survey_Completion__c FROM WorkOrder WHERE Id IN :responseOrderIds AND Typeform_Survey_Completion__c = false];
        
        if(!orders.isEmpty()) {
            
            for(WorkOrder order : orders) {
            	order.Typeform_Survey_Completion__c = true;
            }
                
            update orders;       
        }
    }
}