@isTest
public class PV_ManageServiceResourcesTest {
    
    @testSetup
    static void setupMethod(){
        Permission_Set_Assignment__mdt Permissions = [
            SELECT  Permission_Sets__c, Profile__c, Resource_Type__c 
            FROM    Permission_Set_Assignment__mdt 
            WHERE Resource_Type__c = 'Dispatcher' LIMIT 1
        ];

        Account acc01 = new Account();
        acc01.Name = 'A01';
        insert acc01;
        
        Contact con01 = new Contact();
        con01.FirstName='Casdfdafas0';
        con01.LastName = '12dafdafadf2';
        con01.AccountId = acc01.Id;
        con01.Email = 'consd0asddaf1@yopmail.com';
        con01.MailingCity='test';
        con01.MailingCountry='United States';
        con01.MailingState='Texas';
        con01.MailingStreet='test';
        con01.MailingPostalCode='659855';
        con01.Resource_Type__c = 'Dispatcher';
        con01.Status__c = 'Active';
        insert con01;
        
        Contact con02 = new Contact();
        con02.FirstName='Csadfdafd00';
        con02.LastName = '1sasfdadsfds';
        con02.AccountId = acc01.Id;
        con02.Email = 'con001@yopmail.com';
        con02.MailingCity='test';
        con02.MailingCountry='United States';
        con02.MailingState='Texas';
        con02.MailingStreet='test';
        con02.MailingPostalCode='659855';
        insert con02;
        
        Process_Approval__c pa01 = new Process_Approval__c();
        pa01.Status__c = 'Approved';
        pa01.Resource_Type__c = 'Technician';
        insert pa01;
        
        TimeZone tz = UserInfo.getTimeZone();
        OperatingHours OP01 = new OperatingHours();
        OP01.Name = 'East - Mon-Fri 8am - 5pm';
        OP01.TimeZone = tz.getID();
        insert OP01;

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

        User u = new User();
        u.FirstName = con02.FirstName;
        u.LastName = con02.LastName;
        u.Email = con02.Email;
        u.Username = con02.Email+System.Label.username_prefix;
        u.CommunityNickname = con02.FirstName + con02.LastName+'nick';
        u.ProfileId = [SELECT Id FROM Profile WHERE Name=:Permissions.Profile__c LIMIT 1].Id;
        u.Alias = con02.FirstName.substring(0, 1) + con02.LastName.substring(0, 1);
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.ContactId=con02.id;                  
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        insert u;
    }
    
    @isTest
    static void getContactsTest(){
        Account ac = [SELECT Id FROM Account WHERE Name = 'A01'];
        Test.startTest();
        List<Contact> contacts = PV_ManageServiceResources.getRelatedContacts(ac.Id);
        Test.stopTest();
        System.assertEquals(false, contacts.isEmpty());
    }

    @isTest
    static void getPickValues(){
        Test.startTest();
        List<String> values = PV_ManageServiceResources.getPickValues();
        Test.stopTest();
        System.assertEquals(false,values.isEmpty());
    }
    
    @isTest
    static void getskill(){
        Test.startTest();
        List<String> values = new List<String>();
        values.add('test');
        List<Skill> skills = PV_ManageServiceResources.getskill(values);
        Test.stopTest();
        System.assertEquals(true,skills.isEmpty());
    }
    
    @isTest
    static void getTimzonePickListValues(){
        Test.startTest();
        List<String> values = PV_ManageServiceResources.getTimzonePickListValues();
        Test.stopTest();
        System.assertEquals(false,values.isEmpty());
    }
    
    @isTest
    static void getValues(){
        Account acc = [Select Id from Account where Name = 'A01'];
        Test.startTest();
        List<String> values = PV_ManageServiceResources.getValues('ServiceResource','Vendor__c', acc.Id);
        Test.stopTest();
        System.assertEquals(false,values.isEmpty());
    }
    
    @isTest
    static void getManager(){
        Account a = [select id from Account where Name = 'A01' limit 1];
        Test.startTest();
        List<User> users = PV_ManageServiceResources.getManager(a.Id);
        Test.stopTest();
        System.assertEquals(true,users.isEmpty());
    }
    
    @isTest
    static void validateContact(){
        Account acc = PV_TestDataFactory.createAccount('Test ABC', true);
        PV_ManageServiceResources.contactWrapper cont =new PV_ManageServiceResources.contactWrapper();
        cont.FirstName ='cont';
        cont.LastName ='cont';
        cont.Account =acc.id;
        cont.Timezone ='cont';
        //cont.Email ='cont@ff.com';
        cont.Email = 'usersdsdsd'+'@yopmail.com';
        cont.Phone ='98558855';
        cont.DrugScreenDate =String.valueOf(Date.today());
        cont.BackgroundCheckDate =String.valueOf(Date.today());
        cont.IncludeinSchedulingOptimization='false';
        cont.MailingStreet ='cont';
        cont.MailingCity ='cont';
        cont.MailingStateCode ='NY';
        cont.IDDirecTV ='cont';
        cont.IDViasat ='cont';
        cont.Vendor ='DIRECTV;Viasat';
        PV_ManageServiceResources.validateContact(JSON.serialize(cont),'Technician',Date.today(),Date.today());
        
        PV_ManageServiceResources.contactWrapper cont1 =new PV_ManageServiceResources.contactWrapper();
        cont1.FirstName ='cont1';
        cont1.LastName ='cont1';
        cont1.Account =acc.id;
        cont1.Timezone ='cont1';
        cont1.Email ='cont1@ff.com';
        cont1.Phone ='98558855';
        cont1.DrugScreenDate =String.valueOf(Date.today());
        cont1.BackgroundCheckDate =String.valueOf(Date.today());
        cont1.IncludeinSchedulingOptimization='false';
        cont1.MailingStreet ='cont1';
        cont1.MailingCity ='cont1';
        cont1.MailingStateCode ='NY';
        cont1.IDDirecTV = null;
        cont1.Vendor ='DIRECTV';

        try {
            PV_ManageServiceResources.validateContact(JSON.serialize(cont1),'Technician',null,null);  
        } catch(Exception e){
            Assert.isNotNull(e);
        }
        
        PV_ManageServiceResources.contactWrapper cont2 =new PV_ManageServiceResources.contactWrapper();
        cont2.FirstName ='cont2';
        cont2.LastName ='cont2';
        cont2.Account =acc.id;
        cont2.Timezone ='cont2';
        cont2.Email ='cont2@ff.com';
        cont2.Phone ='98558855';
        cont2.DrugScreenDate =String.valueOf(Date.today());
        cont2.BackgroundCheckDate =String.valueOf(Date.today());
        cont2.IncludeinSchedulingOptimization='false';
        cont2.MailingStreet ='cont2';
        cont2.MailingCity ='cont2';
        cont2.MailingStateCode ='NY';
        cont2.IDDirecTV = null;
        cont2.IDViasat = null;
        cont2.Vendor ='DIRECTV;Viasat';

        try {
            PV_ManageServiceResources.validateContact(JSON.serialize(cont2),'Technician',Date.today(),Date.today());  
        } catch(Exception e){
            Assert.isNotNull(e);
        }
        
        PV_ManageServiceResources.contactWrapper cont3 =new PV_ManageServiceResources.contactWrapper();
        cont3.FirstName ='cont3';
        cont3.LastName ='cont3';
        cont3.Account =acc.id;
        cont3.Timezone ='cont3';
        cont3.Email ='cont3@ff.com';
        cont3.Phone ='98558855';
        cont3.DrugScreenDate =String.valueOf(Date.today());
        cont3.BackgroundCheckDate =String.valueOf(Date.today());
        cont3.IncludeinSchedulingOptimization='false';
        cont3.MailingStreet ='cont3';
        cont3.MailingCity ='cont3';
        cont3.MailingStateCode ='NY';
        cont3.IDDirecTV = 'cont';
        cont3.IDViasat = 'cont';
        cont3.Vendor = 'DIRECTV;Viasat';
        try{
            PV_ManageServiceResources.validateContact(JSON.serialize(cont3),'Technician',null,null);  
        }catch(Exception e){
            Assert.isNotNull(e);
        }
    }
    
    @isTest
    static void submitForApprovalOrSRCreation(){
        Account acc = PV_TestDataFactory.createAccount('Test ABC', true);
        Contact con = PV_TestDataFactory.createContact('testassd', 'usersdsdsd', false, acc);
        con.MailingCity='test';
        con.MailingCountry='United States';
        con.MailingState='Virginia';
        con.MailingStreet='test';
        con.MailingPostalCode='12006';
        Contact Techcon = PV_TestDataFactory.createContact('Techcon', 'Techcon2', false, acc);
        con.MailingCity='test';
        con.MailingCountry='United States';
        con.MailingState='Alaska';
        con.MailingStreet='test';
        con.MailingPostalCode='12006';
        list<PV_ManageServiceResources.ServiceTerritoryMembership> stm= new  list<PV_ManageServiceResources.ServiceTerritoryMembership>();
        PV_ManageServiceResources.ServiceTerritoryMembership st1=new PV_ManageServiceResources.ServiceTerritoryMembership();
        st1.StartDate=String.valueOf(Date.today());
        st1.TerritoryId=[Select Id from ServiceTerritory where Name = 'T01'].id;
        st1.TerritoryType='Primary';
        stm.add(st1);
        List<String> skillList = new List<String>();
        Date startDate = Date.today();
        skillList.add([Select MasterLabel, DeveloperName from Skill limit 1].DeveloperName);
        Map<String, String> obj = new Map<String, String>();
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeNumberField('IndexId', 0);
        gen.writeStringField('StartDate',  st1.StartDate);
        gen.writeStringField('TerritoryId',  st1.TerritoryId);
        gen.writeStringField('TerritoryType', st1.TerritoryType);
        gen.writeEndObject();  
        gen.writeEndArray();
        String Jsonstring = gen.getAsString();
        system.debug('Jsonstring'+Jsonstring);
        
        Contact con3 = new Contact();
        con3.FirstName='testassd';
        con3.LastName = 'usersdsdsd';
        con3.AccountId = acc.Id;
        con3.Email = 'usersdsdsd'+'@yopmail.com';
        con3.MailingPostalCode = '672001';
        con3.MailingCity='city 1';
        con3.MailingStreet='streetTest';
        con3.MailingCountry='United States';
        con3.MailingState='Texas';
        insert con3;

        FSL_Settings__c settings = new FSL_Settings__c(
            Shifts_First_Day_of_the_Week__c = 1,
            Shift_Weeks_In_Advance__c = 4
        );
        insert settings;

        Shift testShift = new Shift();
        testShift.startTime = Datetime.now().addDays(1);
        testShift.EndTime = Datetime.now().addDays(2);
        testShift.TimeSlotType =  'Normal';
        testShift.ServiceTerritoryId = [Select Id from ServiceTerritory where Name = 'T01'].id;

        List<Shift> testShifts = new List<Shift>();
        testShifts.add(testShift);


             
        Test.startTest();
        /*PV_ManageServiceResources.submitForApprovalOrSRCreation(con4,'Dispatcher',Jsonstring,skillList,startDate,Date.today(),Date.today(),null,null,null);
        //PV_ManageServiceResources.submitForApprovalOrSRCreation(con3,'Dispatcher',Jsonstring,skillList,startDate,Date.today(),Date.today(),null,null,null, null, 'America/Montevideo');
        //PV_ManageServiceResources.submitForApprovalOrSRCreation(Techcon,'Technician',Jsonstring,skillList,startDate,Date.today(),Date.today(),null,null,null, null, 'America/Montevideo');
        try{
            PV_ManageServiceResources.submitForApprovalOrSRCreation(Techcon,null,Jsonstring,skillList,startDate,Date.today(),Date.today(),null,null,null, testShifts, 'America/Montevideo'); 
        }catch(Exception e){
            Assert.isNotNull(e);
        }

        User u=[select id from User where  FirstName='testassd' limit 1];
        User Techu=[select id from User where  FirstName='Techcon' limit 1];
        //system.assertNotEquals(null, u) ;
        System.enqueueJob(new PV_CreateSRandSTMQueueable(u,'Technician',con,stm,skillList,startDate,Date.today(),Date.today(),null, testShifts, 'America/Montevideo'));
        /*System.runAs(u){
            
            PV_ManageServiceResources.submitForApprovalOrSRCreation(con,'Technician',Jsonstring,skillList,startDate,Date.today(),Date.today(),null,null,null, testShifts, 'America/Montevideo');
            
        }*/
        
        Test.stopTest();
    }
    @isTest
    static void validateEmail(){
        
        Account acc = PV_TestDataFactory.createAccount('Test ABC', true);
        Contact con = new Contact();
        con.FirstName='testassd';
        con.LastName = 'usersdsdsd';
        con.AccountId = acc.Id;
        con.Email = 'usersdsdsd'+'@yopmail.com';
        con.Time_zone__c = 'America/New_York';
        con.MailingPostalCode = '672001';
        con.MailingCity='city 1';
        con.MailingStreet='streetTest';
        con.MailingCountry='United States';
        con.MailingState='Texas';
        insert con;
        PV_ManageServiceResources.validateEmail('usersdsdsd@yopmail.com',acc.Id,'Technician');
        PV_ManageServiceResources.validatePermission();
        
    }
     @isTest
    static void validateEmail2(){
        
        Account acc = PV_TestDataFactory.createAccount('Test ABC', true);
        Account acc1 = PV_TestDataFactory.createAccount('Test ABC2', true);
        Contact con = new Contact();
        con.FirstName='testassd';
        con.LastName = 'usersdsdsd';
        con.AccountId = acc.Id;
        con.Email = 'usersdsdsd'+'@yopmail.com';
        con.Time_zone__c = 'America/New_York';
        con.MailingPostalCode = '672001';
        con.MailingCity='city 1';
        con.MailingStreet='streetTest';
        con.MailingCountry='United States';
        con.MailingState='Texas';
        insert con;
        PV_ManageServiceResources.validateEmail('usersdsdsd@yopmail.com',acc1.Id,'Technician');
        PV_ManageServiceResources.validateDispatcher('usersdsdsd@yopmail.com');
        PV_ManageServiceResources.getServiceTerritories(acc.id,'test');  
    }   
}