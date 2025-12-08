@isTest
public with sharing class FSL_DynamicCompletionForm_ControllerTest {

    @TestSetup
    static void makeTestData() {
        Test.startTest();

        Completion_Form_Template__c template = new Completion_Form_Template__c(
            Name = 'Test Template',
            Active__c = true,
            Vendor__c = 'T-Mobile',
            Section_Order__c = '"Section A";"Section B"',
            Location_Products_Consumed__c = true
        );
        insert template;

        Completion_Form_Configuration__c field1 = new Completion_Form_Configuration__c(
            Name = 'Upload Speed (Arrival) CG',
            Field_API_Name__c = 'Cellular_Gateway_Router_Arrival_Spe__c',
            Section_Name__c = 'Section A',
            Order_Within_Section__c = 1,
            Completion_Form_Template__c = template.Id
        );

        Completion_Form_Configuration__c field2 = new Completion_Form_Configuration__c(
            Name = 'Download Speed (Arrival) CG',
            Field_API_Name__c = 'Cellular_Gateway_Router_Download_Spee__c',
            Section_Name__c = 'Section A',
            Order_Within_Section__c = 2,
            Completion_Form_Template__c = template.Id
        );

        Completion_Form_Configuration__c field3 = new Completion_Form_Configuration__c(
            Name = 'Upload Speed (Arrival) IoT',
            Field_API_Name__c = 'Tablet_IoT_Device_Arrival_Upload_Speed__c',
            Section_Name__c = 'Section B',
            Order_Within_Section__c = 1,
            Completion_Form_Template__c = template.Id
        );

        Completion_Form_Configuration__c field4 = new Completion_Form_Configuration__c(
            Name = 'Download Speed (Arrival) IoT',
            Field_API_Name__c = 'Tablet_IoT_Device_Arrival_Download_Speed__c',
            Section_Name__c = 'Section B',
            Order_Within_Section__c = 2,
            Completion_Form_Template__c = template.Id
        );

        insert new List<Completion_Form_Configuration__c>{field1, field2, field3, field4};

        Account acct = PV_TestDataFactory.createAccount('TestAcc', true);
        contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acct);
        
        OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acct, pst);
        
        User usr = PV_TestDataFactory.createTechnicianUser(true,con);

        System.runAs(usr) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }
        
        ServiceResource sr = PV_TestDataFactory.createServiceResource(true,acct,con,usr);
        sr.Manager__c = UserInfo.getUserId();
        update sr;
        
        ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true, sr, childServiceTerritory, 'P');

        WorkType wt1 = new WorkType();
        wt1.Name = 'T-Mobile Commercial Service Call - 12 Hour';
        wt1.DurationType = 'Minutes';
        wt1.EstimatedDuration = 60;
        wt1.Vendor__c = 'T-Mobile';
        insert wt1;
        
        WorkOrder wo1 = new WorkOrder();
        wo1.Status = 'Onsite';
        wo1.WorkTypeId = wt1.Id;
        wo1.Vendor__c = 'T-Mobile';
        insert wo1;

        ServiceAppointment sa1 = new ServiceAppointment();
        sa1.Status = 'Onsite';
        sa1.ParentRecordId = wo1.Id;
        sa1.FSSK__FSK_Work_Order__c = wo1.Id;
        sa1.WorkTypeId = wt1.Id;
        sa1.SchedStartTime = System.Today();
        sa1.SchedEndTime = System.now().addHours(3);
        sa1.DueDate = System.today().adddays(4);
        sa1.EarliestStartTime = System.now();
        insert sa1;

        Product2 pd1 = PV_TestDataFactory.createProduct(true,true,'Serialized Product');
        Product2 pd2 = PV_TestDataFactory.createProduct(true,true,'Serialized Product1');
        Product2 pd3 = PV_TestDataFactory.createProduct(true,false,'Non SZ Product 1');
        Product2 pd4 = PV_TestDataFactory.createProduct(true,false,'Non SZ Product 2');

        sr = [SELECT Id FROM ServiceResource LIMIT 1];

        Schema.Location loc1 = new Schema.Location(
            Name = 'Test Location 1',
            LocationType = 'Van',
            IsMobile = true,
            IsInventoryLocation = true,
            Service_Resource__c = sr.Id
        );
        insert loc1;

        AssignedResource assignedResource = new AssignedResource(
            ServiceResourceId = sr.Id,
            ServiceAppointmentId = sa1.Id
        );
        insert assignedResource;

        Test.stopTest();
    }
    
    @isTest
    static void submitProductsTest() {
        Test.startTest();
        String woId = [SELECT Id FROM WOrkOrder LIMIT 1].Id;
        String serializesPd1 = [SELECT Id FROM Product2 WHERE Name ='Serialized Product' LIMIT 1].Id;
        String serializesPd2 = [SELECT Id FROM Product2 WHERE Name ='Serialized Product1' LIMIT 1].Id;
        String nonSerializesPd1 = [SELECT Id FROM Product2 WHERE Name ='Non SZ Product 1' LIMIT 1].Id;
        String nonSerializesPd2 = [SELECT Id FROM Product2 WHERE Name ='Non SZ Product 2' LIMIT 1].Id;
        String locationId = [SELECT Id FROM Location WHERE Name ='Test Location 1' LIMIT 1].Id;

        WorkOrder wo = new WorkOrder(
            Id = woId,
            Cellular_Gateway_Router_Arrival_Spe__c = '20',
            Cellular_Gateway_Router_Download_Spee__c = '25',
            Departure_Upload_Speed__c = '52',
            Cellular_Gateway_Router_Departure_downlo__c = '25',
            Tablet_IoT_Device_Arrival_Upload_Speed__c = '25',
            Tablet_IoT_Device_Arrival_Download_Speed__c = '25',
            Tablet_IoT_Departur_Upolad_Speed__c = '25',
            Tablet_IoT_Departur_Download_Speed__c = '25',
            Existing_SIM_Number__c = '2587',
            Existing_MSISDN_Number_if_applicable__c = '278278',
            Installed_SIM_Number__c = '78287',
            Installed_MSISDN_Number__c = '782828',
            Equipment_Testing_and_Service_Validatio__c = true,
            Acceptance_of_Installation_Service_Repai__c = true,
            Site_Survey_Acknowledgement__c = true
        );
        
        String productJson = '[{"ProductId":\"'+serializesPd1+'\","ProductName":"MR28","SerialNumber":"1425858","Location":"Utility Closet","IsSerialized":true,"additionalProduct":false,"Quantity":"1"},{"ProductId":\"'+serializesPd2+'\","ProductName":"MG51e","SerialNumber":"741258","Location":"Conference Room","IsSerialized":true,"Quantity":"1"},{"ProductId":\"'+nonSerializesPd1+'\","ProductName":"Non Serialized Product 1","SerialNumber":"","Location":"Main Area","IsSerialized":false,"additionalProduct":false,"Quantity":"2"},{"ProductId":\"'+nonSerializesPd2+'\","ProductName":"Non Serialized Product 2","SerialNumber":"","Location":"Secondary Area","IsSerialized":false,"additionalProduct":false,"Quantity":"1"}]';

        List<SerializedProduct> serailizedProducts = [SELECT Id,ProductItemId ,Product2Id FROM SerializedProduct];
        FSL_DynamicCompletionForm_Controller.updateTmoDetails(wo,productJson,locationId,serailizedProducts);
        FSL_DynamicCompletionForm_Controller.submitProducts(wo,productJson,locationId);
        Test.stopTest();
    }

    @isTest
    static void testGetConfiguration() {
        Test.startTest();
        WorkOrder testWO = [SELECT Id, Vendor__c FROM WorkOrder LIMIT 1];
        FSL_DynamicCompletionForm_Controller.DataWrapper result = FSL_DynamicCompletionForm_Controller.getConfiguration(testWO.Id, true);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success to be true');
    }
}