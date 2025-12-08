@isTest
public class PV_InventroyDetailsControllerTest {
    @TestSetup
    static void makeTestData() {
        
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            Account acc= PV_TestDataFactory.createAccount('Test Account', true);
            contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc);
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc, pst);
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true,acc,con,usr);
            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes,childServiceTerritory,'P');
            WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill',true);
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);
            wo.AccountId = acc.Id;
            update wo;
            ServiceRes.RelatedRecordId = usr.Id;
            update ServiceRes;
            
            Account acc1= PV_TestDataFactory.createAccount('Location Account', true);
            contact con1 = PV_TestDataFactory.createContact('Test Location', 'contact_03',true,acc1);
            
            Id ProfileId = [Select Id from profile where Name='#FS Service Resource (Partner Community)'].Id;
            User user = new User();
            user.FirstName = 'Test_';
            user.LastName = 'User';
            user.PortalRole = 'Manager';
            //   user.UserRoleId = userRoleId ;
            user.Email='test_userlocation@gmail.com';
            user.Alias='tst';
            user.Username = con1.Id+'test_user@gmail.com';
            user.CommunityNickname = 'tstuserlocation';
            user.TimeZoneSidKey = 'America/Los_Angeles';
            user.LocaleSidKey = 'en_US';
            user.EmailEncodingKey = 'UTF-8';
            user.LanguageLocaleKey = 'en_US';
            user.PostalCode ='35401';
            user.ProfileId = ProfileId;
            user.contactId = con1.Id;
            insert user;
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, user, 'FSL_Technician');
            
            List<Product2> prList = new List<Product2>();
            Product2 pr1 = new Product2();
            pr1.Name = 'Test P1';
            prList.add(pr1);
            //insert pr1;
            Product2 pr2 = new Product2();
            pr2.Name = 'Test P2';
            prList.add(pr2);
            insert prList;
            Schema.Location loct = new Schema.Location();
            loct.Name = 'Test1';
            loct.LocationType = 'Warehouse';
            loct.IsInventoryLocation = true;
            loct.Account__c = acc.Id;
            loct.IsMobile = true;
            insert loct;

            ServiceResource sr= new ServiceResource();
            sr.Name = 'Test';
            sr.IsActive = TRUE;
            sr.RelatedRecordId =user.Id;
            sr.Contact__c = con1.Id;
            sr.AccountId = acc1.Id;
            sr.ResourceType = 'T';
            sr.LocationId = loct.Id;
            insert sr ;
            
            Test.startTest();
            
            List<ServiceAppointment>Sa = new List<ServiceAppointment>();
                    
            ServiceAppointment sa1 = new ServiceAppointment();
            sa1.ParentRecordId = wo.Id;
            sa1.FSSK__FSK_Work_Order__c = wo.Id;
            sa1.ServiceTerritoryId = pst.Id;
            sa1.WorkTypeId = wt.Id;
            sa1.Status = 'Scheduled';
            sa1.SchedStartTime = System.today().adddays(1);
            sa1.SchedEndTime = Date.today().adddays(2);
            sa1.DueDate = System.today().adddays(3);
            sa1.EarliestStartTime = System.Today();
            Sa.add(sa1);
            
            ServiceAppointment sa01 = new ServiceAppointment();
            sa01.ParentRecordId = wo.Id;
            sa01.FSSK__FSK_Work_Order__c = wo.Id;
            sa01.ServiceTerritoryId = pst.Id;
            sa01.WorkTypeId = wt.Id;
            sa01.Status = 'Unscheduled';
            sa01.SchedStartTime = Date.today().adddays(2);
            sa01.SchedEndTime =  Date.today().adddays(3);
            sa01.DueDate = System.today().adddays(4);
            sa01.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
            sa01.EarliestStartTime = System.now();
            Sa.add(sa01);
            system.debug('sa01.SchedStartTime::::'+sa01.SchedStartTime);
            
            ServiceAppointment sa02= new ServiceAppointment();
            sa02.ParentRecordId = wo.Id;
            sa02.FSSK__FSK_Work_Order__c = wo.Id;
            sa02.ServiceTerritoryId = pst.Id;
            sa02.WorkTypeId = wt.Id;
            sa02.Status = 'Unscheduled';
            sa02.SchedStartTime = Date.today().adddays(2);
            sa02.SchedEndTime =  Date.today().adddays(3);
            sa02.DueDate = System.today().adddays(4);
            sa02.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
            sa02.EarliestStartTime = System.now();
            Sa.add(sa02);
            //insert sa02;
            
            
            ServiceAppointment sa03 = new ServiceAppointment();
            sa03.ParentRecordId = wo.Id;
            sa03.FSSK__FSK_Work_Order__c = wo.Id;
            sa03.ServiceTerritoryId = pst.Id;
            sa03.WorkTypeId = wt.Id;
            sa03.Status = 'Dispatched';
            sa03.SchedStartTime = Date.today().adddays(2);
            sa03.SchedEndTime =  Date.today().adddays(3);
            sa03.DueDate = System.today().adddays(4);
            sa03.FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
            sa03.EarliestStartTime = System.now();
           Sa.add(sa03);
            
            insert  Sa;
            
    Sa[0].FSSK__FSK_Assigned_Service_Resource__c = sr.Id;
            update Sa;
            
            ProductItem prIt = new ProductItem();
            prIt.Product2Id = pr2.Id;
            prIt.QuantityOnHand = 3;
            prIt.LocationId = loct.Id;
            insert prIt;
            
            ProductRequired prReq = new ProductRequired();
            prReq.ParentRecordId = sa03.ParentRecordId;
            prReq.Product2Id = pr1.Id;
            prReq.QuantityRequired = 1;
            insert prReq;
            ProductConsumed prCon = new ProductConsumed();
            prCon.ProductItemId = prIt.Id;
            prCon.QuantityConsumed = 1;
            prCon.WorkOrderId = sa03.ParentRecordId;
            insert prCon;
        }
        Test.stopTest();
    }
    @isTest
    static void inventoryDetails() {
        List<User> usr = [SELECT Id FROM User WHERE Email = 'test_userlocation@gmail.com' ];
        List<ServiceAppointment> sa = [SELECT Id ,SchedStartTime FROM ServiceAppointment];
        Test.startTest();
        PV_InventroyDetailsController.getInventoryDetails(usr[0].Id, Date.today().adddays(2),Date.today().adddays(3));
        PV_InventroyDetailsController.getInventoryDetails(usr[0].Id, Date.today().adddays(2),null);
        Test.stopTest();
    }
}