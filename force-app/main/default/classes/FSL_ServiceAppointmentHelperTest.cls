@isTest
public class FSL_ServiceAppointmentHelperTest {

    @testSetup
    static void makeData() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');

        Account account = PV_TestDataFactory.createAccount('Test Account', true);
        Contact contact = PV_TestDataFactory.createContact('Test', 'Contact', true, account);

        TimeZone timeZone = TimeZone.getTimeZone('America/Los_Angeles');
        OperatingHours operatingHours = new OperatingHours();
        operatingHours.Name = 'Test';
        operatingHours.TimeZone = timeZone.getId();
        insert operatingHours;

        operatingHours = [SELECT Id FROM OperatingHours LIMIT 1];

        ServiceTerritory parentServiceTerritory = PV_TestDataFactory.createParentServiceTerritory(true, 'Test Territory', operatingHours);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, account, parentServiceTerritory);
        User user = PV_TestDataFactory.createTechnicianUser(true, contact);

        WorkType workType = PV_TestDataFactory.createWorkType('Test Work Type', true);
        WorkOrder workOrder = PV_TestDataFactory.createWorkOrder(user, workType, true);

        Id dealerId = [SELECT Id FROM Account LIMIT 1].Id;
        Id childServiceTerritoryId = [SELECT Id FROM ServiceTerritory WHERE ParentTerritory.Id != null].Id;
        ServiceAppointment serviceAppointment = [SELECT Id, Dealer__c FROM ServiceAppointment LIMIT 1];

        serviceAppointment.Status = 'Scheduled';
        serviceAppointment.DueDate = System.today().addDays(+365);
        serviceAppointment.SchedStartTime = System.today().addDays(1);
        serviceAppointment.SchedEndTime = System.today().addDays(1);
        serviceAppointment.ArrivalWindowStartTime = System.today().addDays(1);
        serviceAppointment.ArrivalWindowEndTime = System.today().addDays(1);
        serviceAppointment.ServiceTerritoryId = childServiceTerritoryId;
        update serviceAppointment;
    }

    @isTest
    static void convertToTimeZoneTest() {
        List<ServiceAppointment> serviceAppointments = [
            SELECT  Id, SchedStartTime
            FROM    ServiceAppointment 
            LIMIT 1
        ];

        List<String> serviceAppointmentIds = new List<String>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointmentIds.add(serviceAppointment.Id);
        }

        Test.startTest();
        List<FSL_ServiceAppointmentHelper.ServiceAppointmentWrapper> results = FSL_ServiceAppointmentHelper.convertToTimeZone(serviceAppointmentIds);
        Test.stopTest();

        ServiceAppointment baseAppointment = serviceAppointments[0];
        FSL_ServiceAppointmentHelper.ServiceAppointmentWrapper convertedAppointment = results[0];
        System.assertEquals(1, results.size(), 'Expected one result from the conversion.');

        // SchedStartTime
        String baseAppointmentSchedStartTime = baseAppointment.SchedStartTime.format('MM/dd/yyyy', 'GMT');
        String convertedAppointmentSchedStartTime = convertedAppointment.formattedSchedStartTime;
        
        System.assertNotEquals(baseAppointmentSchedStartTime, convertedAppointmentSchedStartTime, 'SchedStartTime should be converted.');
    }
}