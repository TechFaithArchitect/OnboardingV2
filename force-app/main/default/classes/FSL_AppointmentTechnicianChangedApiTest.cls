@isTest
public class FSL_AppointmentTechnicianChangedApiTest {

    @TestSetup
    static void makeData() {
  
        Account acc = PV_TestDataFactory.createAccount('testProduct', true);
        Contact con = PV_TestDataFactory.createContact('Test', 'Hikko123', true, acc);

        User u = PV_TestDataFactory.createTechnicianUser(false, con);
        u.IsActive = true;
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'External Partner - DCC' LIMIT 1].Id;
        insert u;

        System.runAs(u) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, u, 'FSL_Dispatcher_and_Technician');

            PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
            permissionSetAssignment.AssigneeId = u.Id;
            permissionSetAssignment.PermissionSetId = [SELECT Id,Name FROM PermissionSet where Name = 'DCC_Service_Resource'].Id;
            insert permissionSetAssignment;
        }

        ServiceResource sr = new ServiceResource(
            Name = 'Test Service Resource',
            RelatedRecordId = u.Id
        );
        insert sr;

        Schema.Location loc = new Schema.Location(
            Name = 'FSL Test Location',
            Service_Resource__c = sr.Id,
            IsInventoryLocation = true,
            IsMobile = true
        );
        insert loc;

        WorkOrder wo = new WorkOrder(
            Status = 'Unscheduled',
            Vendor__c = 'COSTCO'
        );
        insert wo;

        OperatingHours op = new OperatingHours(Name = 'Test OH');
        insert op;

        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test SA',
            OperatingHoursId = op.Id,
            IsActive = true
        );
        insert st;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            FSSK__FSK_Assigned_Service_Resource__c = sr.Id,
            SchedStartTime = System.today().addDays(1),
            SchedEndTime = System.today().addDays(2),
            External_Id__c = 'EXT-001',
            Vendor__c = 'COSTCO'
        );
        insert sa;
    }

    @isTest
    static void testgetServiceAppointments() {

        Test.startTest();
        
        String createdAfter = '2024-01-01T00:00:00Z';
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/serviceAppointmentTechnicianChangedApi/';
        RestContext.request.params.put('createdAfter', createdAfter);

        List<FSL_AppointmentTechnicianChangedApi.ServiceAppointmentWrapper> response = FSL_AppointmentTechnicianChangedApi.getServiceAppointments();

        Test.stopTest();

        System.assertNotEquals(0, response.size(), 'The response list should not be empty.');        
    }
}