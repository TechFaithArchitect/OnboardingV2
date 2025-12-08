public without sharing class POE_OrderRelatedListsController {
    @AuraEnabled(cacheable=true)
    public static OrderRelatedDataWrapper getOrderRelatedData(Id orderId) {
        OrderRelatedDataWrapper wrapper = new OrderRelatedDataWrapper();
        
        try {
            wrapper.orderItems = [
                SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Quantity, UnitPrice
                FROM OrderItem
                WHERE OrderId = :orderId
            ];
            
            wrapper.orderConfigurations = [
                SELECT Id, Name, Fee_Type__c, Amount__c
                FROM POE_Order_Configurations__c
                WHERE Order__c = :orderId
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving data: ' + e.getMessage());
        }
        
        return wrapper;
    }
    
    public class OrderRelatedDataWrapper {
        @AuraEnabled public List<OrderItem> orderItems;
        @AuraEnabled public List<POE_Order_Configurations__c> orderConfigurations;
    }
}