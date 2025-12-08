@isTest
public class PV_TmoWorkCompletionControllerTest {
    @TestSetup
    static void makeTestData() {
        Test.startTest();

        Account acct = PV_TestDataFactory.createAccount('TestAcc', true);
        contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acct);
        
        OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
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
    static void addInventoryProductsTest() {
        Test.startTest();

        String woId = [SELECT Id FROM WOrkOrder LIMIT 1].Id;
        String serializesPd1 = [Select Id From Product2 where Name ='Serialized Product' limit 1].Id;
        String serializesPd2 = [Select Id From Product2 where Name ='Serialized Product1' limit 1].Id;
        String nonSerializesPd1 = [Select Id From Product2 where Name ='Non SZ Product 1' limit 1].Id;
        String nonSerializesPd2 = [Select Id From Product2 where Name ='Non SZ Product 2' limit 1].Id;
        String locationId = [Select Id From Location where Name ='Test Location 1' limit 1].Id;

        Map<String, Object> formData = new Map<String, Object>{
            'uploadArrivalCG' => '20',
            'downloadArrivalCG' => '25',
            'uploadDepartureCG' => '52',
            'downloadDepartureCG' => '25',
            'uploadArrivalIoT' => '25',
            'downloadArrivalIoT' => '25',
            'uploadDepartureIoT' => '25',
            'downloadDepartureIoT' => '25',
            'existingSIMNumber' => '2587',
            'existingMSISDNNumber' => '278278',
            'installedSIMNumber' => '78287',
            'installedMSISDNNumber' => '782828',
            'equipmentValidation1' => true,
            'installationRepair' => true,
            'siteSurveyAcknowledgement' => true,
            'Id' => woId 
        };
        
        String productJson = '[{"ProductId":\"'+serializesPd1+'\","ProductName":"MR28","SerialNumber":"1425858","Location":"Utility Closet","IsSerialized":true,"additionalProduct":false},{"ProductId":\"'+serializesPd2+'\","ProductName":"MG51e","SerialNumber":"741258","Location":"Conference Room","IsSerialized":true,"additionalProduct":true}]';

        List<SerializedProduct> serailizedProducts = [Select Id,ProductItemId ,Product2Id FROM SerializedProduct];
        PV_TmoWorkCompletionController.updateTmoDetails(formdata,productJson,locationId,serailizedProducts);
        PV_TmoWorkCompletionController.workTypeCheck(woId);
        PV_TmoWorkCompletionController.addInventoryProducts(formdata,productJson,locationId);
        PV_TmoWorkCompletionController.statusCheck(woId);
        Test.stopTest();
    }

    @isTest
    static void locationCheckTest() {
        Test.startTest();
        String workOrderId = [SELECT Id FROM WOrkOrder LIMIT 1].Id;
        ServiceResource serviceResource = [SELECT RelatedRecordId FROM ServiceResource LIMIT 1];

        // Desktop user
        String locationId = PV_TmoWorkCompletionController.locationCheck(UserInfo.getUserId(), workOrderId, true);
        Assert.areNotEqual(null, locationId, 'Unable to retrieve the Service Resource location');

        // Technician
        locationId = PV_TmoWorkCompletionController.locationCheck(serviceResource.RelatedRecordId, workOrderId, false);
        Assert.areNotEqual(null, locationId, 'Unable to retrieve the Service Resource location');
        Test.stopTest();
    }
}