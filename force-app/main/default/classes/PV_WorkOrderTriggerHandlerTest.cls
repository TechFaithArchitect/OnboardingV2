/**
* @description       : Test Class for PV_WorkOrderTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 12-05-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
@isTest
public class PV_WorkOrderTriggerHandlerTest {
    static String viasat = Label.ViaSat_Skills;
    static String DirecTV = Label.DirecTV_Skills;
    static String DirecTVval = Label.DIRECTV;
    static String ViaSatval = Label.ViaSat;

    @testSetup
    static void setupMethod() {
       
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        
            // Create Service Territory
            ServiceTerritory territory = new ServiceTerritory(Name = 'T01', OperatingHoursId = opHrs.Id, IsActive = true);
            insert territory;

            // Create Service Territory with Vendors__c
            ServiceTerritory territoryWithVendors = new ServiceTerritory(Name = 'T02', OperatingHoursId = opHrs.Id, IsActive = true, Vendors__c = 'T-Mobile;DIRECTV');
            insert territoryWithVendors;
            
            // Create Assigned Postal Code
            Assigned_Postal_Code__c postalCode = new Assigned_Postal_Code__c(Name = 'AL - 35401', Service_Territory__c = territory.Id, Postal_Code__c = '35401');
            insert postalCode;
            
            // Create Assigned Postal Code with vendor-specific territory
            Assigned_Postal_Code__c postalCodeWithVendors = new Assigned_Postal_Code__c(Name = 'AL - 35402', Service_Territory__c = territoryWithVendors.Id, Postal_Code__c = '35402');
            insert postalCodeWithVendors;
            
            // Create Accounts
            Account account1 = new Account(Name = 'MobUserTest', Phone = '+17907747550', BillingPostalCode = '35401');
            insert account1;
            Account account2 = PV_TestDataFactory.createAccount('Test Account', true);
            account2.phone = '8606456050';
            account2.Available_FSL_Vendors__c = 'T-Mobile';
            update account2;
            
            Account account3 = new Account(Name = 'Test Account 3', Phone = '+17907747551', BillingPostalCode = '35402');
            insert account3;
            
            // Create Contact
            Contact contact = new Contact(FirstName = 'con1', LastName = 'Test' + DateTime.now().getTime(), AccountId = account1.Id, Phone = '9411082643');
            insert contact;

            Contact contactTwo = new Contact(FirstName = 'con2', LastName = 'Tester2' + DateTime.now().getTime(), AccountId = account2.Id, Phone = '9411082644');
            insert contactTwo;

            User usr = PV_TestDataFactory.createTechnicianUser(true, contact);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');

            Id ProfileId = [Select Id from profile where Name='#FS Service Resource (Partner Community)'].Id;
            User usr2 = new user();
            usr2.FirstName = 'Tt';
            usr2.LastName = 'User2';
            usr2.PortalRole = 'Manager';
            usr2.Email='test2_user@gmail.com';
            usr2.Alias='tst2';
            usr2.Username = contactTwo.Id+'test2_user@gmail.com';
            usr2.CommunityNickname = 'tstuser2';
            usr2.TimeZoneSidKey = 'America/Los_Angeles';
            usr2.LocaleSidKey = 'en_US';
            usr2.EmailEncodingKey = 'UTF-8';
            usr2.LanguageLocaleKey = 'en_US';
            usr2.PostalCode ='35401';
            usr2.ProfileId = ProfileId ;
            usr2.contactId = contactTwo.Id;
            insert usr2;

            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr2, 'FSL_Technician');

            // Create Location
            Schema.Location location = new Schema.Location(Name = 'Test1', LocationType = 'Warehouse', IsInventoryLocation = true, Account__c = account2.Id, IsMobile = true);
            insert location;

            ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true,account1,contact,usr);
            ServiceRes.Vendor_Type__c = 'T-Mobile';
            ServiceRes.isActive = true;
            ServiceRes.LocationId = location.Id;
            update ServiceRes;

            ServiceResource ServiceRes2 = PV_TestDataFactory.createServiceResource(true,account2,contactTwo,usr2);
            ServiceRes2.Vendor_Type__c = 'T-Mobile';
            ServiceRes2.isActive = true;
            update ServiceRes2;

            
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, account1, territory);
            ServiceTerritory childServiceTerritory2 = PV_TestDataFactory.createServiceTerritoryForAccount(true, account2, territory);
            

            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes,childServiceTerritory,'P');
            ServiceTerritoryMember stm2 = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes2,childServiceTerritory,'P');

            Shift newShift = new Shift(
                StartTime = Date.today().addDays(1),
                EndTime = Date.today().addDays(2),
                ServiceResourceId = ServiceRes.Id,
                ServiceTerritoryId = childServiceTerritory.Id,
                CurrencyIsoCode = 'USD',
                Status = 'Confirmed',
                TimeSlotType = 'Normal');

            insert newShift;

            Shift newShift2 = new Shift(
                StartTime = Date.today().addDays(1),
                EndTime = Date.today().addDays(2),
                ServiceResourceId = ServiceRes2.Id,
                ServiceTerritoryId = childServiceTerritory.Id,
                CurrencyIsoCode = 'USD',
                Status = 'Confirmed',
                TimeSlotType = 'Normal');

            insert newShift2;

            Skill TMoFB_Meraki_MG51_MG51e = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Meraki_MG51_MG51e'];
            Skill TMoFB_Cradlepoint_E300 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_E300'];
            
            List<ServiceResourceSkill> resourceSkills = new List<ServiceResourceSkill>();

            ServiceResourceSkill srSkill01 = new ServiceResourceSkill();
            srSkill01.ServiceResourceId = ServiceRes.Id;
            srSkill01.SkillLevel= 80.00;
            srSkill01.EffectiveStartDate = System.Today();
            srSkill01.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
            resourceSkills.add(srSkill01);

            ServiceResourceSkill srSkill02 = new ServiceResourceSkill();
            srSkill02.ServiceResourceId = ServiceRes.Id;
            srSkill02.SkillLevel= 80.00;
            srSkill02.EffectiveStartDate = System.Today();
            srSkill02.SkillId = TMoFB_Cradlepoint_E300.Id;
            resourceSkills.add(srSkill02);

            ServiceResourceSkill srSkill03 = new ServiceResourceSkill();
            srSkill03.ServiceResourceId = ServiceRes2.Id;
            srSkill03.SkillLevel= 80.00;
            srSkill03.EffectiveStartDate = System.Today();
            srSkill03.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
            resourceSkills.add(srSkill03);

            ServiceResourceSkill srSkill04 = new ServiceResourceSkill();
            srSkill04.ServiceResourceId = ServiceRes2.Id;
            srSkill04.SkillLevel= 80.00;
            srSkill04.EffectiveStartDate = System.Today();
            srSkill04.SkillId = TMoFB_Cradlepoint_E300.Id;
            resourceSkills.add(srSkill04);

            insert resourceSkills;
            ServiceReportLayout srLayout = [SELECT Id, DeveloperName FROM ServiceReportLayout WHERE DeveloperName LIKE :'%T-Mobile Closeout%'];

            // Create Work Types
            List<WorkType> workTypes = new List<WorkType>{
                new WorkType(Name = 'DIRECTV Install', DurationType = 'Minutes', EstimatedDuration = 180),
                new WorkType(Name = 'DIRECTV Service Call', DurationType = 'Minutes', EstimatedDuration = 180),
                new WorkType(Name = 'T-Mobile Commercial Service Call - 12 Hour', DurationType = 'Minutes', EstimatedDuration = 60, ShouldAutoCreateSvcAppt = true, Vendor__c = 'T-Mobile'),
                new WorkType(Name = 'Viasat Commercial Service Call', DurationType = 'Minutes', EstimatedDuration = 90),
                new WorkType(Name = 'T-Mobile Service Call', DurationType = 'Minutes', EstimatedDuration = 60, ShouldAutoCreateSvcAppt = true, Vendor__c = 'T-Mobile', Type__c = 'Service Call')
            };
            insert workTypes;


            SkillRequirement wtypeSkillReq1 = new SkillRequirement();
            wtypeSkillReq1.RelatedRecordId = workTypes[2].Id;
            wtypeSkillReq1.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
            insert wtypeSkillReq1;

            SkillRequirement wtypeSkillReq2 = new SkillRequirement();
            wtypeSkillReq2.RelatedRecordId = workTypes[2].Id;
            wtypeSkillReq2.SkillId = TMoFB_Cradlepoint_E300.Id;
            insert wtypeSkillReq2;

            // Create Work Orders
            List<WorkOrder> workOrders = new List<WorkOrder>{
                new WorkOrder(Status = 'Complete', WorkTypeId = workTypes[0].Id, Vendor__c = DirecTVval, AccountId = account1.Id, ServiceTerritoryId = territory.Id),

                new WorkOrder(Status = 'Dispatched', Notification_check__c = false, WorkTypeId = workTypes[1].Id, Vendor__c = DirecTVval, AccountId = account2.Id),
                new WorkOrder(Status = 'Unscheduled', WorkTypeId = workTypes[2].Id, Vendor__c = 'T-Mobile', ContactId = contact.Id, Postalcode = '35401', City = 'Tuscaloosa', Street = '1402 University Blvd', State = 'Alabama', Country = 'United States', AccountId = account2.Id),
                new WorkOrder(Status = 'Pending Complete', WorkTypeId = workTypes[2].Id, Vendor__c = 'T-Mobile', AccountId = account1.Id, Work_Type_Code_tmo__c = 'COMM1EXTCS')
            };
            insert workOrders;

            // Create Service Appointments
            List<ServiceAppointment> sa = new List<ServiceAppointment>();
            ServiceAppointment sa1 = new ServiceAppointment(ParentRecordId = workOrders[0].Id, FSSK__FSK_Work_Order__c = workOrders[0].Id, WorkTypeId = workTypes[0].Id, Status = 'Unscheduled', SchedStartTime = System.now().addDays(1), SchedEndTime = System.now().addDays(1).addHours(3), DueDate = System.today().addDays(3));
            sa.add(sa1);
            
            Test.stopTest();

            // Update Work Orders
            workOrders[1].Status = 'Complete';
            update workOrders;

            ServiceAppointment sa2 = new ServiceAppointment(ParentRecordId = workOrders[1].Id, FSSK__FSK_Work_Order__c = workOrders[1].Id, WorkTypeId = workTypes[1].Id, Status = 'Dispatched', SchedStartTime = System.today().addDays(1), SchedEndTime = System.now().addDays(1).addHours(3), DueDate = System.today().addDays(4), FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id, EarliestStartTime = System.now());
            sa.add(sa2);
            

            ServiceAppointment sa3 = new ServiceAppointment(ParentRecordId = workOrders[2].Id, FSSK__FSK_Work_Order__c = workOrders[2].Id, WorkTypeId = workTypes[0].Id, Status = 'Scheduled', SchedStartTime = System.now().addDays(1), SchedEndTime = System.now().addDays(1).addHours(3), DueDate = System.today().addDays(3), FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id);
            sa.add(sa3);
            insert sa;
            

            // Create Products
            List<Product2> products = new List<Product2>{
                new Product2(Name = 'Test P1'),
                new Product2(Name = 'Test P2')
            };
            insert products;

            // Create Product Items
            ProductItem productItem = new ProductItem(Product2Id = products[1].Id, QuantityOnHand = 3, LocationId = location.Id);
            insert productItem;

            // Create Product Required
            ProductRequired productRequired = new ProductRequired(ParentRecordId = sa2.ParentRecordId, Product2Id = products[0].Id, QuantityRequired = 1);
            insert productRequired;

            // Create Product Consumed
            ProductConsumed productConsumed = new ProductConsumed(ProductItemId = productItem.Id, QuantityConsumed = 1, WorkOrderId = sa2.ParentRecordId);
            insert productConsumed;
        }
    }

    @isTest
    static void handleBeforeInsertTest() {
        Test.startTest();
        WorkOrder workOrder = [SELECT Id, Status, Vendor__c, ServiceTerritoryId, AccountId FROM WorkOrder WHERE Vendor__c = :DirecTVval LIMIT 1];
        Account account = [SELECT Id, Name, BillingPostalCode FROM Account WHERE Id = :workOrder.AccountId];
        Assigned_Postal_Code__c postalCode = [SELECT Id, Name, Service_Territory__c, Postal_Code__c FROM Assigned_Postal_Code__c WHERE Postal_Code__c = :account.BillingPostalCode];
        Test.stopTest();
        
        System.assertEquals(workOrder.ServiceTerritoryId, postalCode.Service_Territory__c);
    }

    @isTest
    static void handleBeforeInsertWithVendorSpecificTerritoryTest() {
        Test.startTest();
        
        WorkType workType = [SELECT Id FROM WorkType WHERE Name = 'T-Mobile Commercial Service Call - 12 Hour' LIMIT 1];
        Account account = [SELECT Id, BillingPostalCode FROM Account WHERE BillingPostalCode = '35402' LIMIT 1];
        
        WorkOrder workOrder = new WorkOrder(
            Status = 'Unscheduled',
            WorkTypeId = workType.Id,
            Vendor__c = 'T-Mobile',
            AccountId = account.Id,
            PostalCode = '35402'
        );
        
        insert workOrder;
        
        Assigned_Postal_Code__c postalCode = [SELECT Id, Name, Service_Territory__c, Postal_Code__c FROM Assigned_Postal_Code__c WHERE Postal_Code__c = '35402' AND Service_Territory__r.Vendors__c = 'T-Mobile;DIRECTV'];
        WorkOrder insertedWorkOrder = [SELECT Id, ServiceTerritoryId FROM WorkOrder WHERE Id = :workOrder.Id];
        Assert.areEqual(postalCode.Service_Territory__c, insertedWorkOrder.ServiceTerritoryId, 'Service Territory should be assigned');
        
        Test.stopTest();
    }

    @isTest
    static void handleNotificationTest() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            ServiceAppointment serviceAppointment = [SELECT Id, Status, ParentRecordId FROM ServiceAppointment WHERE Status = 'Dispatched'];
            FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Complete');
            serviceAppointment.Status='Complete';
            serviceAppointment.SA_Completed_Date__c= System.today().addDays(-3);
               
            update serviceAppointment;
        }
    }

    @isTest
    static void handleAfterUpdate() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            WorkOrder workOrder = [SELECT Id, Status, Vendor__c, ServiceTerritoryId, PostalCode FROM WorkOrder WHERE Status = 'Pending Complete'];
            
            contentVersions.add(new ContentVersion(Title = 'T-Mobile Closeout', PathOnClient = 'testimage1.jpg', VersionData = Blob.valueOf('Test Image 1'), FirstPublishLocationId = workOrder.Id));
            contentVersions.add(new ContentVersion(Title = 'Test Image 2', PathOnClient = 'testimage2.png', VersionData = Blob.valueOf('Test Image 2'), FirstPublishLocationId = workOrder.Id));
            insert contentVersions;
            
            ServiceReportLayout srLayout  = [SELECT id, DeveloperName FROM ServiceReportLayout WHERE DeveloperName Like:'%T-Mobile Closeout%'];
            
            ServiceReport serviceReport = new ServiceReport(DocumentBody = Blob.valueOf('Test Content'), DocumentContentType = 'application/pdf', DocumentName = 'Test', ParentId = workOrder.Id, IsSigned = true,Template = srLayout.Id);
            insert serviceReport;
            
            workOrder.Status = 'Complete';
            update workOrder;
            
            System.debug('Updated WorkOrder Status: ' + workOrder.Status);
            Test.stopTest();
        }
    }

    @isTest
    static void immediateDealerAssignmentTest() {
        Test.startTest();
        WorkType targetWorkType = [SELECT Id FROM WorkType WHERE Name = 'T-Mobile Commercial Service Call - 12 Hour' LIMIT 1];
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory WHERE Name = 'T01' LIMIT 1];

         
        WorkOrder fullOrder = new WorkOrder(Status = 'Complete', WorkTypeId = targetWorkType.Id, Vendor__c = 'T-Mobile', AccountId = testAcc.Id, Assign_to_Dealer_Immediately__c = true, ServiceTerritoryId = territory.Id);
        insert fullOrder;
        

        PV_WorkOrderTriggerHandler.immediateDealerAssignment(new List<WorkOrder> {fullOrder});
        List<WorkOrder> result = [SELECT Id, Dealer__c, (SELECT Id, ServiceTerritoryId, Dealer__c FROM ServiceAppointments) FROM WorkOrder WHERE Dealer__c = :testAcc.Id];
        Assert.areEqual(1, result.size());
        Assert.areEqual(result[0].Dealer__c, result[0].ServiceAppointments[0].Dealer__c);
        Assert.isNotNull(result[0].ServiceAppointments[0].ServiceTerritoryId);
        Test.stopTest();
    }

    @isTest
    static void calculateDaysSinceInstallationTest() {
        Test.startTest();

        WorkType workType = [SELECT Id FROM WorkType WHERE Name = 'T-Mobile Service Call' LIMIT 1];

        WorkOrder workOrder = [SELECT Id, Status, Vendor__c, AccountId, ServiceTerritoryId, PostalCode, City, Street, State, Country FROM WorkOrder WHERE Status = 'Unscheduled'];
        workOrder.Status = 'Pending Complete';
        update workOrder;

        WorkOrder newServiceCallWorkOrder = new WorkOrder(Status = 'Unscheduled', WorkTypeId = workType.Id, Vendor__c = workOrder.Vendor__c, Postalcode = workOrder.PostalCode, City = workOrder.City, Street = workOrder.Street, State = workOrder.State, Country = workOrder.Country, AccountId = workOrder.AccountId);
        insert newServiceCallWorkOrder;

        // History records are not created in a test context, so we can't assert on the Days_since_Installation__c field

        Test.stopTest();
    }
}