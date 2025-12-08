/**
* @description       : Controller Class for PV_SiteSurveyService LWC
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  :
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Test class 		: PV_InventroyDetailsControllerTest
* Date              :  18-07-2023
**/
    public with sharing class PV_InventroyDetailsController {
    @AuraEnabled
    public static List<ProductInventory> getInventoryDetails(String usrId ,date startDate,date endDate){
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> serviceResourceId = new Set<Id>();
        List<ProductDetails> productDetailsList = new list<ProductDetails>();
        List<ServiceAppointment> saList  = new List<ServiceAppointment> (); 
        Map<Id,Id> sRLocationIdMap = new Map<Id,Id>();
        Map<Id,string> srNameMap = new Map<Id,String>();
        Map<Id,Map<Id,Decimal>> locationProductMap = new Map<Id,Map<Id,Decimal>>();
        Map<Id,Set<Id>> serviceResourceWOMap = new Map<Id,Set<Id>>(); //SR Id 
        Map<Id,List<ProductRequired>> wOProductReqMap = new Map<Id,List<ProductRequired>> ();//WO id 
        Map<Id,List<ProductRequired>> sRProductReqMap = new Map<Id,List<ProductRequired>> ();
        Map<Id,Map<Id,Decimal>> srProductRequiredMap = new Map<Id,Map<Id,Decimal>>();
        Map<Id,Set<Id>>srProductListMap = new Map<Id,Set<Id>>();
        Map<Id,String> srProductNameMap = new Map<Id,String>();
        
        List<User> usr = [SELECT Id, Name, Contact.AccountId  FROM User WHERE Id =:usrId];
        
        List<ServiceResource> allServiceResource = [SELECT Id, Name, AccountId,RelatedRecordId ,LocationId 
                                                    FROM ServiceResource
                                                    WHERE AccountId =: usr[0].Contact.AccountId AND ResourceType ='T' ];
        
     
        for (ServiceResource sr : allServiceResource ){
            sRLocationIdMap.put(sr.Id,sr.LocationId);
            serviceResourceId.add(sr.Id );
            srNameMap.put(sr.Id, sr.Name);
        }
        
        if(endDate != null  ){
             saList = [SELECT Id ,ParentRecordId ,FSSK__FSK_Assigned_Service_Resource__r.LocationId,
                                           FSSK__FSK_Assigned_Service_Resource__r.Name,FSSK__FSK_Work_Order__c,AppointmentNumber
                                           FROM ServiceAppointment 
                                           WHERE FSSK__FSK_Assigned_Service_Resource__c IN :serviceResourceId AND
                      						DAY_ONLY(SchedStartTime) >= :startDate AND DAY_ONLY(SchedStartTime) <= :endDate
                                            AND (Status = 'Dispatched' OR Status = 'Scheduled' )];
                                          
            
        }else{
            saList = [SELECT Id ,ParentRecordId ,FSSK__FSK_Assigned_Service_Resource__r.LocationId,
                                           FSSK__FSK_Assigned_Service_Resource__r.Name,FSSK__FSK_Work_Order__c,AppointmentNumber
                                           FROM ServiceAppointment 
                                           WHERE FSSK__FSK_Assigned_Service_Resource__c IN :serviceResourceId AND  DAY_ONLY(SchedStartTime) =: startDate AND (Status = 'Dispatched' OR Status = 'Scheduled' ) ];
            
        }
        for (ServiceAppointment woId : saList ){
            workOrderIds.add(woId.ParentRecordId);
        }
        
        List<ProductItem> productItems = [SELECT Id, Product2Id, LocationId, QuantityOnHand, ProductName 
                                          FROM ProductItem 
                                          WHERE LocationId IN:sRLocationIdMap.values()];
      
        
        for(ProductItem pItem : productItems){
            if(locationProductMap.containsKey(pItem.LocationId)){
                locationProductMap.get(pItem.LocationId).put(pItem.Product2Id,pItem.QuantityOnHand);
            }else{
                locationProductMap.put(pItem.LocationId,new Map<Id, Decimal> { pItem.Product2Id => pItem.QuantityOnHand });
            }
        }
        
        List<ProductRequired> productRequired = [SELECT Id, QuantityRequired, ProductName, ParentRecordId,Product2Id  
                                                 FROM ProductRequired 
                                                 WHERE ParentRecordId IN :workOrderIds];
    
        
        for(ServiceAppointment srWo: saList){
            if(!serviceResourceWOMap.containsKey(srWo.FSSK__FSK_Assigned_Service_Resource__c)){
                if(srWo.FSSK__FSK_Work_Order__c != null){
                    serviceResourceWOMap.put(srWo.FSSK__FSK_Assigned_Service_Resource__c, new Set<Id>{srWo.FSSK__FSK_Work_Order__c});
                }
            }else{
                if(srWo.FSSK__FSK_Work_Order__c != null){
                    serviceResourceWOMap.get(srWo.FSSK__FSK_Assigned_Service_Resource__c).add(srWo.FSSK__FSK_Work_Order__c);
                }
            }
        }
        
        for(ProductRequired productRequiredMap : productRequired){
            if(!wOProductReqMap.containsKey(productRequiredMap.ParentRecordId)){
                wOProductReqMap.put(productRequiredMap.ParentRecordId, new List<ProductRequired>{productRequiredMap});
            }else{
                wOProductReqMap.get(productRequiredMap.ParentRecordId).add(productRequiredMap);
            }
        }
        
        for(Id srId :serviceResourceWOMap.keyset()){
            List<ProductRequired> productRequiredList = new List <ProductRequired>();
            for(Id workOrderId : serviceResourceWOMap.get(srId)){
                if(wOProductReqMap.containsKey(workOrderId) && !wOProductReqMap.get(workOrderId).isEmpty()){
                    productRequiredList.addAll(wOProductReqMap.get(workOrderId));
                }
            }
            sRProductReqMap.put(srId,productRequiredList);
        }
        
        for(Id srId : sRProductReqMap.keyset()){
            for(ProductRequired prdRequired:sRProductReqMap.get(srId)){
                if(srProductRequiredMap.containsKey(srId)){
                    if(srProductRequiredMap.get(srId).containskey(prdRequired.Product2Id)){
                        Decimal qtyReqired = srProductRequiredMap.get(srId).get(prdRequired.Product2Id) + prdRequired.QuantityRequired;
                        
                        srProductRequiredMap.get(srId).put( prdRequired.Product2Id,qtyReqired);  
                    }else{
                        srProductRequiredMap.get(srId).put( prdRequired.Product2Id,prdRequired.QuantityRequired);                       
                    }
                }else{
                    srProductRequiredMap.put(srId,new Map<Id, Decimal> { prdRequired.Product2Id => prdRequired.QuantityRequired });
                }
                
                if(srProductListMap.containsKey(srId)){
                    srProductListMap.get(srId).add(prdRequired.Product2Id);
                }else{
                    srProductListMap.put(srId, new Set<Id>{prdRequired.Product2Id});
                }
                srProductNameMap.put(prdRequired.Product2Id,prdRequired.ProductName);
            }
        }
        List<ProductInventory> productInventoryList = new List<ProductInventory>();
        for(Id srId : sRProductReqMap.keyset()){
            ProductInventory pi  = new ProductInventory();
            pi.srId = srId;
            pi.technicianName = srNameMap.get(srId);
            if(srProductListMap.containsKey(srId)){
                List<productDetailsInventory> productDetailList = new List<productDetailsInventory> ();
                for(Id prdId:srProductListMap.get(srId)){
                    productDetailsInventory piproduct  = new productDetailsInventory();
                    piproduct.productName = srProductNameMap.get(prdId);
                    piproduct.quantityRequired = srProductRequiredMap.get(srId).get(prdId);
                    piproduct.quantityOnHand = locationProductMap.get(sRLocationIdMap.get(srId)).get(prdId) != null ?  locationProductMap.get(sRLocationIdMap.get(srId)).get(prdId) : 0.00;
                    productDetailList.add(piproduct);
                }
                pi.product = productDetailList;
            }
            productInventoryList.add(pi);
        }
        
        
        return productInventoryList;
    }
    
    
    public class ProductDetails {
        @AuraEnabled
        public decimal quantityRequired = 0.00;
        @AuraEnabled
        public decimal quantityOnHand = 0.00;
        @AuraEnabled
        public String productName ;
        @AuraEnabled
        public String serviceResourceName ; 
        @AuraEnabled
        public Id srId;
    }
    
    public class ProductInventory {
        @AuraEnabled
        public String technicianName ;
        @AuraEnabled
        public String srId ;
        @AuraEnabled
        public productDetailsInventory[] product;
    }
    class productDetailsInventory {
        @AuraEnabled
        public decimal quantityRequired = 0.00;
        @AuraEnabled
        public decimal quantityOnHand = 0.00;
        @AuraEnabled
        public String productName ;
    }
    
}