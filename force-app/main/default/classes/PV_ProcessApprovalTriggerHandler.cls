/**
* @description       : Class for Managing Service Resources
* @author            : Impaqtive DevTeam
* @last modified on  : 11-05-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            	   Modification
* 1.0   11/05/2023   Impaqtive DevTeam     Initial Version
**/

public class PV_ProcessApprovalTriggerHandler{
    
    public static void processApprovalCallToUpdateSR(List<Process_Approval__c> newRecords, Map<Id, Process_Approval__c> oldMap){
        List<Process_Approval__c> approvedRecords = new List<Process_Approval__c>();
        Map<Id, List<Shift>>  shiftsPerProcessApproval = new Map<Id, List<Shift>>();
        Set<Id> approvedIds = new Set<Id>();
        Id serviceRecordTypeId = Schema.SObjectType.Process_Approval__c.getRecordTypeInfosByDeveloperName().get('Service_Resource_Approval').getRecordTypeId();
          String imageURL='';
        for (Process_Approval__c pa : newRecords){
            if (pa.Status__c == 'Approved' && oldMap.get(pa.Id).Status__c != 'Approved' && pa.RecordTypeId == serviceRecordTypeId){
                approvedRecords.add(pa);
                approvedIds.add(pa.Id);
            }
        }

        for (Shift targetShift : [SELECT Id, StartTime, EndTime, TimeSlotType, ServiceTerritoryId, Process_Approval__c FROM Shift WHERE Process_Approval__c IN :approvedIds]){
            if(!shiftsPerProcessApproval.keySet().contains(targetShift.Process_Approval__c)){
                shiftsPerProcessApproval.put(targetShift.Process_Approval__c, new List<Shift>());
            }
            shiftsPerProcessApproval.get(targetShift.Process_Approval__c).add(targetShift);
        }
        if (!approvedRecords.isEmpty()){
            for (Process_Approval__c pa : approvedRecords){
                //PV_CreateSR.createPS(pa.Contact__c, pa.Resource_Type__c);
                Contact con = new Contact();
                con.FirstName = pa.First_Name__c;
                con.LastName = pa.Last_Name__c;
                con.ID_DirecTV__c = pa.ID_DirecTV__c;
                con.ID_Viasat__c = pa.ID_Viasat__c;
                con.Include_in_Scheduling_Optimization__c = pa.Include_in_Scheduling_Optimization__c;
                con.AccountId = pa.Account__c;
                con.Drug_Screen_Date__c = pa.Drug_Screen_Date__c;
                con.Background_Check_Date__c = pa.Background_Check_Date__c;
                con.Email = pa.Email__c;
                con.Phone = pa.Phone__c;
                con.Time_zone__c = pa.Time_Zone__c;
                con.Vendor_Type__c = pa.Vendor_Type__c;                
                con.Mailingstreet = pa.MailingStreet__c;
                con.Mailingcity = pa.MailingCity__c;
                con.MailingstateCode =  pa.MailingState__c;
                con.MailingpostalCode = pa.MailingPostalCode__c;
                con.MailingcountryCode = pa.MailingCountry__c;
                con.Resource_Type__c=pa.Resource_Type__c;
                con.Manager__c=pa.Manager__c;
                list<String> skillList = new list<String>();
                If(!String.isBlank(pa.Skill__c)){
                     skillList = pa.Skill__c.split(',');
                }
                String img;
                if(!Test.isRunningTest()){
                    if(pa.Resource_Image__c!=null){
                       imageURL=  pa.Resource_Image__c.substringBetween(' src="', '"' );
                	   img=imageURL.unescapeHtml4();  
                    }else{
                        img=null;
                    }
                    
                    String userTimeZone = UserInfo.getTimeZone().getID();
            		PV_ManageServiceResources.submitForApprovalOrSRCreation(con, pa.Resource_Type__c,pa.Service_memberships__c,skillList,pa.Skill_Start_Date__c,pa.Viasat_Expiration__c,pa.DIRECTV_Expiration__c,null,pa.id,img, shiftsPerProcessApproval.get(pa.id), ''); 
                }
              
            }
        }
    }
    
    public static void processApprovalCallToCreateLocation(List<Process_Approval__c> newRecordsPA, Map<Id,Process_Approval__c> oldMapPA){
        try{
            List<Process_Approval__c> paRecords = new List<Process_Approval__c>();
            Id locationRecordTypeId = Schema.SObjectType.Process_Approval__c.getRecordTypeInfosByDeveloperName().get('Location_Approval').getRecordTypeId();
            for(Process_Approval__c pa : newRecordsPA){
                if(pa.Status__c == 'Approved' && oldMapPA.get(pa.Id).Status__c != pa.Status__c  && pa.RecordTypeId == locationRecordTypeId){
                    paRecords.add(pa);
                }
            }
            if(!paRecords.isEmpty()){
                List<Schema.Location> locList = new List<Schema.Location>();
                for(Process_Approval__c pa : paRecords){
                    Schema.Location loct = new Schema.Location();
                    loct.Name = pa.Location_Name__c;
                    loct.LocationType = pa.Location_Type__c;
                    loct.IsInventoryLocation = pa.Inventory_Location__c;
                    loct.Account__c = pa.Account__c;
                    loct.IsMobile = pa.Mobile_Location__c;
                    loct.Service_Resource__c = pa.Service_Resource__c;
                    locList.add(loct);
                }
                insert locList;
            }
        }
        catch(Exception ex){
            ExceptionUtil.publishException('PV_ProcessApprovalTriggerHandler.processApprovalCallToCreateLocation', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }

}