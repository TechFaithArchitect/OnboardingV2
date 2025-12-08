public without sharing class FSL_DynamicCompletionForm_Controller {

    @AuraEnabled
    public static DataWrapper getConfiguration(String recordId, Boolean desktopUser) {
        try {
            DataWrapper data = new DataWrapper();
            data.success = false;

            Id locationId = getLocationId(recordId, desktopUser);
            WorkOrder wo = [SELECT Status, WorkTypeId, Vendor__c FROM WorkOrder WHERE Id = :recordId];
            
            List<Completion_Form_Template__c> templates = [
                SELECT  Section_Order__c, Location_Products_Consumed__c, (SELECT Name, Field_API_Name__c, Section_Name__c, Required__c, Read_Only__c, Field_Description__c FROM Completion_Form_Configurations__r ORDER BY Section_Name__c, Order_Within_Section__c)
                FROM    Completion_Form_Template__c
                WHERE   Work_Type__c != null AND Work_Type__c = :wo.WorkTypeId AND Active__c = true
            ];

            if (templates.isEmpty()) {
                templates = [
                    SELECT  Section_Order__c, Location_Products_Consumed__c, (SELECT Name, Field_API_Name__c, Section_Name__c, Required__c, Read_Only__c, Field_Description__c FROM Completion_Form_Configurations__r ORDER BY Section_Name__c, Order_Within_Section__c)
                    FROM    Completion_Form_Template__c
                    WHERE   Work_Type__c = null AND Vendor__c INCLUDES (:wo.Vendor__c) AND Active__c = true
                ];
            }

            String validationMessage = validations(locationId, wo.Status, templates);
            if (validationMessage != null) {
                data.message = validationMessage;
                return data;
            }

            mapSectionsAndFields(data, templates);

            data.success = true;
            data.locationId = locationId;
            data.locationOn = templates[0].Location_Products_Consumed__c;
            data.vendor = wo.Vendor__c;
            data.locations = getLocationPicklist();
            return data;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Id getLocationId(String recordId, Boolean desktopUser) {
        Id locationId;
        if (!desktopUser) {
            locationId = [SELECT LocationId FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId() AND ResourceType = 'T'].LocationId;
        } else {
            List<String> availableStatuses = PV_FSL_Config__mdt.getInstance('Allow_transition').Value__c.split(',');
            List<ServiceAppointment> serviceAppointment = [SELECT Id, (SELECT ServiceResource.LocationId FROM ServiceResources WHERE ServiceResource.ResourceType = 'T' LIMIT 1) FROM ServiceAppointment WHERE FSSK__FSK_Work_Order__c = :recordId AND Status IN :availableStatuses LIMIT 1];
            if (!serviceAppointment.isEmpty() && !serviceAppointment[0].ServiceResources.isEmpty()) {
                locationId = serviceAppointment[0].ServiceResources[0].ServiceResource.LocationId;
            }            
        }
        return locationId;
    }

    private static String validations(Id locationId, String status, List<Completion_Form_Template__c> templates) {

        // Status check
        List<String> allowedTransition = new List<String>();
        for (PV_FSL_Config__mdt config : [SELECT MasterLabel, Value__c FROM PV_FSL_Config__mdt WHERE Type__c = 'allowdedTransition']) {
            allowedTransition.addAll(config.Value__c.split(','));
        }
        if (!allowedTransition.contains(status)) {
            return 'Completion form is only available in Onsite or Pending Complete status.';
        }

        // More than one template available
        if (templates.size() > 1) return 'Duplicate Completion Forms found. Check Completion Form Templates.';

        // Available Completion Form check
        if (templates.isEmpty()) return 'No active Completion Form Template found for this WorkType and Vendor.';

        // Location Check
        if (locationId == null) return 'Inventory location is not available, please contact your Manager.';

        return null;
    }

    private static void mapSectionsAndFields(DataWrapper data, List<Completion_Form_Template__c> templates) {

        Completion_Form_Template__c template = templates[0];

        if (template.Section_Order__c != null) {

            Map<String, Section> sectionsByName = new Map<String, Section>();
            for (String sectionName : template.Section_Order__c.replace('"', '').split(';')) {
                Section section  = new Section();
                section.name = sectionName;
                section.fields = new List<Field>();
                sectionsByName.put(sectionName, section);
            }
            
            SObjectType objType = ((SObject)(Type.forName('Schema.WorkOrder').newInstance())).getSObjectType();
            DescribeSObjectResult objDesc = objType.getDescribe();

            for (Completion_Form_Configuration__c config : template.Completion_Form_Configurations__r) {  
                Field field = new Field();
                field.label = config.Name;
                field.apiName = config.Field_API_Name__c;
                field.type = formatType(objDesc, field.apiName);
                field.isCheckbox = field.type == 'checkbox';
                field.required = config.Required__c;
                field.readOnly = config.Read_Only__c;
                field.description = config.Field_Description__c;
                sectionsByName.get(config.Section_Name__c).fields.add(field);
            }
            data.sections = new List<Section>(sectionsByName.values());
        }
    }

    private static List<String> getLocationPicklist() {
        List<String> values = new List<String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get('ProductConsumed');
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get('Location__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry pickListVal : ple) {
            values.add(pickListVal.getValue());
        }
        return values;
    }

    private static String formatType(DescribeSObjectResult objDesc, String fieldApiName) {
        String schemaFieldType = objDesc.fields.getMap().get(fieldApiName).getDescribe().getType().name();
        switch on schemaFieldType {
            when 'STRING', 'TEXTAREA' { return 'text'; }
            when 'INTEGER' { return 'number'; }
            when 'BOOLEAN' { return 'checkbox'; }
        }
        return null;
    }

    @AuraEnabled
    public static FSL_AppUtils.ResponseWrapper submitProducts(WorkOrder workOrder, String productsJson, String locationId) {
        String missingProductsJson = PV_InventoryController.filterProductsNotInTechnicianVan(productsJson, locationId);
        String nonSerializedProductsJson = filterProductsBySerialization(productsJson, false);
        String serializedProductsJson = filterProductsBySerialization(productsJson, true);

        try {
            PV_InventoryController.addInventoryProducts(missingProductsJson, locationId);
            consumeNonSerializedProducts(workOrder, nonSerializedProductsJson, locationId);
            consumeSerializedProducts(workOrder, serializedProductsJson, locationId);
            return new FSL_AppUtils.ResponseWrapper('SUCCESS', null, null);
        } catch(Exception e) {
            ExceptionUtil.publishException('addInventoryProducts', e.getLineNumber(), e.getMessage(), e.getStackTraceString());
            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }

    private static String filterProductsBySerialization(String productsJson, Boolean isSerialized) {
        List<Object> rawList = (List<Object>) JSON.deserializeUntyped(productsJson);
        List<Map<String, Object>> filtered = new List<Map<String, Object>>();
        
        for (Object obj : rawList) {
            Map<String, Object> product = (Map<String, Object>) obj;
            Boolean serializedFlag = product.containsKey('IsSerialized') ? (Boolean) product.get('IsSerialized') : false;
            
            if (serializedFlag == isSerialized) {
                filtered.add(product);
            }
        }
        return JSON.serialize(filtered);
    }

    private static void consumeNonSerializedProducts(WorkOrder wo, String productsJson, String locationId) {
        List<ProductWrapper> productWrapperList = (List<ProductWrapper>) JSON.deserialize(productsJson, List<ProductWrapper>.class);
        Map<Id, ProductItem> productItemMapByProductId = new Map<Id, ProductItem>();
        List<ProductConsumed> productConsumedList = new List<ProductConsumed>();
        
        for (ProductItem productItem : [SELECT Id, Product2Id FROM ProductItem WHERE LocationId = :locationId]) {
            productItemMapByProductId.put(productItem.Product2Id, productItem);
        }
        
        for (ProductWrapper productWrapper : productWrapperList) {
            if (!String.isBlank(productWrapper.ProductId) && !String.isBlank(productWrapper.Quantity) && productWrapper.Quantity != null) {
                ProductItem matchedProductItem = productItemMapByProductId.get(productWrapper.ProductId);
                ProductConsumed productConsumed = new ProductConsumed();
                productConsumed.WorkOrderId = wo.Id;
                productConsumed.ProductItemId = matchedProductItem.Id;
                productConsumed.QuantityConsumed = Decimal.valueOf(productWrapper.Quantity);
                productConsumedList.add(productConsumed);
            }
        }
        
        if (!productConsumedList.isEmpty()) {
            insert productConsumedList;
        }
    }

    private static void consumeSerializedProducts(WorkOrder workOrder, String productsJson, String locationId) {
        List<ProductWrapper> productItemList = (List<ProductWrapper>) System.JSON.deserialize(productsJson, List<ProductWrapper>.class);
        List<SerializedProduct> serializedProduct = new List<SerializedProduct>();
        Set<String> serialNumber = new set <String>();
        
        List<SerializedProduct> serializedProductListForExistingProductItem = new List<SerializedProduct>();
        Map<Id,ProductItem> existingProductItemMap = new Map<Id,ProductItem>();
        Map<Id,ProductItem> nonSerializedProductItemCreateMap = new Map<Id,ProductItem>();
        Map<Id,ProductItem> newSerializedProductItemMap = new Map<Id,ProductItem>();
        Map<Id,List<SerializedProduct>> newSerializedProductMap = new Map<Id,List<SerializedProduct>>();
        
        for (ProductWrapper productWrapper: productItemList) {
            serialNumber.add(productWrapper.SerialNumber);
        }
        
        Map<Id, Map<String, SerializedProduct>> existingSerializesProductMap = exisitingSerializedProductCheck(serialNumber);
        
        for (Integer i = productItemList.size() - 1; i >= 0; i--) {
            ProductWrapper product = productItemList[i];
            
            // Check if the product ID exists in the existingSerializesProductMap
            if (existingSerializesProductMap.containsKey(product.ProductId)) {
                Map<String, SerializedProduct> innerMap = existingSerializesProductMap.get(product.ProductId);
                if (innerMap.containsKey(product.SerialNumber)) {
                    SerializedProduct serializedProducts = innerMap.get(product.SerialNumber);
                    serializedProduct.add(serializedProducts);
                    productItemList.remove(i);
                }
            }
        }
        
        for (ProductItem prdItem : [SELECT Id,Product2Id,QuantityOnHand FROM ProductItem WHERE LocationId = :locationId]) {
            existingProductItemMap.put(prdItem.Product2Id,prdItem);
        }
        
        for (ProductWrapper prdWrapper: productItemList) {
            ProductItem prdItem = new ProductItem();
            ProductItem srPrdItem = new ProductItem();
            SerializedProduct serializedProductWithPrdItem = new SerializedProduct();
            
            if (prdWrapper.IsSerialized) {
                // Serialized Product already exist in location or not
                if (existingProductItemMap.containsKey(prdWrapper.ProductId)){
                    serializedProductWithPrdItem.SerialNumber = prdWrapper.SerialNumber;
                    serializedProductWithPrdItem.Product2Id = prdWrapper.ProductId;
                    serializedProductWithPrdItem.ProductItemId = existingProductItemMap.get(prdWrapper.ProductId).Id;
                    serializedProductWithPrdItem.Status = 'Available';
                    serializedProductListForExistingProductItem.add(serializedProductWithPrdItem);
                } else {
                    if (!newSerializedProductItemMap.containsKey(prdWrapper.ProductId)) {
                        srPrdItem.LocationId = locationId;  
                        srPrdItem.Product2Id = prdWrapper.ProductId;
                        srPrdItem.QuantityOnHand = 0.00;
                        newSerializedProductItemMap.put(prdWrapper.ProductId,srPrdItem);
                    }
                    
                    serializedProductWithPrdItem.SerialNumber = prdWrapper.SerialNumber;
                    serializedProductWithPrdItem.Product2Id = prdWrapper.ProductId;
                    serializedProductWithPrdItem.ProductItemId = null;
                    serializedProductWithPrdItem.Status = 'Available';
                    
                    if (newSerializedProductMap.containsKey(prdWrapper.ProductId)){
                        newSerializedProductMap.get(prdWrapper.ProductId).add(serializedProductWithPrdItem);
                    } else {
                        newSerializedProductMap.put(prdWrapper.ProductId, new List<SerializedProduct>{serializedProductWithPrdItem});
                    }                    
                }
            }
        }
        
        if (!serializedProductListForExistingProductItem.isEmpty()) {
            insert serializedProductListForExistingProductItem;
            serializedProduct.addAll(serializedProductListForExistingProductItem);
        }
        
        if (!newSerializedProductItemMap.values().isEmpty()) {
            insert newSerializedProductItemMap.values();
            
            List<SerializedProduct> newSerializedProductList = new list<SerializedProduct>();
            for (ProductItem newPrdItem : newSerializedProductItemMap.values()) {
                for (SerializedProduct srp : newSerializedProductMap.get(newPrdItem.Product2Id)) {
                    srp.ProductItemId = newPrdItem.Id;
                    newSerializedProductList.add(srp);
                }                
            }
            if (!newSerializedProductList.isEmpty()) {
                insert newSerializedProductList;
                serializedProduct.addAll(newSerializedProductList) ;
            }
        }
        
        updateTmoDetails(workOrder, productsJson, locationId, serializedProduct);
    }

    // Method to check SerializedProduct is present in inventory or not
    public static  Map<Id, Map<String, SerializedProduct>> exisitingSerializedProductCheck(Set<String> serialNumber) {
        Map<Id, Map<String, SerializedProduct>> existingSerializedProductMap = new Map<Id, Map<String, SerializedProduct>>();
        
        for (SerializedProduct srPrdt : [SELECT Id, Name, Product2Id, ProductItemId, SerialNumber, Status FROM SerializedProduct WHERE Status = 'Available' AND SerialNumber IN :serialNumber]) {
            if (existingSerializedProductMap.containsKey(srPrdt.Product2Id)) {
                existingSerializedProductMap.get(srPrdt.Product2Id).put(srPrdt.SerialNumber, srPrdt);
            } else {
                existingSerializedProductMap.put(srPrdt.Product2Id, new Map<String, SerializedProduct>{srPrdt.SerialNumber => srPrdt});
            }
        }
        return existingSerializedProductMap;
    }

    public static Boolean updateTmoDetails(WorkOrder workOrder, String productsJson, String locationId, List<SerializedProduct> serailizedProducts) {
        try {
            List<ProductWrapper>productList = (List<ProductWrapper>) System.JSON.deserialize(productsJson, List<ProductWrapper>.class);
            List<ProductItem> productItemToBeAdded = new List<ProductItem>();
            Set<Id> productConsumedId = new Set<Id>();

            List<Additional_Product__c> additionalProdList = [
                SELECT  Work_Order__c, Serial_Number__c, Product__c, Location__c
                FROM    Additional_Product__c 
                WHERE   Work_Order__c = :workOrder.Id
            ];
            
            Map<Id,Additional_Product__c> addProdMap = new Map<Id,Additional_Product__c>();
            List<SObject> tmoWorkCompletionList = new List<SObject>();
            List<ProductConsumedState> pcsInsertList = new List<ProductConsumedState>();

            Map<Id,List<SerializedProduct>> existingSeriallizedProductMap = new Map<Id,List<SerializedProduct>>();
            List<SerializedProduct> updatedSerailizedProducts= new  List<SerializedProduct>();
            Map<String,List<SerializedProduct>> serailizedProductsMap = new Map<String,List<SerializedProduct>>();
            Map<String,Id> serailizedProductItemMap = new map<String,Id>();
            
            for (Additional_Product__c addmap : additionalProdList) {
                addProdMap.put(addmap.Product__c , addmap);
            }
            
            for (SerializedProduct srProductMap : serailizedProducts) {
                if (!serailizedProductsMap.containsKey(srProductMap.SerialNumber)) {
                    serailizedProductsMap.put(srProductMap.SerialNumber, new List<SerializedProduct>{srProductMap});
                } else {
                    serailizedProductsMap.get(srProductMap.SerialNumber).add(srProductMap);
                }
            }
            
            for (List<SerializedProduct> SerializedProductList : serailizedProductsMap.values()) {
                for (SerializedProduct product : SerializedProductList) {
                    updatedSerailizedProducts.add(product);
                }
            }
            
            for (ProductWrapper productCheck : productList) {
                for (SerializedProduct serialProductList : updatedSerailizedProducts ) {
                    if (serialProductList.SerialNumber == productCheck.SerialNumber && serialProductList.Product2Id == productCheck.ProductId) {
                        ProductConsumed pc = new ProductConsumed();
                        pc.ProductItemId =  serialProductList.ProductItemId;
                        pc.QuantityConsumed = 0;
                        pc.Serial_Number__c = productCheck.SerialNumber;
                        pc.Location__c = productCheck.Location;
                        pc.WorkOrderId = workOrder.Id;
                        pc.Other__c = productCheck.otherTextBox;
                        tmoWorkCompletionList.add(pc);
                        break;
                    }
                }
            }

            tmoWorkCompletionList.add(workOrder);

            // Update or insert  all record
            upsert tmoWorkCompletionList;
            Map<Id,ProductConsumed> productConsumedMap = new Map<Id,ProductConsumed>([
                SELECT Id,Serial_Number__c ,ProductItemId,WorkOrderId,Product2Id 
                FROM ProductConsumed 
                WHERE WorkOrderId = :workOrder.Id
            ]);
            
            for (ProductConsumed pc : productConsumedMap.values()) {
                for (SerializedProduct SRproduct : updatedSerailizedProducts) {
                    if (SRproduct.SerialNumber == pc.Serial_Number__c && pc.ProductItemId == SRproduct.ProductItemId) {
                        ProductConsumedState pcs = new ProductConsumedState();
                        pcs.ConsumedState = 'Consumed';
                        pcs.SerializedProductId = SRproduct.Id;
                        pcs.ProductConsumedId = pc.Id;
                        productConsumedId.add(pc.Id);
                        pcsInsertList.add(pcs);
                    }
                }
            }

            insert pcsInsertList;
            updateConsumedProduct(productConsumedId);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Error : ' + e.getMessage());
        }
    }

    @future
    public static void updateConsumedProduct(Set<Id> productConsumedId) {
        List<ProductConsumed> pcUpdateList = new List<ProductConsumed>();
        List<ProductConsumedState> pcsInsertList = new List<ProductConsumedState> ();
        
        Map<Id,ProductConsumed> productConsumedMap = new Map<Id,ProductConsumed>([
            SELECT  Id, Serial_Number__c, ProductItemId, WorkOrderId, Product2Id 
            FROM ProductConsumed 
            WHERE Id IN :productConsumedId
        ]);
        
        for (ProductConsumed pc : productConsumedMap.values()) {
            ProductConsumed pcUpdate = new ProductConsumed();
            pcUpdate.Id = pc.Id;
            pcUpdate.IsConsumed = true;
            pcUpdate.QuantityConsumed = 1.00;
            pcUpdateList.add(pcUpdate);
            update pcUpdate;
        }
    }

    public class ProductWrapper {
        @AuraEnabled public String ProductId;
        @AuraEnabled public String ProductName;
        @AuraEnabled public Boolean IsSerialized;
        @AuraEnabled public String SerialNumber;
        @AuraEnabled public String Location;
        @AuraEnabled public String LocationId;
        @AuraEnabled public String otherTextBox;
        @AuraEnabled public String Quantity;
    }

    public class DataWrapper {
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public String message {get; set;}

        @AuraEnabled public List<Section> sections {get;set;}
        @AuraEnabled public String vendor {get;set;}
        @AuraEnabled public String locationId {get;set;}
        @AuraEnabled public Boolean locationOn {get;set;}
        @AuraEnabled public List<String> locations {get;set;}
    }

    public class Section {
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public List<Field> fields {get;set;}
    }

    public class Field {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String apiName {get;set;}
        @AuraEnabled public String type {get;set;}
        @AuraEnabled public Boolean isCheckbox {get;set;}
        @AuraEnabled public Boolean required {get;set;}
        @AuraEnabled public Boolean readOnly {get;set;}
        @AuraEnabled public String description {get;set;}
    }
}