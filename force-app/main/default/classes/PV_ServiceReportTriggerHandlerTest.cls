@isTest
public class PV_ServiceReportTriggerHandlerTest {
    public static final String TEST_VENDOR = 'T-Mobile';

    @testSetup
    static void makeTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            WorkType workType = PV_TestDataFactory.createWorkType('ImpSkill',true);
            WorkOrder workOrder = new WorkOrder();
            workOrder.External_WO_Id__c = 'Id-' + System.now();
            workOrder.Status = 'Unscheduled';
            workOrder.OwnerId = UserInfo.getUserId();
            workOrder.WorkTypeId = workType.Id;
            workOrder.Vendor__c = TEST_VENDOR;
            insert workOrder;

            ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
            serviceAppointment.FSSK__FSK_Work_Order__c = workOrder.Id;
            update serviceAppointment;
        }
    }
    
    @isTest 
    static void sendingSignedReportForWorkOrder() {
        Test.startTest();
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = wo.id;
        cdl.ContentDocumentId = document.Id;
        cdl.shareType = 'V';
        insert cdl;
        
        ServiceReport sr = new ServiceReport();
        sr.DocumentBody = Blob.valueOf('Test Content'); 
        sr.DocumentContentType = 'application/pdf';
        sr.DocumentName = 'Test';
        sr.ParentId = wo.id; 
        sr.IsSigned = true;
        insert sr ;
        Test.stopTest();
    }

    @isTest 
    static void sendingSignedReportForServiceAppointment() {
        Test.startTest();
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        ContentVersion contentVersion = new ContentVersion(
            Title = 'OriginalName',
            PathOnClient = 'OriginalFile.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        ContentDocumentLink contentDocumentLink = New ContentDocumentLink();
        contentDocumentLink.LinkedEntityId = serviceAppointment.Id;
        contentDocumentLink.ContentDocumentId = document.Id;
        contentDocumentLink.shareType = 'V';
        insert contentDocumentLink;

        ServiceReport serviceReport = new ServiceReport();
        serviceReport.DocumentBody = Blob.valueOf('Test Content'); 
        serviceReport.DocumentContentType = 'application/pdf';
        serviceReport.DocumentName = 'Test';
        serviceReport.ParentId = serviceAppointment.Id; 
        serviceReport.IsSigned = true;
        insert serviceReport;
        Test.stopTest();

        List<ContentVersion> documents = [SELECT Id, Title FROM ContentVersion WHERE Title <> :contentVersion.Title];
        Assert.areNotEqual(0, documents.size(), 'A document with a new title was expected');
    }
}