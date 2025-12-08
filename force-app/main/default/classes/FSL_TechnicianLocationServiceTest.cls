@isTest
public with sharing class FSL_TechnicianLocationServiceTest {
    
    @TestSetup
    static void setupTestData() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Dispatched');
        Account testAccount = PV_TestDataFactory.createAccount('Test Dealer', true);
        Contact testContact = PV_TestDataFactory.createContact('John', 'Technician', true, testAccount);
        
        User testUser = PV_TestDataFactory.createTechnicianUser(false, testContact);
        testUser.FirstName = 'John';
        testUser.LastName = 'Technician';
        insert testUser;

        System.runAs(testUser) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, testUser, 'FSL_Technician');
        }
        
        ServiceResource serviceResource = new ServiceResource(
            Name = 'Test Service Resource',  
            RelatedRecordId = testUser.Id
        );
        insert serviceResource;
        
        OperatingHours operatingHours = PV_TestDataFactory.createOperatingHours('Test Operating Hours', false);
        operatingHours.TimeZone = UserInfo.getTimeZone().getID();
        insert operatingHours;
        
        ServiceTerritory serviceTerritory = PV_TestDataFactory.createParentServiceTerritory(true, 'Test Territory', operatingHours);
        
        WorkType workType = PV_TestDataFactory.createWorkType('Test Work Type', true);
        
        WorkOrder workOrder = PV_TestDataFactory.createWorkOrder(testUser, workType, true);

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :workOrder.Id LIMIT 1];
        serviceAppointment.FSSK__FSK_Assigned_Service_Resource__c = serviceResource.Id;
        serviceAppointment.Status = 'Dispatched';
        serviceAppointment.Street = '123 Test Street';
        serviceAppointment.City = 'Test City';
        serviceAppointment.State = 'California';
        serviceAppointment.PostalCode = '91750';
        serviceAppointment.Country = 'United States';
        serviceAppointment.Dealer__c = testAccount.Id;
        serviceAppointment.ServiceTerritoryId = serviceTerritory.Id;
        serviceAppointment.SchedStartTime = DateTime.now().addHours(1);
        serviceAppointment.SchedEndTime = DateTime.now().addHours(2);
        update serviceAppointment;
    }
    
    @isTest
    static void testGetTechnicianLocation() {
        ServiceAppointment testSA = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        List<String> encryptedIds = new List<String>();
        EncryptSAForSelfScheduling.EncryptionInput input = new EncryptSAForSelfScheduling.EncryptionInput();
        input.recordIdList = testSA.Id;
        input.url = 'https://test.com';
        input.encodeRecordId = true;
        
        List<EncryptSAForSelfScheduling.EncryptionInput> inputs = new List<EncryptSAForSelfScheduling.EncryptionInput>{input};
        List<String> encryptedURLs = EncryptSAForSelfScheduling.encrypt(inputs);
        
        String encryptedId = encryptedURLs[0].substringAfter('recordId=');
        List<String> encryptedServiceAppointmentIds = new List<String>{encryptedId};
        
        Test.startTest();
        List<FSL_TechnicianLocationService.TechnicianLocationOutput> results = 
            FSL_TechnicianLocationService.getTechnicianLocation(encryptedServiceAppointmentIds);
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        
        FSL_TechnicianLocationService.TechnicianLocationOutput result = results[0];
        Assert.areEqual('Dispatched', result.serviceAppointmentStatus, 'Status should match');
        Assert.isTrue(result.serviceAppointmentAddress.contains('123 Test Street'), 'Address should contain street');
        Assert.isTrue(result.serviceAppointmentAddress.contains('Test City'), 'Address should contain city');
        Assert.isTrue(result.serviceAppointmentAddress.contains('California'), 'Address should contain state');
        Assert.isTrue(result.serviceAppointmentAddress.contains('91750'), 'Address should contain postal code');
        Assert.isTrue(result.serviceAppointmentAddress.contains('United States'), 'Address should contain country');
        Assert.areNotEqual(null, result.serviceAppointmentStartTime, 'Start time should not be null');
        Assert.areNotEqual(null, result.serviceAppointmentEndTime, 'End time should not be null');
        Assert.areEqual('Test Dealer', result.dealerName, 'Dealer name should match');
        Assert.areEqual('John', result.technicianFirstName, 'Technician first name should match');
        Assert.areEqual('John Technician', result.technicianName, 'Technician name should match');
    }
}