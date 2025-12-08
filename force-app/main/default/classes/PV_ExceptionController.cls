/**
* @description       : Controller class for Pv_Exception LWC
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 12-06-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/

//method to get product details
public with sharing class PV_ExceptionController {
    
    @AuraEnabled(cacheable=true)
    public static FSL_AppUtils.ResponseWrapper getProducts(){

        try {

            Map<String, String> getProducts = new Map<String, String>();
            for(Product2 products : [SELECT Name, Id FROM Product2 WHERE Family ='Viasat' AND FSL_Product__c = TRUE ]){
                getProducts.put(products.Name, products.Id);
            }

            return new FSL_AppUtils.ResponseWrapper('SUCCESS', getProducts, null);

        }catch(Exception e) {

            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }
    
    @AuraEnabled
    public static FSL_AppUtils.ResponseWrapper getVendorType (string recordId){

        try{

            List<ServiceAppointment > sa= [SELECT Id, FSSK__FSK_Work_Order__r.Vendor__c ,FSSK__FSK_Work_Order__r.WorkType.Name 
                                       FROM ServiceAppointment WHERE Id =:recordId];
        
            List<Vendor_Setting__mdt> vendorTypeCheck = [SELECT Is_Active__c,Vendor__c,Work_Type_Long__c FROM Vendor_Setting__mdt 
                                                        WHERE Vendor__c =:sa[0].FSSK__FSK_Work_Order__r.Vendor__c AND Is_Active__c = true 
                                                        AND Component_Name__c = 'Exception' ];
            
            Boolean isCompVisible = false;
            if(!vendorTypeCheck.isEmpty()){
                if(vendorTypeCheck[0].Work_Type_Long__c != null ){
                    isCompVisible = vendorTypeCheck[0].Work_Type_Long__c.split(',').contains(sa[0].FSSK__FSK_Work_Order__r.WorkType.Name)? true : false;
                }
            }

            return new FSL_AppUtils.ResponseWrapper('SUCCESS', isCompVisible, null);

        }catch(Exception e) {

            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }
    
    @AuraEnabled
    public static FSL_AppUtils.ResponseWrapper getSharinPixImage (string recordId){

        try {

            List<ServiceAppointment > sa= [SELECT Id, FSSK__FSK_Work_Order__c FROM ServiceAppointment WHERE Id =:recordId];
            List<sharinpix__SharinPixImage__c > workOrderImage= [SELECT Id, Work_Order_Image__c FROM sharinpix__SharinPixImage__c 
                                                                WHERE Work_Order_Image__c =: sa[0].FSSK__FSK_Work_Order__c];

            return new FSL_AppUtils.ResponseWrapper('SUCCESS', workOrderImage.isEmpty(), null);

        }catch(Exception e) {

            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }    
    }
}