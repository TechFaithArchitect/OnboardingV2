/**
* @description       : Handler Class PV_ExceptionTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 12-06-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
public class PV_ExceptionTriggerHandler{
    public static void exceptionAfterInsert (List<Exception__c> exceptionList){
        
        String categoryTypeList = '';
        Set<String> typeValues = new Set<String>();
        Set<Id> serviceAppId = new Set<Id>();
        List<Id> serviceResId = new List<Id>();
        List<Id> accountId = new List<Id>();
        List<Id> contactId = new List<Id>();
        Set<String> categoryType = new Set<String>();
        Map<String,Decimal> typeAmountMap = new Map<String,Decimal> ();
        Map<String,String> typeCategoryMap = new Map<String,String>();
        for(Exception__c exp : exceptionList ){
            serviceAppId.add(exp.Service_Appointment__c);
            List<String> selections = exp.Type__c.split(';');
            if (selections != null && !selections.isEmpty()) {
                typeValues.addAll(selections);
            }
        }
        
        List<ServiceAppointment> serviceAppList = [SELECT FSSK__FSK_Assigned_Service_Resource__c FROM ServiceAppointment WHERE Id IN:serviceAppId ];
        for(ServiceAppointment serviceResourceId : serviceAppList ){
            serviceResId.add(serviceResourceId.FSSK__FSK_Assigned_Service_Resource__c);  
        }
        System.debug('serviceAppId>>>>>'+serviceAppId);
        system.debug('typeValues>>>>>>>'+typeValues);
        try{
            for(String totalAmount : typeValues ){
                typeAmountMap.put(totalAmount,PV_Constant.typeAmount.get(totalAmount));
                
            }
            for(String typeCategory : typeValues ){
                typeCategoryMap.put(typeCategory,PV_Constant.typeCategory.get(typeCategory));
            }
            
            for(String categoryList : typeValues){
                categoryType.add(typeCategoryMap.get(categoryList));            
            }
            System.debug('categoryType>>>>.'+categoryType);
            
            
            for(Exception__c categoryExcep : exceptionList ){
                for(String categoryTypevalues :categoryType){
                    categoryTypeList += categoryTypevalues +';';
                    categoryExcep.Category__c = categoryTypeList;
                    System.debug('categoryTypeList>>>>>>>>>>>'+categoryTypeList);
                }
            } 
            System.debug('categoryTypeList>>>>>>>>>>>'+categoryTypeList);
            
            for(Exception__c exp : exceptionList ){
                for(String typeCategory : typeValues ){
                    //exp.Total_Amount__c = totalAmount;
                    exp.Antenna_credit__c = typeAmountMap.get('Antenna credit')!=null?typeAmountMap.get('Antenna credit'):null;
                    exp.Reinstall_Service_Call__c = typeAmountMap.get('Reinstall (Service Call)')!=null?typeAmountMap.get('Reinstall (Service Call)'):null;
                    exp.Reinstall_Upgrade__c = typeAmountMap.get('Reinstall (Upgrade)')!=null?typeAmountMap.get('Reinstall (Upgrade)'):null;
                    exp.Reinstall_Commercial__c = typeAmountMap.get('Reinstall Commercial')!=null?typeAmountMap.get('Reinstall Commercial'):null;
                    exp.Repair__c = typeAmountMap.get('Repair')!=null?typeAmountMap.get('Repair'):null;
                    exp.ODU_move__c = typeAmountMap.get('ODU move')!=null?typeAmountMap.get('ODU move'):null;
                    exp.Repair_Commercial__c = typeAmountMap.get('Repair Commercial')!=null?typeAmountMap.get('Repair Commercial'):null;
                    //exp.Trip_Fee__c = typeAmountMap.get('Trip Fees')!=null?typeAmountMap.get('Trip Fees'):null;
                    exp.Service_Resource__c = serviceResId[0]!=null?serviceResId[0]:null;
                }
            }
            
            //System.debug('totalAmount>>>>>>>>>'+totalAmount);
            System.debug('totalAmountMap>>>>>>'+typeAmountMap);
            System.debug('typeCategoryMap>>>>>'+typeCategoryMap);
        }
        catch(Exception ex) {
            ExceptionUtil.publishException('PV_ExceptionTriggerHandler.exceptionAfterInsert', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
}