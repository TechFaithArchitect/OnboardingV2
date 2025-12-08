public without sharing class FSL_AgnosticCompletionFormController { 

    @AuraEnabled
    public static FSL_AppUtils.ResponseWrapper updateAgnosticDetails(List<Map<String, String>> productList, String workOrderId, String locationId) {

        try {

            Set<String> serialNumbers = new Set<String>();
            Set<String> productIds = new Set<String>();
            Map<String, ProductWrapper> productsBySerialNumber = new Map<String, ProductWrapper>();
            Map<String, ProductItem> itemsBySerialNumber = new Map<String, ProductItem>();
            Map<String, SerializedProduct> serializedProductsBySerialNumber = new Map<String, SerializedProduct>();
            List<ProductWrapper> itemsToConsume = new List<ProductWrapper>();
            List<ProductWrapper> itemsToCreate = new List<ProductWrapper>();
            List<ProductItem> prodItemsToCreate = new List<ProductItem>();
            List<ProductConsumed> consumedProducts = new List<ProductConsumed>();
            List<ProductConsumedState> consumedProductsState = new List<ProductConsumedState>();
            List<SerializedProduct> serializedProductsToInsert = new List<SerializedProduct>();

            for(Map<String, String> product : productList) {
            serialNumbers.add(product.get('SerialNumber'));
            productIds.add(product.get('ProductId'));
            }

            List<ProductItem> inventoryItems = [SELECT Id, Product2Id, LocationId 
                                                FROM ProductItem 
                                                WHERE LocationId = :locationId
                                                AND Product2Id IN :productIds
                                                AND Product2.IsSerialized = true];

            for(Map<String, String> product : productList) {
                for(ProductItem item : inventoryItems) {

                    if(product.get('ProductId') == item.Product2Id)
                        itemsBySerialNumber.put(product.get('SerialNumber'), item);
                }
            }

            List<SerializedProduct> serializedProductItems = [
                SELECT Id, ProductItemId, SerialNumber, ProductItem.LocationId, ProductItem.Product2Id
                FROM SerializedProduct 
                WHERE SerialNumber IN :serialNumbers 
                AND ProductItemId IN :inventoryItems
            ];

            for(SerializedProduct sp : serializedProductItems) {
                serializedProductsBySerialNumber.put(sp.SerialNumber, sp);
            }

            for (Map<String, String> product : productList) {

                if(serializedProductsBySerialNumber.containsKey(product.get('SerialNumber'))) {

                    productsBySerialNumber.put(product.get('SerialNumber'), new ProductWrapper(
                        serializedProductsBySerialNumber.get(product.get('SerialNumber')).ProductItem.Product2Id,
                        serializedProductsBySerialNumber.get(product.get('SerialNumber')).ProductItemId,
                        serializedProductsBySerialNumber.get(product.get('SerialNumber')).SerialNumber,
                        serializedProductsBySerialNumber.get(product.get('SerialNumber')).Id
                    ));

                }else {

                    String productItemId = itemsBySerialNumber.get(product.get('SerialNumber')) != null ? itemsBySerialNumber.get(product.get('SerialNumber')).Id : null;

                    productsBySerialNumber.put(product.get('SerialNumber'), new ProductWrapper(
                        product.get('ProductId'),
                        productItemId,
                        product.get('SerialNumber'),
                        null
                    ));
                }
            }

            for(ProductWrapper product : productsBySerialNumber.values()) {

                if(product.ProductItemId == null) {

                    ProductItem item = new ProductItem(

                        Product2Id = product.ProductId,
                        QuantityOnHand = 0,
                        LocationId = locationId
                    );

                    prodItemsToCreate.add(item);
                }
            }

            if(!prodItemsToCreate.isEmpty()) {

                insert prodItemsToCreate;

                for(ProductWrapper product : productsBySerialNumber.values()) {

                    for(ProductItem item : prodItemsToCreate) {

                        if(product.ProductItemId == null && item.Product2Id == product.ProductId) {
                            product.ProductItemId = item.Id;
                        }
                    }
                }
            }

            for(ProductWrapper product : productsBySerialNumber.values()) {

                if(product.SerializedProductId != null) {
                    itemsToConsume.add(product);

                }else {
                    itemsToCreate.add(product);
                }
            }

            if(!itemsToConsume.isEmpty()) {

                for(ProductWrapper product : itemsToConsume) {

                    ProductConsumed consumed = new ProductConsumed(
                        ProductItemId = product.ProductItemId,
                        WorkOrderId = workOrderId,
                        Serial_Number__c = product.SerialNumber,
                        QuantityConsumed = 0
                    );

                    consumedProducts.add(consumed);
                }
            }

            if(!itemsToCreate.isEmpty()) {

                for(ProductWrapper product : itemsToCreate) {

                    SerializedProduct sp = new SerializedProduct(
                        ProductItemId = product.ProductItemId,
                        Product2Id = product.ProductId,
                        SerialNumber = product.SerialNumber
                    );

                    serializedProductsToInsert.add(sp);
                }

                insert serializedProductsToInsert;

                for(ProductWrapper product : itemsToCreate) {
                    
                    for(SerializedProduct sp : serializedProductsToInsert) {
                        if(sp.SerialNumber == product.SerialNumber) {
                            productsBySerialNumber.get(product.SerialNumber).SerializedProductId = sp.Id;
                        }
                    }
                }

                for(SerializedProduct sp : serializedProductsToInsert) {

                    ProductConsumed consumed = new ProductConsumed(
                        ProductItemId = sp.ProductItemId,
                        WorkOrderId = workOrderId,
                        Serial_Number__c = sp.SerialNumber,
                        QuantityConsumed = 0
                    );

                    consumedProducts.add(consumed);
                }
            }

            if(!consumedProducts.isEmpty()) {

                insert consumedProducts;

                for(ProductConsumed consumed : consumedProducts) {

                    ProductConsumedState pcs = new ProductConsumedState(
                        ConsumedState = 'Consumed',
                        SerializedProductId = productsBySerialNumber.get(consumed.Serial_Number__c).SerializedProductId,
                        ProductConsumedId = consumed.Id
                    );

                    consumedProductsState.add(pcs);

                    consumed.IsConsumed = true;
                    consumed.QuantityConsumed = 1;
                    
                    //Loop DML
                    insert pcs; 
                    update consumed;
                    //To be resolved
                }
            }

            return new FSL_AppUtils.ResponseWrapper('SUCCESS', null, null);

        }catch(Exception e) {

            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }    

    public class ProductWrapper {
        public String ProductId;
        public String ProductItemId;
        public String SerialNumber;
        public String SerializedProductId;

        public ProductWrapper(String productId, String productItemId, String serialNumber, String serializedProductId) {
            this.ProductId = productId;
            this.ProductItemId = productItemId;
            this.SerialNumber = serialNumber;
            this.SerializedProductId = serializedProductId;
        }
    }
}