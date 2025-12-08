public with sharing class PV_FullFill_OrderParts {

@AuraEnabled
public static void updateOrderParts(String orderPartsToUpdate){
    List<PartsWrapper> partsToUpdate = (List<PartsWrapper>) JSON.deserialize (orderPartsToUpdate,List<PartsWrapper>.class);
    List<Line_Item__c> lineItem = new List<Line_Item__c>();
    List<PV_Warehouse__c> warehouseList = new List<PV_Warehouse__c>();
    Map<String,Integer> inventoryInfo = new Map<String,Integer>();

    for(PartsWrapper partwrap: partsToUpdate){
        System.debug('partwrap '+partwrap);
        List<String> ids = new List<String>();
        ids = partwrap.partId.split('--');
        if(String.isNotBlank(partwrap.partFullFillQty)){
            lineItem.add( new Line_Item__c( id = ids[0], Fulfilled_Quantity__c = integer.valueOf(partwrap.partFullFillQty)));
            inventoryInfo.put(ids[1], integer.valueOf(partwrap.partFullFillQty));
        }
        
    }
    if(lineItem.size()> 0){
        update lineItem;
    }
    /*for(PV_Warehouse__c wh: warehouseQuantityCheck(inventoryInfo.keySet())){
        System.debug('Quantity_At_Hand__c '+wh.Quantity_At_Hand__c);
        System.debug('inventoryInfo '+inventoryInfo.get(wh.Id));
        warehouseList.add(new PV_Warehouse__c(Id = wh.Id,Quantity_At_Hand__c = wh.Quantity_At_Hand__c - inventoryInfo.get(wh.Id)));
        System.debug('warehouseList inside for '+warehouseList);        
    }
    System.debug('warehouseList '+warehouseList);
    if(warehouseList.size()>0){
        update warehouseList;
    }*/    
}


@AuraEnabled
public static void updateOrderAndInventory(String orderPartsToUpdate, String orderId){
    try {

        if(String.isNotBlank(orderId)){
            Order__c ord = new Order__c( id = orderId, Stage__c = 'Fulfilled' );
            update ord;
        }

        List<PartsWrapper> partsToUpdate = (List<PartsWrapper>) JSON.deserialize (orderPartsToUpdate,List<PartsWrapper>.class);
        List<PV_Warehouse__c> warehouseList = new List<PV_Warehouse__c>();
        Map<String,Integer> inventoryInfo = new Map<String,Integer>();

        for(PartsWrapper partwrap: partsToUpdate){
            List<String> ids = new List<String>();
            ids = partwrap.partId.split('--');
            if(String.isNotBlank(partwrap.partFullFillQty)){
                inventoryInfo.put(ids[1], integer.valueOf(partwrap.partFullFillQty));
            }
        }

        for(PV_Warehouse__c wh: warehouseQuantityCheck(inventoryInfo.keySet())){
            warehouseList.add(new PV_Warehouse__c(Id = wh.Id,Quantity_At_Hand__c = wh.Quantity_At_Hand__c - inventoryInfo.get(wh.Id)));
        }
        if(warehouseList.size()>0){
            update warehouseList;
        }

    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

@AuraEnabled
public static String getOrderPartsAndWarehouseInfo(String orderId){
    List<PartsWrapper> partsInfos = new List<PartsWrapper>();
    List<Line_Item__c> lineItems = getOrderPartLines(orderId);
    String warehouseName;
    Set<String> allItems = new Set<String>();
    List<Order__c> ord= [SELECT Id,Name from Order__c where id=:orderId limit 1];
    String ordNumber=ord[0].Name;
    for(Line_Item__c lineItem : lineItems){
        if(String.isBlank(warehouseName)){
            warehouseName = lineItem.Order__r.Warehouse__c;
        }
        allItems.add(lineItem.Item__r.Item_Name_Number__c );
    }
    Map<String, PV_Warehouse__c> wareHousepartAndDetails = new Map<String, PV_Warehouse__c> ();
    for(PV_Warehouse__c warehouse : getWarehouseInfo(warehouseName, allItems)){
        wareHousepartAndDetails.put(warehouse.Part__c, warehouse);
    }    
    for(Line_Item__c line_Item :  getOrderPartLines(orderId)){
        PartsWrapper partsInfo = new PartsWrapper();
            partsInfo.partName          = line_Item.Item__r.Item_Name_Number__c;
            partsInfo.partReqQty        = String.valueof(line_Item.Requested_Quantity__c);
            partsInfo.partDescription   = line_Item.Item_Description__c;
            partsInfo.partFullFillQty   = line_Item.Fulfilled_Quantity__c!=null?String.valueof(line_Item.Fulfilled_Quantity__c):String.valueof(line_Item.Requested_Quantity__c);
            partsInfo.orderNumber       = ordNumber;
            partsInfo.partBin           = wareHousepartAndDetails.containsKey(line_Item.Item__r.Item_Name_Number__c)?wareHousepartAndDetails.get(line_Item.Item__r.Item_Name_Number__c).Bin__c:'';
            partsInfo.partWarehouseQty  = wareHousepartAndDetails.containsKey(line_Item.Item__r.Item_Name_Number__c)?String.valueof(wareHousepartAndDetails.get(line_Item.Item__r.Item_Name_Number__c).Quantity_At_Hand__c):'';
            partsInfo.inventoryId		= wareHousepartAndDetails.containsKey(line_Item.Item__r.Item_Name_Number__c)?String.valueof(wareHousepartAndDetails.get(line_Item.Item__r.Item_Name_Number__c).Id):'';
            partsInfo.partId			= line_Item.Id+'--'+partsInfo.inventoryId;
        partsInfos.add(partsInfo);
    }
    return JSON.serialize(partsInfos);
}

public static List<Line_Item__c> getOrderPartLines(String orderId){
    return [SELECT  Id, Requested_Quantity__c,
            		Fulfilled_Quantity__c,
                    Item__r.Name, 
                    Item_Description__c,
                    Order__r.Warehouse__c, 
                    Item__r.Item_Name_Number__c 
                FROM Line_Item__c WHERE Order__c = :orderId];
}

public static List<PV_Warehouse__c> getWarehouseInfo(String warehouseName, Set<String> itemNumbers){
    return [SELECT  Id, 
                    Bin__c, 
                    Part__c, 
                    Name, 
                    Quantity_At_Hand__c 
            FROM PV_Warehouse__c 
            WHERE Name = :warehouseName AND Part__c IN : itemNumbers];
}

public static List<PV_Warehouse__c> warehouseQuantityCheck(Set<String> warehouseId){
    return [SELECT  Id, 
                    Quantity_At_Hand__c 
            FROM PV_Warehouse__c 
            WHERE Id IN :warehouseId];
}

public class PartsWrapper{
    public string partId;
    public string partName;
    public string partDescription;
    public string partReqQty;
    public string partFullFillQty;
    public string orderNumber;
    public string partBin;
    public string partWarehouseQty;
    public string inventoryId;

}
}