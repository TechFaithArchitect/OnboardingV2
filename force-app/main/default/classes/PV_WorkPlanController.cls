/**
* @description       : Test Class PV_ServiceAppointmentTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 22-06-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
public with sharing class PV_WorkPlanController {
    @AuraEnabled(cacheable=true)
    public static List<Work_Plan__mdt> getWorkPlan(string workType){
        list<Work_Plan__mdt> workPlanList = [SELECT Id,Label, Work_Plan__c ,Order__c,Work_Type__c from Work_Plan__mdt 
                                             WHERE Work_Type__c LIKE :'%'+workType+'%' ORDER BY Order__c ] ;
        List<Work_Plan__mdt> workPlanToShow = new List<Work_Plan__mdt> ();
        for (Work_Plan__mdt workPlan : workPlanList){
            List<String> workTypeSplit = workPlan.Work_Type__c.split(',');
            if(workTypeSplit.contains(workType)){
                workPlanToShow.add(workPlan);
            }
        }
        system.debug('workPlanToShow---------->'+workPlanToShow.size());
        return workPlanToShow ;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static String getWorkPlanType(String recordId){
        List <ServiceAppointment> sa = [SELECT Id ,WorkType.Name  FROM  ServiceAppointment WHERE Id =:recordId];
        return sa[0].WorkType.Name;
        
    }
}