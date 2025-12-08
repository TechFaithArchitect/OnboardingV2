@isTest
public class FSL_ServiceBenchImagesApiTest {

    @TestSetup
    static void makeData() {

        WorkOrder wo = new WorkOrder(
            Status = 'Unscheduled',
            Vendor__c = 'COSTCO',
            External_WO_Id__c = '1234abc'
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
            Status = 'Unscheduled',
            ParentRecordId = wo.Id,
            FSSK__FSK_Work_Order__c = wo.Id,
            ServiceTerritoryId = st.Id
        );
        insert sa;

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document Version',
            PathOnClient = 'test.png',
            VersionData = Blob.valueOf('test')
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = wo.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = sa.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert new List<ContentDocumentLink> {cdl, cdl2};

    }

    @isTest
    static void testGetNewImages() {
       
        Test.startTest();

        String createdAfter = '2024-01-01T00:00:00Z';
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/serviceBenchImagesApi/';
        RestContext.request.params.put('createdAfter', createdAfter);
        RestContext.response = new RestResponse();

        FSL_ServiceBenchImagesApi.getNewImages();
        List<FSL_ServiceBenchImagesApi.ResponseWrapper> response = (List<FSL_ServiceBenchImagesApi.ResponseWrapper>) JSON.deserialize(RestContext.response.responseBody.toString(), List<FSL_ServiceBenchImagesApi.ResponseWrapper>.class);

        Test.stopTest();

        System.assertNotEquals(0, response.size(), 'The response list should not be empty.');
    }
}