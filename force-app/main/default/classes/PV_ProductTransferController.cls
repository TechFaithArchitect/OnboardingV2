/**
* @description       : Apex Class for Inventory transfer
* @author            : Impaqtive DevTeam
* @last modified on  : 08-02-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            	   Modification
* 1.0   08-02-2023   Impaqtive DevTeam     Initial Version
**/
public class PV_ProductTransferController {
    @AuraEnabled(cacheable=false)
    public static void transferProduct(String productTransferJson,String fromLocationId,String ToLocationId) {
        try{  
            list<ProductTransferWrapper> productTransferList=(List<ProductTransferWrapper>) System.JSON.deserialize(productTransferJson, List<ProductTransferWrapper>.class);
            Map<Id,ProductTransfer> serializedProductTransferMap = new Map<Id,ProductTransfer>();
            Map<Id,ProductTransfer> nonSerializedProductTransferMap = new Map<Id,ProductTransfer>();
            Set<String> productSerialNumeberSet = new Set<String>();
            for(ProductTransferWrapper prdTransfer:productTransferList){
                ProductTransfer pt = new ProductTransfer();
                pt.SourceLocationId = fromLocationId;
                pt.DestinationLocationId=ToLocationId;
                pt.Product2Id = prdTransfer.ProductId;
                if(prdTransfer.IsSerialized){
                    if(serializedProductTransferMap.containsKey(prdTransfer.ProductId)){
                        serializedProductTransferMap.get(prdTransfer.ProductId).QuantitySent += 1;
                        productSerialNumeberSet.add(prdTransfer.SerialNumber);
                    }else{
                        pt.QuantitySent = 1.00;
                        serializedProductTransferMap.put(prdTransfer.ProductId,pt);
                        productSerialNumeberSet.add(prdTransfer.SerialNumber);
                    }
                }else{
                    if(nonSerializedProductTransferMap.containsKey(prdTransfer.ProductId)){
                        nonSerializedProductTransferMap.get(prdTransfer.ProductId).QuantitySent += Decimal.valueOf(prdTransfer.Quantity);
                        nonSerializedProductTransferMap.get(prdTransfer.ProductId).QuantityReceived += Decimal.valueOf(prdTransfer.Quantity);
                    }else{
                        pt.QuantitySent = Decimal.valueOf(prdTransfer.Quantity);
                        pt.QuantityReceived = Decimal.valueOf(prdTransfer.Quantity);
                        pt.IsReceived = true;
                        nonSerializedProductTransferMap.put(prdTransfer.ProductId,pt);
                    }
                    
                }
            }
            if(!nonSerializedProductTransferMap.values().isEmpty()){
                validateProductTransfer(fromLocationId,nonSerializedProductTransferMap,null);
                insert nonSerializedProductTransferMap.values();
            }
            if(! productSerialNumeberSet.isEmpty()){
                validateProductTransfer(fromLocationId,serializedProductTransferMap,new List<String>(productSerialNumeberSet));
                List<SerializedProduct> serializedPRoductList=[Select Id,Product2Id,Status from SerializedProduct where SerialNumber IN : productSerialNumeberSet];
                insert serializedProductTransferMap.values();
                List<ProductTransferState> producttransferStateSendList = new List <ProductTransferState>();
                List<ProductTransferState> producttransferStateRecievedList = new List <ProductTransferState>();
                
                 Map<Id,String> serializedProductStatusMap = new Map<Id,String>();
                for(SerializedProduct srprdt:serializedPRoductList){
                    if(serializedProductTransferMap.containsKey(srprdt.Product2Id)){
                        ProductTransferState ptState = new ProductTransferState();
                        ptState.ProductTransferId = serializedProductTransferMap.get(srprdt.Product2Id).Id;
                        ptState.SerializedProductId = srprdt.Id;
                        ptState.Action ='Send';
                        ptState.TransferState = 'Sent';
                        producttransferStateSendList.add(ptState);
                        serializedProductStatusMap.put(srprdt.Id,srprdt.Status);
                    }
                }
                
                insert producttransferStateSendList;
                for(ProductTransferState sendItem:producttransferStateSendList){
                    ProductTransferState ptRecievedState = new ProductTransferState();
                    ptRecievedState.ProductTransferId = sendItem.ProductTransferId;
                    ptRecievedState.SerializedProductId = sendItem.SerializedProductId;
                    ptRecievedState.Action ='Receive';
                    ptRecievedState.TransferState = serializedProductStatusMap.get(sendItem.SerializedProductId);
                    producttransferStateRecievedList.add(ptRecievedState);
                }
                insert producttransferStateRecievedList;
                for(ProductTransfer prdRecieved: serializedProductTransferMap.values()){
                    prdRecieved.IsSent = true;
                }
                update serializedProductTransferMap.values();
                for(ProductTransfer prdRecieved: serializedProductTransferMap.values()){
                    
                    prdRecieved.IsReceived = true;
                    prdRecieved.QuantityReceived = prdRecieved.QuantitySent;
                }
                update serializedProductTransferMap.values();
            }
        }catch (Exception ex) {
            system.debug(ex.getMessage());
            ExceptionUtil.publishException('PV_ProductTransferController - transferProduct', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled(cacheable=false)
    public Static void validateProductTransfer(String fromLocationId, Map<Id,ProductTransfer> productTransferMap, List<String> serialNumbers){
        Map<Id,Decimal> productsAvailableMap = new Map<Id,Decimal>();
        Map<Id,String> productNameMap = new Map<Id,String>();
        for(ProductItem pitem: [Select Id,Product2Id, QuantityOnHand from ProductItem where LocationId = :fromLocationId]){
            productsAvailableMap.put(pitem.Product2Id,pitem.QuantityOnHand);
        }
        for(Product2 pdt:[Select Id,Name from Product2 where Id IN : productTransferMap.keySet()]){
            productNameMap.put(pdt.Id, pdt.Name);
        }
        for(ProductTransfer ptItem:productTransferMap.values()){
            if(! productsAvailableMap.containsKey(ptItem.Product2Id) || ptItem.QuantitySent > productsAvailableMap.get(ptItem.Product2Id)){
                throw newMessageException('Either the product '+productNameMap.get(ptItem.Product2Id)+' is not available in your source location, or the required quantity is currently unavailable.');
            }
        }
        if(serialNumbers != null){
            list<String> availableSerializedProduct = new list<String>();
            for(SerializedProduct szPrd:[Select Id,SerialNumber from SerializedProduct where (Status = 'Available' OR Status = 'Damaged') AND ProductItem.LocationId =:fromLocationId 
                                         AND Product2Id IN :productTransferMap.keySet() AND SerialNumber IN : serialNumbers]){
                                             availableSerializedProduct.add(szPrd.SerialNumber);
                                         }
            String invalidSerialNumber = '';
            for(String prdItem: serialNumbers){
                if(! availableSerializedProduct.contains(prdItem)){
                    if(!String.isBlank(invalidSerialNumber)){
                        invalidSerialNumber +=',';
                    }
                    invalidSerialNumber += prdItem;
                    
                }
            }
            if(!String.isBlank(invalidSerialNumber)){
                throw newMessageException('The serial numbers \''+invalidSerialNumber+ '\' are currently unavailable at the source location.');
            }
        }
    }
    @AuraEnabled(cacheable=false)
    public static void handleDefectProduct(String defectProductJson,String fromLocationId) {
        list<Schema.Location> locationItem = [Select id from Location where Name =: PV_FSL_Config__mdt.getInstance('Damaged_Prduct_Warehouse').Value__c limit 1];
        if(!locationItem.isEmpty()){
            String defectInventoryLocation = locationItem[0].Id;
            list<ProductTransferWrapper> productTransferList=(List<ProductTransferWrapper>) System.JSON.deserialize(defectProductJson, List<ProductTransferWrapper>.class);
            Set<String> defectiveSerialNumberSet = new Set<String>();
            list<SerializedProduct> rmaAddedserializedProductList = new list<SerializedProduct>();
            //Set<String> defectiveSerialProductSet = new Set<String>();
            Map<String,List<String>> defectiveProductMap = new Map<String,List<String>>();
            Map<String,String> rmaMap = new Map<String,String>();
            for(ProductTransferWrapper prdTransfer:productTransferList){
                defectiveSerialNumberSet.add(prdTransfer.SerialNumber);
                // defectiveSerialProductSet.add(prdTransfer.ProductId);
                if(defectiveProductMap.containsKey(prdTransfer.ProductId)){
                    defectiveProductMap.get(prdTransfer.ProductId).add(prdTransfer.SerialNumber);
                }else{
                    defectiveProductMap.put(prdTransfer.ProductId,new list<String> {prdTransfer.SerialNumber});
                }
                rmaMap.put(prdTransfer.SerialNumber, prdTransfer.rmaNumber);
            }
            String invalidItem = '';
            for(SerializedProduct srp :[SELECT Id,SerialNumber,Status,Product2Id from SerializedProduct where SerialNumber IN:defectiveSerialNumberSet AND Product2Id IN:defectiveProductMap.keySet()]){
                if (srp.Status != 'Damaged' && srp.Status != 'Available' && defectiveProductMap.containsKey(srp.Product2Id) && defectiveProductMap.get(srp.Product2Id).contains(srp.SerialNumber)) {
                    if(!String.isBlank(invalidItem)){
                        invalidItem +=',';
                    }
                    invalidItem += srp.SerialNumber;
                }
                if(srp.Status == 'Damaged' && defectiveProductMap.containsKey(srp.Product2Id) && defectiveProductMap.get(srp.Product2Id).contains(srp.SerialNumber)){
                   SerializedProduct szp = new SerializedProduct();
                    szp.Id = srp.Id;
                    szp.RMA_Number__c = rmaMap.get(srp.SerialNumber);
                    rmaAddedserializedProductList.add(szp);
                }
            }
            if(!String.isBlank(invalidItem)){
                throw newMessageException('The serial numbers: '+invalidItem+' are not valid.');
            }
            transferProduct(defectProductJson,fromLocationId,defectInventoryLocation);
            try{
              update rmaAddedserializedProductList;
            }catch (Exception ex) {
            system.debug(ex.getMessage());
            ExceptionUtil.publishException('PV_ProductTransferController - handleDefectProduct', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
            
            
        }
        
    }

    @AuraEnabled(cacheable=false)
    public static List<OptionWrapper> getSerializedProducts(String locationId, String productId, Boolean isRMA) {
        try {
            String query = 'SELECT Id, SerialNumber '
                + 'FROM SerializedProduct '
                + 'WHERE ProductItem.LocationId = :locationId '
                + 'AND Product2Id = :productId ';
            if (isRMA) {
                query += 'AND (Status = \'Available\' OR Status = \'Damaged\') ';
            }
            Map<String, Object> bindVars = new Map<String, Object>{
                'locationId' => locationId,
                'productId' => productId
            };

            List<OptionWrapper> options = new List<OptionWrapper>();
            for(SerializedProduct serializedProduct : (List<SerializedProduct>) Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE)) {
                OptionWrapper option = new OptionWrapper();
                option.label = serializedProduct.SerialNumber;
                option.value = serializedProduct.SerialNumber;
                options.add(option);
            }

            return options;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            ExceptionUtil.publishException('PV_ProductTransferController - getSerializedProducts', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
    public class ProductTransferWrapper {
        public String ProductName;	//
        public String ProductId;
        public String SerialNumber;	//
        public String Quantity;	//
        public String Location;	//
        public Boolean IsSerialized;
        public String rmaNumber;
    }
    public class OptionWrapper {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }
}