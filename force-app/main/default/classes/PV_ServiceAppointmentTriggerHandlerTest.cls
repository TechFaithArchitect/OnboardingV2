@isTest
public class PV_ServiceAppointmentTriggerHandlerTest {
    public static final String defaultSchedulingPolicyName = 'POE Scheduling';
    public static final String POE_DEALER = 'POE_Dealer';
    public static final String BUSINESS_UNIT_DCC = 'Direct Connect Connections';

    @TestSetup
    static void makeTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            RecordType recType = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = :POE_DEALER LIMIT 1];
            Test.startTest();
            Account acc = PV_TestDataFactory.createAccount('Test Account', true);
            acc.Available_FSL_Vendors__c = 'COSTCO';
            acc.RecordTypeId = recType.Id;
            acc.Business_Unit__c = BUSINESS_UNIT_DCC;
            update acc;
            contact con = PV_TestDataFactory.createContact('Test', 'contact_01', true, acc);
            con.Phone = '9999999999';
            update con;
            OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01', opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(
                true,
                acc,
                pst
            );
            User usr = PV_TestDataFactory.createTechnicianUser(true, con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');

            Schema.Location loct = new Schema.Location();
            loct.Name = 'Test1';
            loct.LocationType = 'Warehouse';
            loct.IsInventoryLocation = true;
            loct.Account__c = acc.Id;
            loct.IsMobile = true;
            insert loct;
            ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(false, acc, con, usr);
            ServiceRes.LocationId = loct.Id;
            insert ServiceRes;

            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(
                true,
                ServiceRes,
                childServiceTerritory,
                'P'
            );

            WorkType wt = PV_TestDataFactory.createWorkType('DIRECTV Install', true);
            WorkType wtCOSTCO = PV_TestDataFactory.createWorkType('COSTCO Install', true);
            wtCOSTCO.Afternoon_Installation__c = true;
            wtCOSTCO.Vendor__c = 'COSTCO';
            update wtCOSTCO;
            
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr, wtCOSTCO, true);
            ServiceRes.RelatedRecordId = usr.Id;
            serviceRes.Manager__c = usr.Id;
            update ServiceRes;

            Skill TMoFB_Meraki_MG51_MG51e = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Meraki_MG51_MG51e'];

            ServiceResourceSkill srSkill01 = new ServiceResourceSkill();
            srSkill01.ServiceResourceId = ServiceRes.Id;
            srSkill01.SkillLevel= 80.00;
            srSkill01.EffectiveStartDate = System.Today();
            srSkill01.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
            insert srSkill01;

            SkillRequirement wtypeSkillReq1 = new SkillRequirement();
            wtypeSkillReq1.RelatedRecordId = wtCOSTCO.Id;
            wtypeSkillReq1.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
            insert wtypeSkillReq1;

            List<Shift> shiftList = new List<Shift>();
            for (Integer i = 0; i < 3; i++) {
                Shift shift = new Shift();
                shift.ServiceResourceId = ServiceRes.Id;
                shift.StartTime = DateTime.now().addDays(i);
                shift.EndTime = DateTime.now().addDays(i).addHours(8);
                shift.TimeSlotType = 'Normal';
                shift.ServiceTerritoryId = childServiceTerritory.Id;
                shift.Status = 'Confirmed';
                shiftList.add(shift);
            }
            insert shiftList;


            String RecTypeId = [SELECT Id FROM RecordType WHERE Name = 'Person Account' AND SobjectType = 'Account'].Id;
            Account personAccnt = new Account(
                RecordTypeID = RecTypeId,
                FirstName = 'Test FName',
                LastName = 'Test LName',
                PersonMailingStreet = 'test@yopmail.com',
                PersonMailingPostalCode = '12345',
                PersonMailingCity = 'SFO',
                PersonEmail = 'test@yahoo.com',
                PersonMobilePhone = '12345678'
            );
            insert personAccnt;

            wo.AccountId = personAccnt.id;
            wo.ServiceTerritoryId = pst.Id;
            wo.Assign_to_Dealer_Immediately__c = true;
            wo.StartDate = DateTime.now();
            update wo;
            Test.stopTest();

            FSL_Settings__c fslSettings = new FSL_Settings__c(
                Default_Scheduling_Policy_Name__c = defaultSchedulingPolicyName
            );
            insert fslSettings;
    
            FSL__Scheduling_Policy__c defaultPolicy = new FSL__Scheduling_Policy__c(
                Name = defaultSchedulingPolicyName
            );
            insert defaultPolicy;

            List<ServiceAppointment> salist = new List<ServiceAppointment>();
            ServiceAppointment sa = new ServiceAppointment();
            sa.ParentRecordId = wo.Id;
            sa.FSSK__FSK_Work_Order__c = wo.Id;
            sa.ServiceTerritoryId = pst.Id;
            sa.WorkTypeId = wt.Id;
            sa.Status = 'Scheduled';
            sa.SchedStartTime = System.now();
            sa.SchedEndTime = System.now().addHours(3);
            sa.DueDate = System.today().adddays(3);
            sa.FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id;
            sa.EarliestStartTime = System.Today();
            salist.add(sa);

            ServiceAppointment sa01 = new ServiceAppointment();
            sa01.ParentRecordId = wo.Id;
            sa01.FSSK__FSK_Work_Order__c = wo.Id;
            sa01.ServiceTerritoryId = pst.Id;
            sa01.WorkTypeId = wtCOSTCO.Id;
            sa01.Status = 'Unscheduled';
            sa01.SchedStartTime = System.Today();
            sa01.SchedEndTime = System.now().addHours(3);
            sa01.DueDate = System.today().adddays(4);
            sa01.FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id;
            sa01.EarliestStartTime = System.now();
            salist.add(sa01);

            ServiceAppointment sa02 = new ServiceAppointment();
            sa02.ParentRecordId = wo.Id;
            sa02.FSSK__FSK_Work_Order__c = wo.Id;
            sa02.ServiceTerritoryId = pst.Id;
            sa02.WorkTypeId = wt.Id;
            sa02.Status = 'Unscheduled';
            sa02.SchedStartTime = System.Today();
            sa02.SchedEndTime = System.now().addHours(3);
            sa02.DueDate = System.today().adddays(4);
            sa02.FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id;
            sa02.EarliestStartTime = System.now();
            salist.add(sa02);

            ServiceAppointment sa03 = new ServiceAppointment();
            sa03.ParentRecordId = wo.Id;
            sa03.FSSK__FSK_Work_Order__c = wo.Id;
            sa03.ServiceTerritoryId = pst.Id;
            sa03.WorkTypeId = wt.Id;
            sa03.Status = 'Dispatched';
            sa03.SchedStartTime = System.Today();
            sa03.SchedEndTime = System.now().addHours(3);
            sa03.DueDate = System.today().adddays(4);
            sa03.FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id;
            sa03.EarliestStartTime = System.now();
            salist.add(sa03);

            ServiceAppointment sa04 = new ServiceAppointment();
            sa04.ParentRecordId = wo.Id;
            sa04.FSSK__FSK_Work_Order__c = wo.Id;
            sa04.ServiceTerritoryId = pst.Id;
            sa04.WorkTypeId = wt.Id;
            sa04.Status = 'Scheduled';
            sa04.ArrivalWindowStartTime = System.Today();
            sa04.ArrivalWindowEndTime = System.now().addHours(3);
            sa04.DueDate = System.today().adddays(4);
            sa04.FSSK__FSK_Assigned_Service_Resource__c = ServiceRes.Id;
            sa04.EarliestStartTime = System.now();
            salist.add(sa04);
            insert salist;

            FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Acknowledge');
            sa01.Status = 'Scheduled';

            FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Acknowledge');
            sa03.Status = 'Acknowledge';
            update salist;

            Product2 pr1 = new Product2();
            pr1.Name = 'Test P1';
            insert pr1;
            Product2 pr2 = new Product2();
            pr2.Name = 'Test P2';
            insert pr2;
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
    }

    static List<TimeSlot> createTimeSlotsForOperatingHours(OperatingHours operatingHours) {
        List<TimeSlot> timeSlots = new List<TimeSlot>();
        List<String> daysOfWeek = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'};
        
        for (String day : daysOfWeek) {
            TimeSlot timeSlot = new TimeSlot();
            timeSlot.OperatingHoursId = operatingHours.Id;
            timeSlot.DayOfWeek = day;
            timeSlot.StartTime = Time.newInstance(8, 0, 0, 0);
            timeSlot.EndTime = Time.newInstance(17, 0, 0, 0);
            timeSlots.add(timeSlot);
        }
        insert timeSlots;
        return timeSlots;
    }

    @isTest
    static void handleAfterUpdateAndNotificationTest() {
        Test.startTest();
        List<ServiceAppointment> sa1 = [SELECT Id, Status FROM ServiceAppointment WHERE Status = 'Scheduled'];
        sa1[0].Status = 'Acknowledge';
        update sa1;
        List<ServiceAppointment> updatedServices = [
            SELECT Id, Status
            FROM ServiceAppointment
            WHERE Status = 'Dispatched' AND Status != 'Acknowledge'
        ];
        Test.stopTest();
        System.assertEquals(0, updatedServices.size(), 'Service Appointments were not updated');
    }

    @isTest
    static void handleBeforeInsertTest() {
        Test.startTest();

        TimeZone timeZone = UserInfo.getTimeZone();
        OperatingHours operatingHours = new OperatingHours();
        operatingHours.Name = 'Test';
        operatingHours.TimeZone = timeZone.getId();
        insert operatingHours;

        operatingHours = [SELECT Id FROM OperatingHours LIMIT 1];
        List<TimeSlot> timeSlots = createTimeSlotsForOperatingHours(operatingHours);

        ServiceTerritory serviceTerritory = [
            SELECT Id, Account__c
            FROM ServiceTerritory
            WHERE ParentTerritory.Id != NULL AND Account__c != NULL
        ];

        serviceTerritory.OperatingHours = operatingHours;

        //remove
        System.debug('test territory Id: ' + serviceTerritory.Id);

        update serviceTerritory;


        List<WorkOrder> wo = [SELECT Id FROM WorkOrder];
        List<ServiceTerritory> pst = [SELECT Id FROM ServiceTerritory];
        WorkType wt = [SELECT Id, Extended_Earliest_Date_in_days__c FROM WorkType LIMIT 1];
        wt.Extended_Earliest_Date_in_days__c = 1;
        update wt;
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = wo[0].Id;
        sa.ServiceTerritoryId = serviceTerritory.Id;
        sa.WorkTypeId = wt.Id;
        sa.EarliestStartTime = Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day(), 9, 0, 0);
        insert sa;
        ServiceAppointment serviceAppointment = [SELECT Id, DueDate FROM ServiceAppointment WHERE Id = :sa.Id LIMIT 1];
        Test.stopTest();
        DateTime earliestStartTime = System.now();
        System.assertEquals(true, serviceAppointment.dueDate > earliestStartTime, 'Due Date was not updated');
    }

    @isTest
    static void assignDealerToAppointmentsTest() {
        Test.startTest();
        ServiceAppointment serviceAppointment = [
            SELECT Id, ServiceTerritoryId, Dealer__c, ParentRecordId
            FROM ServiceAppointment
            LIMIT 1
        ];
        ServiceTerritory serviceTerritory = [
            SELECT Id, Account__c
            FROM ServiceTerritory
            WHERE ParentTerritory.Id != NULL AND Account__c != NULL
        ];
        serviceAppointment.ServiceTerritoryId = serviceTerritory.Id;

        update serviceAppointment;

        WorkOrder workOrder = [
            SELECT Id, Dealer__c, Assign_to_Dealer_Immediately__c, ServiceTerritoryId
            FROM WorkOrder
            WHERE Id = :serviceAppointment.ParentRecordId
        ];

        serviceAppointment = [
            SELECT Id, ServiceTerritoryId, Dealer__c, ParentRecordId
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        Test.stopTest();

        System.assertEquals(
            serviceTerritory.Account__c,
            serviceAppointment.Dealer__c,
            'The Dealer field was not correctly assigned to the SA'
        );
        System.assertEquals(
            serviceTerritory.Account__c,
            workOrder.Dealer__c,
            'The Dealer field was not correctly assigned to the WO'
        );
    }

    @isTest
    static void updateFirstAvailableSlotStartTimeTest() {

        TimeZone timeZone = UserInfo.getTimeZone();
        OperatingHours operatingHours = new OperatingHours();
        operatingHours.Name = 'Test';
        operatingHours.TimeZone = timeZone.getId();
        insert operatingHours;

        operatingHours = [SELECT Id FROM OperatingHours LIMIT 1];
        List<TimeSlot> timeSlots = createTimeSlotsForOperatingHours(operatingHours);

        ServiceTerritory serviceTerritory = [
            SELECT Id, Account__c
            FROM ServiceTerritory
            WHERE ParentTerritory.Id != NULL AND Account__c != NULL
        ];
        serviceTerritory.OperatingHours = operatingHours;
        update serviceTerritory;

        ServiceAppointment serviceAppointment = [
            SELECT Id
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.ServiceTerritoryId = null;
        update serviceAppointment;

        Test.startTest();
        serviceAppointment.ServiceTerritoryId = serviceTerritory.Id;
        update serviceAppointment;
        Test.stopTest();

        serviceAppointment = [
            SELECT Id, First_Available_Slot_Start_Time__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        Assert.isNotNull(serviceAppointment.First_Available_Slot_Start_Time__c, 'The First_Available_Slot_Start_Time__c field was not correctly assigned');
    }
}