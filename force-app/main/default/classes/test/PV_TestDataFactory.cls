@isTest 
public class PV_TestDataFactory {
    
    static String DirecTV = Label.DIRECTV;
    public static Account createAccount(String name, Boolean doInsert) {
        Account acc = new Account();
        acc.Name = name;
        acc.POE_Dealer_Code__c = 'D01';
        acc.Available_FSL_Vendors__c = 'DIRECTV';
        if(doInsert) {
            insert acc;
        }
        return acc;
    }
    public static Contact createContact(String firstName,String lastName, Boolean doInsert,Account acc) {
        Contact con = new Contact();
        con.FirstName=firstName;
        con.LastName = lastName;
        con.AccountId = acc.Id;
        con.Email = lastName+'@yopmail.com';
        con.Time_zone__c = 'America/New_York';
        con.MailingPostalCode = '672001';
        con.MailingCity='city 1';
        con.MailingStreet='streetTest';
            con.MailingCountry='United States';
            con.MailingState='Texas';
        if(doInsert) {
            insert con;
        }
        return con;
    }

    public static OperatingHours createOperatingHours(String Name,Boolean doInsert){
        TimeZone tz = UserInfo.getTimeZone();
        OperatingHours opHrs = new OperatingHours();
        opHrs.Name = Name;
        if(doInsert) {
            insert opHrs;
        }
        return opHrs;   
    }

    public static WorkType createWorkType(String Name,Boolean doInsert){
        WorkType wt = new WorkType();
        wt.Name = Name ;
        wt.EstimatedDuration = 60.00;
        wt.ShouldAutoCreateSvcAppt = TRUE ;
        if(doInsert) {
            insert wt;
        }
        return wt;
    }

    public static WorkOrder createWorkOrder(User usr, WorkType wt,Boolean doInsert){
        WorkOrder wo = new WorkOrder();
        wo.Status = 'Unscheduled';
        wo.OwnerId = usr.Id;
        wo.WorkTypeId = wt.Id;
        wo.Vendor__c = DirecTV;
        if(doInsert) {
            insert wo;
        }
        return wo;
    }
    
    public static ServiceTerritory createParentServiceTerritory(Boolean doInsert,String Name, OperatingHours opHrs){
        ServiceTerritory pst = new ServiceTerritory();
        pst.Name = Name;
        pst.OperatingHoursId = opHrs.Id;
        pst.IsActive =TRUE;
        if(doInsert) {
            insert pst;
        }
        return pst;
    }

    public static ServiceTerritory createServiceTerritoryForAccount(Boolean doInsert,Account acc, ServiceTerritory parentServiceTerritory){
        ServiceTerritory st = new ServiceTerritory();
        st.Name = acc.Name+'-'+parentServiceTerritory.Name;
        st.ParentTerritoryId = parentServiceTerritory.Id;
        st.Account__c = acc.Id;
        st.OperatingHoursId = parentServiceTerritory.OperatingHoursId;
        st.IsActive =TRUE;
        if(doInsert) {
            insert st;
        }
        return st;
    }

    public static User createTechnicianUser(Boolean doInsert, contact con) {
        Id ProfileId = [Select Id from profile where Name='#FS Service Resource (Partner Community)'].Id;
        User user = new User();
        user.FirstName = 'Test_';
        user.LastName = 'User';
        user.PortalRole = 'Manager';
        user.Email = 'PV_TestDataFactory' + DateTime.now().getTime() + '@hikko.com';
        user.Alias = 'tst';
        user.Username = 'PV_TestDataFactory' + DateTime.now().getTime() + '@hikko.com';
        user.CommunityNickname = 'tstuser';
        user.TimeZoneSidKey = 'America/Los_Angeles';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.PostalCode ='35401';
        user.ProfileId = ProfileId ;
        user.contactId = con.Id;
        if (doInsert) {
            insert user;
        }
        return user;
    }

    public static permissionSetAssignment assignPermissionSetGroupToUser(Boolean doInsert, User usr,String permissionSetGrpName) {
        Id permissionSetGroupId = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName = :permissionSetGrpName].Id;
        
        // Create a new PermissionSetAssignment record
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
        permissionSetAssignment.AssigneeId = usr.Id;
        permissionSetAssignment.PermissionSetGroupId = permissionSetGroupId;
        
        // Insert the PermissionSetAssignment record
        
        if(doInsert) {
            Test.calculatePermissionSetGroup(permissionSetGroupId);
            insert permissionSetAssignment;
        }
        return permissionSetAssignment;
    }
    public static ServiceResource createServiceResource(Boolean doInsert,Account acc, contact con,User usr){
        ServiceResource sr= new ServiceResource();
        sr.Name = con.LastName;
        sr.IsActive = TRUE;
        sr.RelatedRecordId =usr.Id;
        sr.Contact__c = con.Id;
        sr.AccountId = acc.Id;
        sr.ResourceType = 'T';
        if(doInsert) {
            insert sr;
        }
        return sr;
    }

    public static ServiceTerritoryMember createServiceTerritoryMember(Boolean doInsert,ServiceResource sr, ServiceTerritory str,String territoryType){
        ServiceTerritoryMember stm = new ServiceTerritoryMember();
        stm.ServiceResourceId = sr.Id;
        stm.ServiceTerritoryId = str.Id;
        stm.TerritoryType = territoryType;
        if(territoryType =='P'){
            stm.PostalCode = '35401';
        }
        stm.EffectiveStartDate =System.today();
        if(doInsert) {
            insert stm;
        }
        return stm;
    }

    public static Product2 createProduct(Boolean doInsert,boolean isSerialized,String productName){
        Product2 prd  = new Product2();
        prd.Name = productName;
        prd.IsSerialized = isSerialized;
        prd.IsActive  = true;
        prd.Family = 'DirecTV';
        prd.FSL_Product__c = true;
        prd.FSL_Vendor__c = 'DIRECTV';
        if(doInsert) {
            insert prd;
        }
        return prd;
    }
}