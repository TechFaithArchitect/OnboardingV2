public with sharing class FSL_NonSerializedCompController {
    
    @AuraEnabled(cacheable=false)
    public static Product2 getProductDetails(Id productId) {
        return [
            SELECT  Id, Name, QuantityUnitOfMeasure, IsSerialized
            FROM    Product2
            WHERE   Id = :productId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=false)
    public static void consumeNonSerializedProducts(Map<String, Object> formData, String productItemJson, String locationId) {
        List<ProductItemWrapper> productWrapperList = (List<ProductItemWrapper>) JSON.deserialize(productItemJson, List<ProductItemWrapper>.class);
        Map<Id, ProductItem> productItemMapByProductId = new Map<Id, ProductItem>();
        List<ProductConsumed> productConsumedList = new List<ProductConsumed>();
        
        for (ProductItem productItem : [
            SELECT  Id, Product2Id
            FROM    ProductItem
            WHERE   LocationId = :locationId
        ]) {
            productItemMapByProductId.put(productItem.Product2Id, productItem);
        }
        
        for (ProductItemWrapper productWrapper : productWrapperList) {
            if (!String.isBlank(productWrapper.productId) && !String.isBlank(productWrapper.quantity)) {
                ProductItem matchedProductItem = productItemMapByProductId.get(productWrapper.productId);
                
                ProductConsumed productConsumed = new ProductConsumed();
                productConsumed.WorkOrderId = (Id)formData.get('Id');
                productConsumed.ProductItemId = matchedProductItem.Id;
                productConsumed.QuantityConsumed = Decimal.valueOf(productWrapper.quantity);
                productConsumedList.add(productConsumed);
            }
        }
        
        if (!productConsumedList.isEmpty()) {
            insert productConsumedList;
        }
    }

    @AuraEnabled
    public static void updateWorkOrder(Map<String, Object> formData) {
        WorkOrder workOrder = new WorkOrder();
        workOrder.Id = (Id) formData.get('Id');
        workOrder.Signal_Level__c = (String) formData.get('signalLevel');
        workOrder.Beginning_Tick_Mark__c = (String) formData.get('beginningTickMark');
        workOrder.End_Tick_Mark__c = (String) formData.get('endTickMark');
        workOrder.Cable_and_Equipment_Check__c = (Boolean) formData.get('cableValidation');
        workOrder.Cable_Conduit_Aesthetic_Check__c = (Boolean) formData.get('conduitValidation');
        workOrder.Connector_and_Equipment_Attachment_Check__c = (Boolean) formData.get('connectorValidation');
        update workOrder;
    }

    public class ProductItemWrapper {
        public String productId;
        public String quantity;
    }
}