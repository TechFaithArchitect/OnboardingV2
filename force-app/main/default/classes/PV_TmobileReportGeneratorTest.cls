@isTest
public class PV_TmobileReportGeneratorTest {

    @isTest
    static void testConstructor() {
       
        WorkOrder wo = new WorkOrder();
        wo.Subject = 'Test Work Order';
        wo.Vendor__c = 'T-Mobile';
        insert wo;

       
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'Test Image 1';
        cv1.PathOnClient = 'testimage1.jpg';
        cv1.VersionData = Blob.valueOf('Test Image 1');
        cv1.FirstPublishLocationId = wo.Id;
        insert cv1;

        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'Test Image 2';
        cv2.PathOnClient = 'testimage2.png';
        cv2.VersionData = Blob.valueOf('Test Image 2');
        cv2.FirstPublishLocationId = wo.Id;
        insert cv2;

       


        Test.startTest();
        PageReference pageRef = Page.TmobileCloseOutReport; 
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(wo);
        PV_TmobileReportGenerator reportGenerator = new PV_TmobileReportGenerator(stdController);
        Test.stopTest();

    }
}