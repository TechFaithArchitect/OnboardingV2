@IsTest
private class PV_SRCertificationStatusChangeBatchTest {
    @IsTest
    static void testBatchExecution() {
         System.runAs(new User(Id = Userinfo.getUserId()))
         {
            Account acct= PV_TestDataFactory.createAccount('pvTestAcc', true);
            contact con1 = PV_TestDataFactory.createContact('pvfirstAName1', 'pvlastAName_1',true,acct);
            contact con2 = PV_TestDataFactory.createContact('Test', 'pvFSLContact',true,acct);
            contact con3 = PV_TestDataFactory.createContact('pvfirstCName3', 'fslContact',true,acct);
            contact con4 = PV_TestDataFactory.createContact('fslContact', 'pvlastDName_4',true,acct);
          
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acct, pst);
            
            User usr1 = createTechUser(true,con1);
            User usr2 = createTechUser(true,con2);
    		User usr3 = createTechUser(true,con3);   
            User usr4 = createTechUser(true,con4); 
            
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr1, 'FSL_Technician');
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr2, 'FSL_Technician');
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr3, 'FSL_Technician');
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr4, 'FSL_Technician');
             
            ServiceResource sr1 = PV_TestDataFactory.createServiceResource(true,acct,con1,usr1);
            ServiceTerritoryMember stm1 = PV_TestDataFactory.createServiceTerritoryMember(true,sr1,childServiceTerritory,'P');            
            ServiceResource sr2 = PV_TestDataFactory.createServiceResource(true,acct,con2,usr2);
            ServiceTerritoryMember stm2 = PV_TestDataFactory.createServiceTerritoryMember(true,sr2,childServiceTerritory,'P');            
            ServiceResource sr3 = PV_TestDataFactory.createServiceResource(true,acct,con1,usr3);
            ServiceTerritoryMember stm3 = PV_TestDataFactory.createServiceTerritoryMember(true,sr3,childServiceTerritory,'P');            
            ServiceResource sr4 = PV_TestDataFactory.createServiceResource(true,acct,con2,usr4);
            ServiceTerritoryMember stm4 = PV_TestDataFactory.createServiceTerritoryMember(true,sr4,childServiceTerritory,'P');            
			sr1.Viasat_Expiration__c = Date.today();                         
            sr2.Viasat_Expiration__c = Date.today().addDays(60);                       
            sr3.DIRECTV_Expiration__c = Date.today(); 
            sr4.DIRECTV_Expiration__c =Date.today().addDays(60);          
            
            update sr1;
            update sr2;
            update sr3;
            update sr4;
         }
 
        Test.startTest();
        PV_SRCertificationStatusChangeBatch batch = new PV_SRCertificationStatusChangeBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Retrieve the updated ServiceResource records
        List<ServiceResource> updatedServiceResources = [SELECT Certification_Status_Viasat__c, Certification_Status_DIRECTV__c FROM ServiceResource];

        // Assert the expected values after batch execution
        // PROD-release05072025
        /*
        System.assertEquals('Expired', updatedServiceResources[0].Certification_Status_Viasat__c);
        System.assertEquals('Nearing Expiration', updatedServiceResources[1].Certification_Status_Viasat__c);
        System.assertEquals('Expired', updatedServiceResources[2].Certification_Status_DIRECTV__c);
        System.assertEquals('Nearing Expiration', updatedServiceResources[3].Certification_Status_DIRECTV__c);
        */
    }

    public static User createTechUser(Boolean doInsert, contact con){
       // Id userRoleId = [Select Id, DeveloperName From UserRole Where DeveloperName = 'UniversalUtilitySolutionsPartnerUser'].Id;
        Id ProfileId = [Select Id from profile where Name='#FS Service Resource (Partner Community)'].Id;
        User user = new User();
        user.FirstName = con.Id+'Test_';
        user.LastName = con.Id+'User';
        user.PortalRole = 'Manager';
    //   user.UserRoleId = userRoleId ;
        user.Email='test_user@gmail.com';
        user.Alias='tst';
        user.Username = con.Id+'test_user@gmail.com';
        user.CommunityNickname = con.Id+'tstuser';
        user.TimeZoneSidKey = 'America/Los_Angeles';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.PostalCode ='35401';
        user.ProfileId = ProfileId ;
        user.contactId = con.Id;
        if(doInsert) {
            insert user;
        }
        return user;       
    }    
}