@isTest
public with sharing class FSL_UpdateAppointmentsQueueableTest {
    public static final String defaultSchedulingPolicyName = 'POE Scheduling';
    public static final String defaultPostalCode = '35401';

    @testSetup
    static void makeData() {
        Test.startTest();
        Account account = PV_TestDataFactory.createAccount('Test Account', true);
        Contact contact = PV_TestDataFactory.createContact('Test', 'Contact', true, account);

        TimeZone timeZone = UserInfo.getTimeZone();
        OperatingHours operatingHours = new OperatingHours();
        operatingHours.Name = 'Test';
        operatingHours.TimeZone = timeZone.getId();
        insert operatingHours;

        createTimeSlotsForOperatingHours(operatingHours);

        ServiceTerritory parentServiceTerritory = PV_TestDataFactory.createParentServiceTerritory(true, 'Test Territory', operatingHours);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, account, parentServiceTerritory);
        User user = PV_TestDataFactory.createTechnicianUser(true, contact);

        System.runAs(user) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, user, 'FSL_Technician');
        }

        ServiceResource serviceResource = PV_TestDataFactory.createServiceResource(true,account,contact,user);
        ServiceTerritoryMember serviceTerritoryMember = PV_TestDataFactory.createServiceTerritoryMember(true,serviceResource,childServiceTerritory,'P');

        WorkType workType = PV_TestDataFactory.createWorkType('Test Work Type', true);
        WorkOrder workOrder = PV_TestDataFactory.createWorkOrder(user, workType, true);

        Id dealerId = account.Id;
        Id childServiceTerritoryId = childServiceTerritory.Id;
        ServiceAppointment serviceAppointment = [SELECT Id, Dealer__c FROM ServiceAppointment LIMIT 1];

        serviceAppointment.Status = 'Unscheduled';
        serviceAppointment.DueDate = System.today().addDays(+365);
        serviceAppointment.PostalCode = defaultPostalCode;
        serviceAppointment.Dealer__c = dealerId;
        serviceAppointment.ServiceTerritoryId = childServiceTerritoryId;
        update serviceAppointment;

        ServiceAppointment secondServiceAppointment = new ServiceAppointment();

        secondServiceAppointment.ParentRecordId = workOrder.Id;
        secondServiceAppointment.ServiceTerritoryId = childServiceTerritory.Id;
        secondServiceAppointment.WorkTypeId = workType.Id;    
        secondServiceAppointment.Status = 'Unscheduled';
        secondServiceAppointment.DueDate = System.today().addDays(+365);
        secondServiceAppointment.PostalCode = defaultPostalCode;
        secondServiceAppointment.Dealer__c = dealerId;
        secondServiceAppointment.ServiceTerritoryId = childServiceTerritoryId;
        secondServiceAppointment.SchedStartTime = System.now();
        secondServiceAppointment.SchedEndTime = System.now().addHours(3);
        secondServiceAppointment.DueDate = System.today().adddays(3);
        secondServiceAppointment.EarliestStartTime = System.Today();
        insert secondServiceAppointment;

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
    public static void updateAppointmentFieldsTest() {
        Test.startTest();
        
        FSL_Settings__c fslSettings = new FSL_Settings__c(
            Default_Scheduling_Policy_Name__c = defaultSchedulingPolicyName
        );
        insert fslSettings;

        FSL__Scheduling_Policy__c defaultPolicy = new FSL__Scheduling_Policy__c(
            Name = defaultSchedulingPolicyName
        );
        insert defaultPolicy;

        List<ServiceAppointment> serviceAppointment = [
            SELECT Id, ServiceTerritoryId, Dealer__c, ParentRecordId, EarliestStartTime
            FROM ServiceAppointment
            LIMIT 1
        ];

        System.debug('ServiceTerritoryId: ' + serviceAppointment[0].ServiceTerritoryId);
        ServiceTerritory serviceTerritory = [
            SELECT Id, Account__c
            FROM ServiceTerritory
            WHERE ParentTerritory.Id != NULL AND Account__c != NULL
        ];

        System.debug('serviceTerritory.Id: ' + serviceTerritory.Id);

        Map<Id, ServiceTerritory> territoryMap = new Map<Id, ServiceTerritory>();
        territoryMap.put(serviceAppointment[0].Id, serviceTerritory);

        update serviceTerritory;

        serviceAppointment[0].ServiceTerritoryId = serviceTerritory.Id;
        serviceAppointment[0].ServiceTerritory = serviceTerritory;
        serviceAppointment[0].EarliestStartTime = Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day(), 9, 0, 0);

        System.enqueueJob(new FSL_UpdateAppointmentsFieldsQueueable(serviceAppointment, defaultPolicy.Id, Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day(), 9, 0, 0), Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day(), 11, 0, 0), territoryMap));

        Test.stopTest();

        List<ServiceAppointment> result = [SELECT Id, ArrivalWindowStartTime, ArrivalWindowEndTime FROM ServiceAppointment WHERE Id = :serviceAppointment[0].Id];

        Assert.areEqual(1, result.size(), 'The query should have returned a service appointment');
        Assert.areNotEqual(null, result[0].ArrivalWindowStartTime, 'ArrivalWindowStartTime should be set');
        Assert.areNotEqual(null, result[0].ArrivalWindowEndTime, 'ArrivalWindowEndTime should be set');
    }

    @isTest
    public static void scheduleAppointmentschedulerTest() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        Test.startTest();
        
        FSL_Settings__c fslSettings = new FSL_Settings__c(
            Default_Scheduling_Policy_Name__c = defaultSchedulingPolicyName
        );
        insert fslSettings;

        FSL__Scheduling_Policy__c defaultPolicy = new FSL__Scheduling_Policy__c(
            Name = defaultSchedulingPolicyName
        );
        insert defaultPolicy;

        List<ServiceAppointment> serviceAppointment = [
            SELECT Id, ServiceTerritoryId, Dealer__c, ParentRecordId, EarliestStartTime
            FROM ServiceAppointment
        ];

        System.debug('ServiceTerritoryId: ' + serviceAppointment[0].ServiceTerritoryId);
        ServiceTerritory serviceTerritory = [
            SELECT Id, Account__c
            FROM ServiceTerritory
            WHERE ParentTerritory.Id != NULL AND Account__c != NULL
        ];

        System.debug('serviceTerritory.Id: ' + serviceTerritory.Id);
        Map<Id, ServiceTerritory> territoryMap = new Map<Id, ServiceTerritory>();
        territoryMap.put(serviceAppointment[0].Id, serviceTerritory);

        System.enqueueJob(new FSL_RunShedulerCostcoQueueable(serviceAppointment, defaultPolicy.Id, territoryMap));

        Test.stopTest();

        List<ServiceAppointment> result = [SELECT Id, ServiceTerritoryId, Status, ParentRecordId, EarliestStartTime FROM ServiceAppointment WHERE Id = :serviceAppointment[0].Id];

        Assert.areEqual('Scheduled', result[0].Status, 'The status does not match');
    }

    @isTest
    public static void runSchedulerCostcoQueueableExceptionTest() {
        Test.startTest();
        
        FSL_Settings__c fslSettings = new FSL_Settings__c(
            Default_Scheduling_Policy_Name__c = defaultSchedulingPolicyName
        );
        insert fslSettings;

        FSL__Scheduling_Policy__c defaultPolicy = new FSL__Scheduling_Policy__c(
            Name = defaultSchedulingPolicyName
        );
        insert defaultPolicy;

        List<ServiceAppointment> serviceAppointment = [
            SELECT Id, ServiceTerritoryId, Dealer__c, ParentRecordId, EarliestStartTime
            FROM ServiceAppointment
        ];

        ServiceTerritory serviceTerritory = [
            SELECT Id, Account__c
            FROM ServiceTerritory
            WHERE ParentTerritory.Id != NULL AND Account__c != NULL
        ];

        Map<Id, ServiceTerritory> territoryMap = new Map<Id, ServiceTerritory>();
        territoryMap.put(serviceAppointment[0].Id, serviceTerritory);

        System.enqueueJob(new FSL_RunShedulerCostcoQueueable(serviceAppointment, defaultPolicy.Id, territoryMap));
        Test.stopTest();

        List<ServiceAppointment> result = [SELECT Id, ServiceTerritoryId, Status, ParentRecordId, EarliestStartTime FROM ServiceAppointment WHERE Id = :serviceAppointment[0].Id];
    }
}