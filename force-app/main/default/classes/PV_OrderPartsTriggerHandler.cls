public without sharing class PV_OrderPartsTriggerHandler {
	
    public static void handleAfterDelete (Map<Id, Line_Item__c> oderLineItems ){
        Set<String> orderIds = new Set<String>();
        for(Line_Item__c lineItems : oderLineItems.values()){
            orderIds.add( lineItems.Order__c );
        }
        
       	Map<Id, List<Line_Item__c>> orderAndParts = new Map<Id, List<Line_Item__c>>();
        for(Line_Item__c parts : [SELECT Order__c, Id, Price__c, MSP_Price_Warning__c, MSP__c 
                                    FROM Line_Item__c 
                                   WHERE Order__c IN : orderIds] ){
            orderAndParts.put(parts.Order__c, new List<Line_Item__c>());
            if( orderAndParts.containsKey(parts.Order__c)){
               orderAndParts.get(parts.Order__c).add(parts);                        
            }                        
        }
        
        List<Order__c> order = new List<Order__c>();
        Map<String,Boolean> orderMSPUpdate = new  Map<String,Boolean>();
        for(Id orderId : orderAndParts.keySet()){
            for(Line_Item__c linePart : orderAndParts.get(orderId)){
                //order.add( new order__c( Id = linePart.Order__c,  MSP_Not_Meet__c  = false));	 
                 orderMSPUpdate.put(linePart.Order__c,false);
            	if(linePart.Price__c < linePart.MSP__c){
                  //  order.add( new order__c( Id = linePart.Order__c,  MSP_Not_Meet__c  = true));
                  orderMSPUpdate.put(linePart.Order__c,true);
                    Break;
                }
            }
        }
        for(String orderId:orderMSPUpdate.keyset()){
            order.add( new order__c( Id = orderId,  MSP_Not_Meet__c  = orderMSPUpdate.get(orderId)));
        }
        if(order.size() > 0){
           update order;
        }
    }
}