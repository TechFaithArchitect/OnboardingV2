public without sharing class FSL_AddNewProductsController {

    @AuraEnabled(cacheable=false)
    public static FSL_AppUtils.ResponseWrapper getRequiredProducts(Date selectedDate) {
        
        try {
            ServiceResource resource = [SELECT Id, LocationId FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId() LIMIT 1];

            List<ServiceAppointment> resourceAppointments = [
                SELECT  Id, ParentRecordId, SchedStartTime, FSSK__FSK_Assigned_Service_Resource__c
                FROM ServiceAppointment 
                WHERE FSSK__FSK_Assigned_Service_Resource__c = :resource.Id
            ];

            Set<String> orderIds = new Set<String>();
            for (ServiceAppointment sa : resourceAppointments) {
                if (sa.SchedStartTime != null && sa.SchedStartTime.date() == selectedDate) {
                    orderIds.add(sa.ParentRecordId);
                }
            }

            List<WorkOrder> workOrders = [SELECT Id, WorkOrderNumber, Work_Type__c FROM WorkOrder WHERE Id IN :orderIds];
            List<ProductRequired> productsRequired = [
                SELECT Id, QuantityRequired, Product2Id, Product2.Name, Product2.ProductCode, ParentRecordId 
                FROM ProductRequired 
                WHERE ParentRecordId IN :orderIds
            ];

            List<ProductItem> productItems= [SELECT Id, Product2Id, QuantityOnHand, LocationId FROM ProductItem WHERE LocationId = :resource.LocationId];

            List<Map<String, Object>> productList = new List<Map<String, Object>>();
            for (ProductRequired result : productsRequired) {
                Map<String, Object> product = new Map<String, Object>();
                product.put('id', result.Id);
                product.put('productName', result.Product2.Name);
                product.put('productCode', result.Product2.ProductCode);

                result.QuantityRequired = result.QuantityRequired == null ? 0 : result.QuantityRequired;
                product.put('quantity', result.QuantityRequired);

                for(ProductItem item : productItems) {
                    if(item.Product2Id == result.Product2Id)
                        item.QuantityOnHand = item.QuantityOnHand == null ? 0 : item.QuantityOnHand;
                        product.put('quantityInVan', item.QuantityOnHand);
                }

                for(WorkOrder wo : workOrders) {
                    if(wo.Id == result.ParentRecordId)
                        product.put('workOrderNumber', wo.WorkOrderNumber);
                        product.put('workTypeName', wo.Work_Type__c);
                }

                productList.add(product);
            }

            return new FSL_AppUtils.ResponseWrapper('SUCCESS', productList, null);
        } catch (Exception e) {
            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }

    @AuraEnabled
    public static FSL_AppUtils.ResponseWrapper addProductToLocation(Map<String, Object> selectedProduct, String serialCode) {
        try {
            Id productId = (Id) selectedProduct.get('productid');
            Boolean IsSerialized = (Boolean) selectedProduct.get('isSerialized');
            Schema.Location resourceLocation = getLocation();

            if (String.isNotBlank(serialCode) && !IsSerialized) {
                return new FSL_AppUtils.ResponseWrapper('ERROR', null, 'That product isn\'t serialized.');
            }

            List<ProductItem> item = [
                SELECT  Id, Product2Id, LocationId, QuantityOnHand
                FROM    ProductItem
                WHERE   Product2Id = :productId
                AND     LocationId = :resourceLocation.Id
                LIMIT 1
            ];

            List<SerializedProduct> ownSerializedProduct = new List<SerializedProduct>();

            if (!item.isEmpty()) {
                ownSerializedProduct = [SELECT Id, SerialNumber, ProductItemId FROM SerializedProduct WHERE ProductItemId = :item[0].Id AND SerialNumber = :serialCode LIMIT 1];
            }

            SerializedProduct generalSerializedProduct = getSerializedProduct(serialCode, productId);
            SerializedProduct newSP = new SerializedProduct();
            newSP.Product2Id = productId;
            newSP.SerialNumber = serialCode;

            if (!item.isEmpty() && !ownSerializedProduct.isEmpty()) {
                throw new CustomException('This serialized product already exists in your assigned location.');
            } else if (!item.isEmpty() && ownSerializedProduct.isEmpty() && generalSerializedProduct == null) {
                if (!isSerialized) {
                    item[0].QuantityOnHand = item[0].QuantityOnHand + 1;
                    update item; 
                }
                if (String.isNotBlank(serialCode) && IsSerialized) {
                    newSP.ProductItemId = item[0].Id;
                    insert newSP;
                }
                return new FSL_AppUtils.ResponseWrapper('SUCCESS', null, null);
            }

            ProductItem newItem = new ProductItem();
            
            if (item.isEmpty()) {
                newItem.Product2Id = productId;
                newItem.LocationId = resourceLocation.Id;
                newItem.QuantityOnHand = isSerialized ? 0 : 1;
                insert newItem;
            }

            if (item.isEmpty() && String.isNotBlank(serialCode) && IsSerialized && generalSerializedProduct == null) {
                newSP.ProductItemId = newItem.Id;
                insert newSP;
            }

            ProductItem moveTo = new Productitem();
            if (!item.isEmpty()) {
                moveTo = item[0];
            } else {
                moveTo = newItem;
            }

            if (generalSerializedProduct != null) {
                moveSerializedProduct(generalSerializedProduct, moveTo);
            }
    
            return new FSL_AppUtils.ResponseWrapper('SUCCESS', null, null);
        } catch(Exception e) {
            String errorMessage = e.getMessage();
            
            if (errorMessage != null && errorMessage.contains('DUPLICATE_VALUE')) {
                errorMessage = 'Serial number ' + serialCode + ' is already in another technician\'s inventory. Please contact your inventory manager to resolve this.';
            }
            return new FSL_AppUtils.ResponseWrapper('ERROR', null, errorMessage);
        }
    }

    public static void moveSerializedProduct(SerializedProduct generalSerializedProduct, ProductItem productItem) {
        generalSerializedProduct.ProductItemId = productItem.Id;
        update generalSerializedProduct;
    }

    @AuraEnabled
    public static Schema.Location getLocation() {
        List<Schema.Location> locationList = [
            SELECT  Id, Name, Service_Resource__c, Service_Resource__r.RelatedRecordId 
            FROM    Location 
            WHERE   Service_Resource__r.RelatedRecordId = :UserInfo.getUserId() LIMIT 1
        ];

        if (locationList.isEmpty()) {
            throw new AuraHandledException('No location found for the current user.');
        } else {
            return locationList[0];
        }
    }

    @AuraEnabled
    public static SerializedProduct getSerializedProduct(String serialNumber, Id productId) {
        User user = getCurrentUser();
        Set<String> allowedVendors = getAllowedVendors(user);
        
        if (allowedVendors.isEmpty()) {
            return null;
        }

        List<SerializedProduct> serializedProducts = [
            SELECT  Id, Name, SerialNumber, Product2Id, Product2.Name, Product2.ProductCode, Product2.IsSerialized
            FROM    SerializedProduct
            WHERE   SerialNumber = :serialNumber
            AND     Product2.FSL_Vendor__c IN :allowedVendors
            AND     (
                ProductItemId = null 
                OR ProductItem.Location.LocationType = 'Warehouse'
                OR ProductItem.Location.Service_Resource__r.RelatedRecordId = :UserInfo.getUserId()
            )
        ];

        if (serializedProducts.isEmpty()) {
            return null;
        } else if (productId == null) {
            return serializedProducts[0];
        }

        SerializedProduct selectedSerializedProduct;
        for (SerializedProduct serializedProduct : serializedProducts) {
            if (serializedProduct.Product2Id == productId) {
                selectedSerializedProduct = serializedProduct;
                break;
            }
        }

        return selectedSerializedProduct;
    }

    public static User getCurrentUser() {
        return [
            SELECT  Contact.Account.Available_FSL_Vendors__c
            FROM    User
            WHERE   Id = :UserInfo.getUserId()
        ];
    }

    public static Set<String> getAllowedVendors(User user) {
        Set<String> allowedVendors = new Set<String>();

        if (String.isBlank(user.Contact.Account.Available_FSL_Vendors__c)) {
            return new Set<String>();
        }

        for (String vendor : user.Contact.Account.Available_FSL_Vendors__c.split(';')) {
            allowedVendors.add(vendor);
        }

        return allowedVendors;
    }
}