/**
* @description       :Controller  Class for audit screen
* @author            : Impaqtive DevTeam
* @last modified on  : 07-24-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
* Ver   Date         Author            	   Modification
* 1.0   03/07/2023   Impaqtive DevTeam     Initial Version
**/
public without sharing class PV_AuditController {
    
    //Method for completed audit record
    @AuraEnabled(cacheable=true)
    public static boolean getCompletedAudit(String workOrderId) {
        
        system.debug('workOrderId'+workOrderId);
        try{        
            String userProfile=[SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1].Name;
            List<string> readProfiles = PV_FSL_Config__mdt.getInstance('Audit_Read_access').Value__c.split(',');
            boolean py = true;
            system.debug(readProfiles);
            List<Audit__c> auditList=[select id,
                                      Audit_Result__c from Audit__c 
                                      where Work_Order__c=:workOrderId AND Audit_Result__c != NULL 
                                      order by CreatedDate desc limit 1];
            
            List<ServiceAppointment> appointmentList=[select id,
                                      Status from ServiceAppointment 
                                      where Status='Complete' AND ParentRecordId =:workOrderId
                                      order by CreatedDate desc limit 1];


            if(appointmentList.isEmpty()){
                return false;
            }
            
            if((readProfiles.contains(userProfile)) &&(auditList.isEmpty())){

                     py= false;              
            }
            return py; 
            
        }catch (Exception ex) {
            ExceptionUtil.publishException('PV_AuditController.getCompletedAudit', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //Method for related audit record
    @AuraEnabled(cacheable=true)
    public static Payload getAudit(String workOrderId) {
        
        try{        
            String userProfile=[SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1].Name;
            List<string> EditRequiredProfiles = PV_FSL_Config__mdt.getInstance('Audit_Edit_access').Value__c.split(',');
            Payload py;
            List<Audit__c> auditList=[select id,
                                      On_Site__c,
                                      Virtual__c,
                                      Roof__c,
                                      Stubby__c,
                                      Round_Pole__c,
                                      S_Mount__c,
                                      Non_Pen__c,
                                      Hex_Pole__c,
                                      Undereave__c,
                                      Approved_Mount__c,
                                      Wall__c,
                                      All_Required_Photos__c,
                                      Quality_Follow_Up_Needed__c,
                                      Antenna_Pointing__c,
                                      Equipment_Cable_ODU__c,
                                      Line_of_Sight_10__c,
                                      ODU_Mount_Hardware__c,
                                      Approved_Cabling_Aesthetics__c,
                                      System_Grounded_to_NEC_Ground_Source__c,
                                      Pre_Install_Customer_Experience__c,
                                      Site_Survey__c,
                                      Antenna_Assembly__c,
                                      Antenna_Mount__c,
                                      Cable_Routing__c,
                                      System_Grounded__c,
                                      Point_Peak__c,
                                      System_Provisioned__c,
                                      Post_Install_Customer_Experience__c,
                                      Audit_Result__c from Audit__c where Work_Order__c=:workOrderId order by CreatedDate desc limit 1];
            
            
            
            if(EditRequiredProfiles.contains(userProfile)){
                
                py=new Payload(auditList,true);
                
            }else{
                py=new Payload(auditList,false);
            }
            return py; 
            
        }catch (Exception ex) {
            ExceptionUtil.publishException('PV_AuditController', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //Method to update audit record
    @AuraEnabled
    public static void updateAudit(Audit__c auditrecord) {
        try{
            update auditrecord;
            
        }catch (Exception ex) {
            ExceptionUtil.publishException('PV_AuditController', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //Method to return audit options
    @AuraEnabled
    public static List<PicklistOptions> auditOptions() {
        
        List<PicklistOptions> auditOptions=new List<PicklistOptions>();
        List<string> auditOptionList = PV_FSL_Config__mdt.getInstance('Audit_options').Value__c.split(',');
        for(String Soption:auditOptionList){
            PicklistOptions option=new PicklistOptions();
            option.value=option.label=Soption;
            auditOptions.add(option);
        }
        
        return auditOptions;
        
    }
    //Method to return quality Options
    @AuraEnabled
    public static List<PicklistOptions> qualityOptions() {
        
        List<PicklistOptions> auditOptions=new List<PicklistOptions>();
        List<string> auditOptionList = PV_FSL_Config__mdt.getInstance('Audit_qualityFollwup_options').Value__c.split(',');
        for(String Soption:auditOptionList){
            PicklistOptions option=new PicklistOptions();
            option.value=option.label=Soption;
            auditOptions.add(option);
        }
        
        return auditOptions;
        
    }
    //Method to return audit Result
    @AuraEnabled
    public static List<PicklistOptions> auditResult() {
        
        List<PicklistOptions> auditOptions=new List<PicklistOptions>();
        List<string> auditOptionList = PV_FSL_Config__mdt.getInstance('Audit_results').Value__c.split(',');
        for(String Soption:auditOptionList){
            PicklistOptions option=new PicklistOptions();
            option.value=option.label=Soption;
            auditOptions.add(option);
        }
        
        return auditOptions;
        
    }
    
    public class Payload{
        
        @AuraEnabled public List<Audit__c> auditList;
        @AuraEnabled public Boolean IsEditAccess;
        
        public  Payload(List<Audit__c> auditList,Boolean Isedit){
            
            this.auditList=auditList;
            this.IsEditAccess=Isedit;
        }
        
    }
    
    public class PicklistOptions{
        
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        
    }
    
}