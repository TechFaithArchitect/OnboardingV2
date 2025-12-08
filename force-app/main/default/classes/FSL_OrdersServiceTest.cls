@isTest
public class FSL_OrdersServiceTest {

    public static final String defaultPostalCode = '35401';
    public static final String defaultSchedulingPolicyName = 'POE Scheduling';

    @testSetup
    static void makeData() {
        Account account = PV_TestDataFactory.createAccount('Test Account', true);
        Contact contact = PV_TestDataFactory.createContact('Test', 'Contact', true, account);

        TimeZone timeZone = UserInfo.getTimeZone();
        OperatingHours operatingHours = new OperatingHours();
        operatingHours.Name = 'Test';
        operatingHours.TimeZone = timeZone.getId();
        insert operatingHours;

        operatingHours = [SELECT Id FROM OperatingHours LIMIT 1];
        createTimeSlotsForOperatingHours(operatingHours);

        ServiceTerritory parentServiceTerritory = PV_TestDataFactory.createParentServiceTerritory(true, 'Test Territory', operatingHours);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, account, parentServiceTerritory);
        User user = PV_TestDataFactory.createTechnicianUser(true, contact);

        System.runAs(user) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, user, 'FSL_Technician');
        }

        ServiceResource serviceResource = PV_TestDataFactory.createServiceResource(false,account,contact,user);
        serviceResource.ID_Verizon__c = 'testId1234';
        insert serviceResource;
        
        ServiceTerritoryMember serviceTerritoryMember = PV_TestDataFactory.createServiceTerritoryMember(true,serviceResource,childServiceTerritory,'P');

        WorkType workType = PV_TestDataFactory.createWorkType('Test Work Type', true);
        WorkOrder workOrder = PV_TestDataFactory.createWorkOrder(user, workType, true);

        Id dealerId = [SELECT Id FROM Account LIMIT 1].Id;
        Id childServiceTerritoryId = [SELECT Id FROM ServiceTerritory WHERE ParentTerritory.Id != null].Id;
        ServiceAppointment serviceAppointment = [SELECT Id, Dealer__c FROM ServiceAppointment LIMIT 1];

        serviceAppointment.Status = 'Unscheduled';
        serviceAppointment.DueDate = System.today().addDays(+365);
        serviceAppointment.PostalCode = defaultPostalCode;
        serviceAppointment.Dealer__c = dealerId;
        serviceAppointment.ServiceTerritoryId = childServiceTerritoryId;
        update serviceAppointment;

        FSL_Settings__c fslSettings = new FSL_Settings__c(
            Default_Scheduling_Policy_Name__c = defaultSchedulingPolicyName
        );
        insert fslSettings;

        FSL__Scheduling_Policy__c defaultPolicy = new FSL__Scheduling_Policy__c(
            Name = defaultSchedulingPolicyName
        );
        insert defaultPolicy;
    }
    
    static void createTimeSlotsForOperatingHours(OperatingHours operatingHours) {
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
    }

    @isTest
    static void testGetSlotsValidServiceAppointment() {
        ServiceAppointment serviceAppointment = [SELECT Id, Dealer__c FROM ServiceAppointment LIMIT 1];

        RestRequest req = new RestRequest();
        req.requestURI = '/fslServices/getSlots/' + serviceAppointment.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        FSL_OrdersServiceHandler.GetSlotsResponseWrapper result = FSL_OrdersService.handleGetRequest();

        Assert.areEqual(true, result.slots != null && !result.slots.isEmpty(), 'testGetSlotsValidServiceAppointment: Response should contain slots.');
    }

    @isTest
    static void testGetSlotsInvalidPath() {
        RestRequest req = new RestRequest();
        req.requestURI = '/fslServices/invalidPath';
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        FSL_OrdersServiceHandler.GetSlotsResponseWrapper result = FSL_OrdersService.handleGetRequest();
        
        Assert.areEqual('INVALID_PATH', result.errorCode, 'testGetSlotsInvalidPath: Response should indicate INVALID_PATH.');
    }

    @isTest
    static void testGetSlotsMissingParameterError() {
        RestRequest req = new RestRequest();
        req.requestURI = '/fslServices/getSlots/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        FSL_OrdersServiceHandler.GetSlotsResponseWrapper result = FSL_OrdersService.handleGetRequest();
        
        Assert.areEqual(
            'MISSING_PARAMETER', result.errorCode, 
            'testGetSlotsMissingParameterError: Response should indicate MISSING_PARAMETER.'
        );
    }

    @isTest
    static void testGetSlotsException() {
        ServiceAppointment serviceAppointment = [SELECT Id, Dealer__c FROM ServiceAppointment LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestURI = '/fslServices/getSlots/' + serviceAppointment.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        FSL_OrdersService.throwException = true;
        FSL_OrdersServiceHandler.GetSlotsResponseWrapper serviceResult = FSL_OrdersService.handleGetRequest();

        Assert.areEqual(
            'INTERNAL_SERVER_ERROR', serviceResult.errorCode,
            'testGetSlotsException: Response should indicate INTERNAL_SERVER_ERROR for FSL_OrdersService.handleGetRequest.'
        );

        FSL_OrdersServiceHandler.throwException = true;
        Map<String, Object> handlerResult = FSL_OrdersServiceHandler.getSlots('/getSlots/' + serviceAppointment.Id);
        
        Assert.areEqual(
            'INTERNAL_SERVER_ERROR', handlerResult.get('errorCode'),
            'testGetSlotsException: Response should indicate INTERNAL_SERVER_ERROR for FSL_OrdersServiceHandler.getSlots.'
        );
    }

    @isTest
    static void testGetSlotsResourceNotFoundError() {
        RestRequest req = new RestRequest();
        req.requestURI = '/fslServices/getSlots/invalidServiceAppointmentId';
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        FSL_OrdersServiceHandler.GetSlotsResponseWrapper result = FSL_OrdersService.handleGetRequest();
        
        Assert.areEqual(
            'RESOURCE_NOT_FOUND', result.errorCode, 
            'testGetSlotsResourceNotFoundError: Response should indicate RESOURCE_NOT_FOUND.'
        );
    }

    @isTest
    static void testGetSlotsUnassignedAppointmentError() {
        Test.startTest();
        ServiceAppointment serviceAppointment = [SELECT Id, Dealer__c FROM ServiceAppointment LIMIT 1];
        serviceAppointment.Dealer__c = null;
        update serviceAppointment;

        RestRequest req = new RestRequest();
        req.requestURI = '/fslServices/getSlots/' + serviceAppointment.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        FSL_OrdersServiceHandler.GetSlotsResponseWrapper result = FSL_OrdersService.handleGetRequest();
        
        Test.stopTest();
        Assert.areEqual(
            'UNASSIGNED_APPOINTMENT', result.errorCode,
            'testGetSlotsUnassignedAppointmentError: Response should indicate UNASSIGNED_APPOINTMENT.'
        );
    }

    @isTest
    public static void testBookAppointmentValidServiceAppointment() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        String requestBody = '{"serviceAppointmentId": "' + serviceAppointment.Id + '"}';

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/fslServices/bookAppointment';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        FSL_OrdersServiceHandler.BookAppointmentResponseWrapper result = FSL_OrdersService.handlePostRequest();
        Test.stopTest();

        Assert.areEqual(true, result.status == 'Scheduled', 'testBookAppointmentValidServiceAppointment: Response should contain Scheduled.');
    }

    @isTest
    static void testBookAppointmentInvalidPath() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        String requestBody = '{"serviceAppointmentId": "' + serviceAppointment.Id + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/fslServices/invalidPath';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        FSL_OrdersServiceHandler.BookAppointmentResponseWrapper result = FSL_OrdersService.handlePostRequest();
        
        Assert.areEqual(true, result.errorCode == 'INVALID_PATH', 'testBookAppointmentInvalidPath: Response should indicate INVALID_PATH.');
    }

    @isTest
    static void testBookAppointmentException() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        String requestBody = '{"serviceAppointmentId": "' + serviceAppointment.Id + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/fslServices/bookAppointment';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        FSL_OrdersService.throwException = true;
        FSL_OrdersServiceHandler.BookAppointmentResponseWrapper serviceResult = FSL_OrdersService.handlePostRequest();

        Assert.areEqual(
            'INTERNAL_SERVER_ERROR', serviceResult.errorCode,
            'testBookAppointmentException:  Response should indicate INTERNAL_SERVER_ERROR for FSL_OrdersService.handlePostRequest.'
        );

        FSL_OrdersServiceHandler.throwException = true;
        Map<String, Object> handlerResult = FSL_OrdersServiceHandler.bookAppointment(requestBody);
        
        Assert.areEqual(
            'INTERNAL_SERVER_ERROR', (String)handlerResult.get('errorCode'),
            'testBookAppointmentException:  Response should indicate INTERNAL_SERVER_ERROR for FSL_OrdersServiceHandler.bookAppointment.'
        );
    }
    
    @isTest
    static void testBookAppointmentMissingParameterError() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/fslServices/bookAppointment';
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;
        FSL_OrdersServiceHandler.BookAppointmentResponseWrapper result = FSL_OrdersService.handlePostRequest();
        
        Assert.areEqual(
            'MISSING_PARAMETER', result.errorCode,
            'testBookAppointmentMissingParameterError: Response should indicate MISSING_PARAMETER.'
        );
    }

    @isTest
    static void testBookAppointmentResourceNotFoundError() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/fslServices/bookAppointment';
        req.requestBody = Blob.valueOf('{"serviceAppointmentId":"invalidServiceAppointmentId"}');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        FSL_OrdersServiceHandler.BookAppointmentResponseWrapper result = FSL_OrdersService.handlePostRequest();

        Assert.areEqual(
            'RESOURCE_NOT_FOUND', result.errorCode,
            'testBookAppointmentResourceNotFoundError: Response should indicate RESOURCE_NOT_FOUND.'
        );
    }

    @isTest
    static void testBookAppointmentNotMatchingResources() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        String requestBody = '{"serviceAppointmentId": "' + serviceAppointment.Id + '"}';

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/fslServices/bookAppointment';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        FSL_OrdersServiceHandler.BookAppointmentResponseWrapper result = FSL_OrdersService.handlePostRequest();
        Test.stopTest();
        
        Assert.areEqual(
            'NO_MATCHING_RESOURCES', result.errorCode,
            'testBookAppointmentNotMatchingResources: Response should indicate NO_MATCHING_RESOURCES.'
        );
    }
}