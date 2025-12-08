/**
* @description       : Test code for PV_ServiceResourceMultiSelectLookupCtrl
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 08-05-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
@isTest
public class PV_ServiceResourceMultiSelectLookupTest {
    
    @testSetup
    static void setupMethod(){
        TimeZone tz = UserInfo.getTimeZone();
        OperatingHours OP01 = new OperatingHours();
        OP01.Name = 'East - Mon-Fri 8am - 5pm';
        insert OP01;
        
        Account acc01 = new Account();
        acc01.Name = 'A01';
        acc01.POE_Dealer_Code__c = 'D01';
        insert acc01;
        
        ServiceTerritory ST01 = new ServiceTerritory();
        ST01.Name = 'T01';
        ST01.Account__c = acc01.Id;
        ST01.OperatingHoursId = OP01.Id;
        ST01.IsActive =TRUE;
        insert ST01;
                
        ServiceTerritory ST02 = new ServiceTerritory();
        ST02.Name = 'T02';
        ST02.Account__c = acc01.Id;
        ST02.OperatingHoursId = OP01.Id;
        ST02.IsActive =TRUE;
        insert ST02;
       
    }
    
    @isTest
    static void getResultsTest(){
        List<String> selectedRecId = null;
        List<String> StIds = new List<String>();
        Test.startTest();
        PV_ServiceResourceMultiSelectLookupCtrl.getResults('ServiceTerritory','Name','T',StIds);
        PV_ServiceResourceMultiSelectLookupCtrl.getResults('ServiceTerritory','Name','T',selectedRecId);
        Test.stopTest();
       System.assertEquals(0,StIds.size());
    }
    
    @isTest
    static void insertServiceTerritoryTest(){
        Account acc = [SELECT Id,Name,POE_Dealer_Code__c  FROM Account WHERE Name ='A01'];
        List <ServiceTerritory> STlist = [SELECT Id,Name,ParentTerritoryId,OperatingHoursId,IsActive,Account__c 
                                          FROM ServiceTerritory 
                                          WHERE Account__c =: acc.Id];
        
        List <Id> StIds = new List<Id>();
        for(ServiceTerritory str: STlist){
            StIds.add(str.Id);
        }
        String accId = String.valueOf(acc.Id);
        Test.startTest();
        PV_ServiceResourceMultiSelectLookupCtrl.insertServiceTerritory(accId, StIds) ;    
        Test.stopTest();
        
        List<ServiceTerritory> newSTlist = [SELECT Id,Name,ParentTerritoryId,OperatingHoursId,IsActive,Account__c 
                                          FROM ServiceTerritory 
                                          WHERE Account__c =: acc.Id AND ParentTerritoryId IN :StIds];
        System.assertEquals(2, newSTlist.size());
        
    }
    
}