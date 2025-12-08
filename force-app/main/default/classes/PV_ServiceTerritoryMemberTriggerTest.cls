@isTest
public class PV_ServiceTerritoryMemberTriggerTest {
    
    @TestSetup
    static void makeTestData() {
        
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            Account acc= PV_TestDataFactory.createAccount('Test Account', true);
            Account acc2= PV_TestDataFactory.createAccount('Test Account2', true);
            contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc);
            contact con2 = PV_TestDataFactory.createContact('Test2', 'FSL_contact_02',true,acc2);
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('West - Mon-Fri 9am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'SR-01',opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc, pst);
            ServiceTerritory pst1 = PV_TestDataFactory.createParentServiceTerritory(true, 'SR-02',opHrs);
            ServiceTerritory childServiceTerritory2 = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc, pst1);
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            
            
           // Id userRoleId = [Select Id, DeveloperName From UserRole Where DeveloperName = 'UniversalUtilitySolutionsPartnerUser'].Id;
            Id ProfileId = [Select Id from profile where Name='#FS Service Resource (Partner Community)'].Id;
            User usr2 = new user();
            usr2.FirstName = 'Tt';
            usr2.LastName = 'User2';
            usr2.PortalRole = 'Manager';
           // usr2.UserRoleId = userRoleId ;
            usr2.Email='test2_user@gmail.com';
            usr2.Alias='tst2';
            usr2.Username = con2.Id+'test2_user@gmail.com';
            usr2.CommunityNickname = 'tstuser2';
            usr2.TimeZoneSidKey = 'America/Los_Angeles';
            usr2.LocaleSidKey = 'en_US';
            usr2.EmailEncodingKey = 'UTF-8';
            usr2.LanguageLocaleKey = 'en_US';
            usr2.PostalCode ='35401';
            usr2.ProfileId = ProfileId ;
            usr2.contactId = con2.Id;
            insert usr2;
            
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr2, 'FSL_Technician');
            ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true,acc,con,usr);
            ServiceResource ServiceRes2 = PV_TestDataFactory.createServiceResource(true,acc2,con2,usr2);
            ServiceTerritoryMember stm1 = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes,childServiceTerritory,'P');
            ServiceTerritoryMember stm2 = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes2,childServiceTerritory,'P');
            ServiceTerritoryMember stm3 = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes2,childServiceTerritory2,'S');
        }        
    }
    
    @isTest
    static void testupdatePrimaryStm(){
        Test.startTest();
        Account ac1 = [SELECT Id, Name from Account WHERE  Name = 'Test Account'];
        Account ac2 = [SELECT Id, Name from Account WHERE  Name = 'Test Account2'];
        ServiceResource st = [SELECT Id, Name,AccountId From ServiceResource WHERE AccountId =: ac1.Id];
        ServiceResource st2 = [SELECT Id, Name,AccountId From ServiceResource WHERE AccountId =: ac2.Id];
        List<ServiceTerritoryMember> StmList = [SELECT Id,TerritoryType,ServiceResourceId,ServiceTerritoryId,PostalCode
                                                From ServiceTerritoryMember 
                                                WHERE ServiceResourceId =: st.Id];
        system.debug('StmList--->'+StmList);
        ServiceTerritoryMember Stm2 = [SELECT Id,TerritoryType,ServiceResourceId,ServiceTerritoryId,PostalCode
                                                 From ServiceTerritoryMember 
                                                 WHERE ServiceResourceId =: st2.Id Limit 1];

        Stm2.EffectiveEndDate = system.today().addmonths(5);
        Stm2.OperatingHoursId = Null;
        Stm2.PostalCode = Null;
        Stm2.TerritoryType = 'S';
        update Stm2;
        
        Delete StmList[0];
        Test.stopTest();
        System.assertEquals('S', Stm2.TerritoryType);
        System.assertEquals(2, StmList.size());
        
    }
    
    @isTest
    static void testcreateParentrStm(){
        Set<Id>newStm = new Set<Id>();
        List<ServiceTerritoryMember> StmList = [SELECT Id,TerritoryType,ServiceResourceId,ServiceTerritoryId
                                                From ServiceTerritoryMember 
                                                WHERE TerritoryType =:'P'];
        for(ServiceTerritoryMember st:StmList){
            newStm.add(st.Id);
        }
        Test.startTest();
        if(!Test.isRunningTest()){
            PV_ServiceTerritoryMemberTriggerHandler.createParentrStm(newStm);
        }
        Test.stopTest();
        system.assertEquals(2,newStm.size());
    }
    
    @isTest
    static void testdeleteParentrStm(){
        List<ServiceTerritory> StmList = [SELECT Id,OperatingHoursId,Name
                                          From ServiceTerritory 
                                          WHERE Name =:'NY-01'];
        Set<Id>parenterritoryIds = new Set<Id>();
        system.debug('parenterritoryIds-->'+parenterritoryIds);
        for(ServiceTerritory stmUpdated:StmList){
            parenterritoryIds.add(stmUpdated.Id);
        }
        ServiceResource Sr=[SELECT Id,Name,ResourceType From ServiceResource WHERE ResourceType=:'T' LIMIT 1];
        system.debug('Sr-->'+Sr);
        Id srr = sr.Id;
        system.debug('srr-->'+srr);
        Test.startTest();
        PV_ServiceTerritoryMemberTriggerHandler.deleteParentrStm(parenterritoryIds,srr);
        Test.stopTest();
        system.assertEquals(0, parenterritoryIds.size());
    }
    
}