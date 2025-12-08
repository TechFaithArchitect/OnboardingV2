/**
* @description       : Service methods for Assign Service Territory
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 16-05-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
public class PV_ServiceResourceMultiSelectLookupCtrl {
    
    //Method to Search Matching Parent Service Territory 
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getResults(String ObjectName, String fieldName, String value, List<String> selectedRecId) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        if(selectedRecId == null)
            selectedRecId = new List<String>();
        
        if(String.isNotEmpty(value)) {
            String query = 'Select Id,'+fieldName+' FROM '+ObjectName+' WHERE '+fieldName+' LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId AND ParentTerritoryId = Null AND IsActive = True';
            for(sObject so : Database.Query(query)) {
                String fieldvalue = (String)so.get(fieldName);
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
            }
        }
        return sObjectResultList;
    }
    
    public class SObjectResult {
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;
        
        public SObJectResult(String recNameTemp, Id recIdTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
        }
        
    }
    
    //Method for Child Service Territory Creation    
    @AuraEnabled
    public static String insertServiceTerritory(String acc, List<Id> serviceTry) {      
        List<ServiceTerritory> strList = [Select Id, Name, OperatingHoursId from ServiceTerritory where Id IN: serviceTry];
        Account acct = [Select Id, Name, POE_Dealer_Code__c from Account where Id =: acc];
        List<ServiceTerritory> newStr = new List<ServiceTerritory>();
        Map<String, Id> dupList= new Map<String, Id>();
        
        //for(ServiceTerritory st: [SELECT Id, Name, OperatingHoursId, Account__c from ServiceTerritory where Account__c =: acct.Id]){
         for(ServiceTerritory st: [SELECT Id, Name, OperatingHoursId, Account__c from ServiceTerritory where Name LIKE :'%'+acct.POE_Dealer_Code__c+'%']){
            dupList.put(st.name, st.Id);
        }
        
        for(ServiceTerritory st: strList){
            if(dupList.containsKey(acct.POE_Dealer_Code__c +' - '+ st.Name )){
                throw new AuraHandledException(st.Name +': Duplicate Service Territory identified');
            }
            ServiceTerritory str = new ServiceTerritory();
            str.Name = acct.POE_Dealer_Code__c +' - '+ st.Name ;
            str.Account__c = acct.Id;
            str.OperatingHoursId = st.OperatingHoursId;
            str.ParentTerritoryId = st.Id;
            str.IsActive = true;
            newStr.add(str);   
        }
        insert newStr;
        return 'Created';
    }
    
}