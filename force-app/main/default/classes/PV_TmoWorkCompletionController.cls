public with sharing class PV_TmoWorkCompletionController {
    @AuraEnabled
    public static Boolean updateTmoDetails(Map<String, Object> formData,string productsJson,String locationId,List<SerializedProduct> serailizedProducts) {
        try {
            List<ProductWrapper>productList = (List<ProductWrapper>) System.JSON.deserialize(productsJson, List<ProductWrapper>.class);
            List<ProductItem> productItemToBeAdded = new List<ProductItem>();
            Set<Id> productConsumedId = new set<Id>();
            List<Additional_Product__c> additionalProdList = [SELECT Work_Order__c,Serial_Number__c,Product__c,Location__c 
                                                              FROM Additional_Product__c WHERE Work_Order__c =: (Id)formData.get('Id')];
            map<Id,Additional_Product__c> addProdMap = new  map<Id,Additional_Product__c>();
            List<Sobject> tmoWorkCompletionList = new  List<Sobject>();
            List<ProductConsumedState> pcsInsertList = new List<ProductConsumedState> ();
            // List<SerializedProduct> serailizedProducts = addInventoryProducts(productsJson,locationId);
            Map<Id,List<SerializedProduct>> existingSeriallizedProductMap = new Map<Id,List<SerializedProduct>>();
            List<SerializedProduct> updatedSerailizedProducts= new  List<SerializedProduct>();
            map<String,List<SerializedProduct>> serailizedProductsMap = new map<String,List<SerializedProduct>>();
            map<String,Id> serailizedProductItemMap = new map<String,Id>();
            
            for(Additional_Product__c addmap : additionalProdList){
                addProdMap.put(addmap.Product__c , addmap);
            }
            
            for(SerializedProduct srProductMap : serailizedProducts){
                if(!serailizedProductsMap.containsKey(srProductMap.SerialNumber)){
                    serailizedProductsMap.put(srProductMap.SerialNumber, new List<SerializedProduct>{srProductMap});
                }else{
                    serailizedProductsMap.get(srProductMap.SerialNumber).add(srProductMap);
                }
            }
            
            for (List<SerializedProduct> SerializedProductList : serailizedProductsMap.values()) {
                for (SerializedProduct product : SerializedProductList) {
                    updatedSerailizedProducts.add(product);
                }
            }
            
            for(ProductWrapper productCheck : productList){
                for(SerializedProduct serialProductList : updatedSerailizedProducts ){
                    if (productCheck.additionalProduct == false){
                        if(serialProductList.SerialNumber == productCheck.SerialNumber && serialProductList.Product2Id == productCheck.ProductId){
                            ProductConsumed pc = new ProductConsumed();
                            pc.ProductItemId =  serialProductList.ProductItemId;
                            pc.QuantityConsumed = 0;
                            pc.Serial_Number__c = productCheck.SerialNumber;
                            pc.Location__c = productCheck.Location;
                            pc.WorkOrderId = (Id)formData.get('Id');
                            pc.Other__c = productCheck.otherTextBox;
                            tmoWorkCompletionList.add(pc);
                            break;
                        }
                    }
                }
            }
            
            for(ProductWrapper productCheckAdd : productList){
                Additional_Product__c adEquipment =  new Additional_Product__c();
                if(productCheckAdd.additionalProduct == true){
                    if(!addProdMap.isEmpty() && addProdMap.containsKey(productCheckAdd.ProductId)){
                        adEquipment.Id = addProdMap.get(productCheckAdd.ProductId).Id;
                    }
                    adEquipment.Product__c = productCheckAdd.ProductId;
                    adEquipment.Work_Order__c = (Id)formData.get('Id');
                    adEquipment.Serial_Number__c = productCheckAdd.SerialNumber;
                    adEquipment.Location__c = productCheckAdd.Location;
                    adEquipment.Other__c = productCheckAdd.otherTextBox;
                    tmoWorkCompletionList.add(adEquipment);
                }
            }

            WorkOrder workOrderRecord = workOrderGenerator(formData);
            tmoWorkCompletionList.add(workOrderRecord);
            // Update or insert  all record
            upsert tmoWorkCompletionList;
            Map<Id,ProductConsumed> productConsumedMap = new Map<Id,ProductConsumed>([SELECT Id,Serial_Number__c ,ProductItemId,WorkOrderId,Product2Id 
                                                                                      FROM ProductConsumed WHERE WorkOrderId=:(Id)formData.get('Id') ]);
            
            for (ProductConsumed pc : productConsumedMap.values()) {
                for(SerializedProduct SRproduct : updatedSerailizedProducts){
                    if(SRproduct.SerialNumber == pc.Serial_Number__c && pc.ProductItemId == SRproduct.ProductItemId){
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
    public static void updateConsumedProduct(Set<Id> productConsumedId){
        List<ProductConsumed> pcUpdateList = new List<ProductConsumed>();
        List<ProductConsumedState> pcsInsertList = new List<ProductConsumedState> ();
        
        Map<Id,ProductConsumed> productConsumedMap = new Map<Id,ProductConsumed>([SELECT Id,Serial_Number__c ,ProductItemId,WorkOrderId,Product2Id 
                                                                                  FROM ProductConsumed WHERE Id IN:productConsumedId ]);
        
        for (ProductConsumed pc : productConsumedMap.values()){
            ProductConsumed pcUpdate = new ProductConsumed();
            pcUpdate.Id = pc.Id;
            pcUpdate.IsConsumed = true;
            pcUpdate.QuantityConsumed = 1.00;
            pcUpdateList.add(pcUpdate);
            update pcUpdate;
        }
        //  update pcUpdateList;
    }
    
    @AuraEnabled
    public static String locationCheck(String userId, Id workOrderId, Boolean desktopUser) {
        Id locationId;

        if (!desktopUser) {
            List<ServiceResource> srLocationCheck = [SELECT Id, LocationId FROM ServiceResource WHERE RelatedRecordId = :userId AND ResourceType = 'T'];
            return srLocationCheck[0].LocationId;
        }

        List<String> availableStatuses = PV_FSL_Config__mdt.getInstance('Allow_transition').Value__c.split(',');
        List<ServiceAppointment> serviceAppointment = [
            SELECT  Id, (SELECT ServiceResource.LocationId FROM ServiceResources WHERE ServiceResource.ResourceType = 'T' LIMIT 1)
            FROM    ServiceAppointment
            WHERE   FSSK__FSK_Work_Order__c = :workOrderId
            AND     Status IN :availableStatuses
            LIMIT 1
        ];

        if (serviceAppointment.size() > 0 && serviceAppointment[0].ServiceResources.size() > 0) {
            locationId = serviceAppointment[0].ServiceResources[0].ServiceResource.LocationId;
        }

        return locationId;
    }

    @AuraEnabled
    public static boolean statusCheck(String woId) {
        String woStatus = [SELECT Id, Status FROM WorkOrder WHERE Id = :woId].Status;
        
        List<String> allowedTransition = new List<String>();
        
        for (PV_FSL_Config__mdt config : [SELECT MasterLabel, Value__c FROM PV_FSL_Config__mdt WHERE Type__c = 'allowdedTransition']) {
            allowedTransition.addAll(config.Value__c.split(','));
        }

        if (allowedTransition.contains(woStatus)) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled
    public static String getWorkTypeName(Id workOrderId) {
        List<WorkOrder> workOrder = [SELECT Id, WorkType.Name FROM WorkOrder WHERE Id = :workOrderId];
        return workOrder[0].WorkType.Name;
    }
    
    @AuraEnabled
    public static Boolean workTypeCheck(String woId) {
        WorkOrder workOrder = [SELECT WorkType.Site_Survey_Allowed_For_Closeout__c FROM WorkOrder WHERE Id = :woId];
        return workOrder.WorkType.Site_Survey_Allowed_For_Closeout__c;
    }
  
    @AuraEnabled
    public static FSL_AppUtils.ResponseWrapper addInventoryProducts(Map<String, Object> formData, String productsJson, String locationId) {
        try {
            List<ProductWrapper> productItemList = (List<ProductWrapper>) System.JSON.deserialize(productsJson, List<ProductWrapper>.class);
            List<SerializedProduct> serializedProduct = new List<SerializedProduct>();
            Set<string> serialNumber = new set <string> ();
            
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

            for(ProductItem prdItem : [SELECT Id,Product2Id,QuantityOnHand FROM ProductItem WHERE LocationId = :locationId]) {
                existingProductItemMap.put(prdItem.Product2Id,prdItem);
            }
            
            for (ProductWrapper prdWrapper: productItemList) {
                ProductItem prdItem = new ProductItem();
                ProductItem srPrdItem = new ProductItem();
                SerializedProduct serializedProductWithPrdItem = new SerializedProduct();
                
                if (prdWrapper.IsSerialized) {
                    //Serialized Product already exist in location or not
                    if(existingProductItemMap.containsKey(prdWrapper.ProductId)){
                        serializedProductWithPrdItem.SerialNumber = prdWrapper.SerialNumber;
                        serializedProductWithPrdItem.Product2Id = prdWrapper.ProductId;
                        serializedProductWithPrdItem.ProductItemId = existingProductItemMap.get(prdWrapper.ProductId).Id;
                        serializedProductWithPrdItem.Status = 'Available';
                        serializedProductListForExistingProductItem.add(serializedProductWithPrdItem);
                    }else{
                        if(! newSerializedProductItemMap.containsKey(prdWrapper.ProductId)){
                            srPrdItem.LocationId = locationId;  
                            srPrdItem.Product2Id = prdWrapper.ProductId;
                            srPrdItem.QuantityOnHand = 0.00;
                            newSerializedProductItemMap.put(prdWrapper.ProductId,srPrdItem);
                        }
                        serializedProductWithPrdItem.SerialNumber = prdWrapper.SerialNumber;
                        serializedProductWithPrdItem.Product2Id = prdWrapper.ProductId;
                        serializedProductWithPrdItem.ProductItemId = null;
                        serializedProductWithPrdItem.Status = 'Available';
                        
                        if(newSerializedProductMap.containsKey(prdWrapper.ProductId)){
                            newSerializedProductMap.get(prdWrapper.ProductId).add(serializedProductWithPrdItem);
                        }else{
                            newSerializedProductMap.put(prdWrapper.ProductId, new List<SerializedProduct>{serializedProductWithPrdItem});
                        }                    
                    }
                }
            }
            
            
            if(!serializedProductListForExistingProductItem.isEmpty()){
                insert serializedProductListForExistingProductItem;
                serializedProduct.addAll(serializedProductListForExistingProductItem) ;
                
            }
            if(!newSerializedProductItemMap.values().isEmpty()){
                insert newSerializedProductItemMap.values();
                list<SerializedProduct> newSerializedProductList = new list<SerializedProduct>();
                for(ProductItem newPrdItem : newSerializedProductItemMap.values()){
                    for(SerializedProduct srp:newSerializedProductMap.get(newPrdItem.Product2Id)){
                        srp.ProductItemId = newPrdItem.Id;
                        newSerializedProductList.add(srp);
                    }                
                }
                if(!newSerializedProductList.isEmpty()){
                    insert newSerializedProductList;
                    serializedProduct.addAll(newSerializedProductList) ;
                }
            }

            updateTmoDetails(formdata,productsJson,locationId,serializedProduct);
            return new FSL_AppUtils.ResponseWrapper('SUCCESS', serializedProduct, null);
        } catch (Exception e) {
            ExceptionUtil.publishException('addInventoryProducts', e.getLineNumber(), e.getMessage(), e.getStackTraceString());
            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }
    
    // Method to check SerializedProduct is present in inventory or not
    public static  Map<Id, Map<String, SerializedProduct>> exisitingSerializedProductCheck(Set<String> serialNumber){
        Map<Id, Map<String, SerializedProduct>> existingSerializedProductMap = new Map<Id, Map<String, SerializedProduct>>();
        
        for (SerializedProduct srPrdt : [SELECT Id, Name, Product2Id, ProductItemId, SerialNumber, Status FROM SerializedProduct 
                                         WHERE Status = 'Available' AND SerialNumber IN :serialNumber]) {
               if (existingSerializedProductMap.containsKey(srPrdt.Product2Id)) {
                    existingSerializedProductMap.get(srPrdt.Product2Id).put(srPrdt.SerialNumber, srPrdt);
                } else {
                     existingSerializedProductMap.put(srPrdt.Product2Id, new Map<String, SerializedProduct>{srPrdt.SerialNumber => srPrdt});
                    }
                }
        return existingSerializedProductMap;
    }
    
    
    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
    
    private static WorkOrder  workOrderGenerator(Map<String, Object> formData){
        WorkOrder workOrderRecord = new WorkOrder();
        workOrderRecord.Id = (Id)formData.get('Id'); 
        workOrderRecord.Cellular_Gateway_Router_Arrival_Spe__c = (String)formData.get('uploadArrivalCG');
        workOrderRecord.Cellular_Gateway_Router_Download_Spee__c = (String)formData.get('downloadArrivalCG');
        workOrderRecord.Departure_Upload_Speed__c = (String)formData.get('uploadDepartureCG');
        workOrderRecord.Cellular_Gateway_Router_Departure_downlo__c = (String)formData.get('downloadDepartureCG');
        workOrderRecord.Tablet_IoT_Device_Arrival_Upload_Speed__c = (String)formData.get('uploadArrivalIoT');
        workOrderRecord.Tablet_IoT_Device_Arrival_Download_Speed__c = (String)formData.get('downloadArrivalIoT');
        workOrderRecord.Tablet_IoT_Departur_Upolad_Speed__c = (String)formData.get('uploadDepartureIoT');
        workOrderRecord.Tablet_IoT_Departur_Download_Speed__c = (String)formData.get('downloadDepartureIoT');
        workOrderRecord.Existing_SIM_Number__c = (String)formData.get('existingSIMNumber');
        workOrderRecord.Existing_MSISDN_Number_if_applicable__c = (String)formData.get('existingMSISDNNumber');
        workOrderRecord.Installed_SIM_Number__c = (String)formData.get('installedSIMNumber');
        workOrderRecord.Installed_MSISDN_Number__c = (String)formData.get('installedMSISDNNumber');
        workOrderRecord.Equipment_Testing_and_Service_Validatio__c = (Boolean)formData.get('equipmentValidation1');
        workOrderRecord.Acceptance_of_Installation_Service_Repai__c = (Boolean)formData.get('installationRepair');
        workOrderRecord.Site_Survey_Acknowledgement__c = (Boolean)formData.get('siteSurveyAcknowledgement');
        return workOrderRecord;
    }
    
    public class ProductWrapper {
        @AuraEnabled public String ProductId;
        @AuraEnabled public String ProductName;
        @AuraEnabled public String SerialNumber;
        @AuraEnabled public String Location;
        @AuraEnabled public Boolean IsSerialized;
        @AuraEnabled public String LocationId;
        @AuraEnabled public Boolean additionalProduct;
        @AuraEnabled public String otherTextBox;
    }
}