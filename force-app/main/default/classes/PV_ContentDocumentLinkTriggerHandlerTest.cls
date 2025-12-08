@isTest
public class PV_ContentDocumentLinkTriggerHandlerTest {
    static String docURL = FSL_Settings__c.getInstance().Document_URL__c;
    static String DirecTV = Label.DirecTV_Skills;
    static String viasat = Label.ViaSat_Skills;
    static String DirecTVval = Label.DIRECTV;
    static String ViaSatval = Label.ViaSat;
    @isTest
    static void testTriggerLogic() {
        // Step 1: Set up test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        WorkType wType = new WorkType();
        wType.Name ='Viasat Commercial Service Call';
        wType.DurationType = 'Minutes';
        wType.EstimatedDuration = 90;
        insert wType;
        WorkOrder wo = new WorkOrder();
        wo.Status = 'Complete';
        wo.WorkTypeId = wType.Id;
        wo.Vendor__c = DirecTVval;
        wo.AccountId = acc.Id;
        insert wo;
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'testDocument.txt',
            VersionData = Blob.valueOf('Test Content')
            
        );
        insert cv;
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id) LIMIT 1];
        All_Images__c obj = new All_Images__c();
        obj.ImageURL__c = docURL;
        obj.Content_Document_Id__c = cd.Id;
        obj.Work_Order__c = wo.Id;
        insert obj;
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        // Create a ContentDocumentLink record
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = wo.Id, // Link to Account
            ContentDocumentId = cd.Id,
            ShareType = 'V', // View access
            Visibility = 'AllUsers' // Visible to all users
        );
        
        // Step 2: Call the trigger manually
        Test.startTest();
        insert cdl;
        Test.stopTest();  
    }
    @isTest
    static void testContentDocumentDeleteTrigger() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'testDocument.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        WorkType wType = new WorkType();
        wType.Name ='Viasat Commercial Service Call';
        wType.DurationType = 'Minutes';
        wType.EstimatedDuration = 90;
        insert wType;
        WorkOrder wo = new WorkOrder();
        wo.Status = 'Complete';
        wo.WorkTypeId = wType.Id;
        wo.Vendor__c = DirecTVval;
        wo.AccountId = acc.Id;
        insert wo;
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id) LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = wo.Id, // Link to Account
            ContentDocumentId = cd.Id,
            ShareType = 'V', // View access
            Visibility = 'AllUsers' // Visible to all users
        );
        insert cdl;
        All_Images__c obj = new All_Images__c();
        obj.ImageURL__c = docURL;
        obj.Content_Document_Id__c = cd.Id;
        obj.Work_Order__c = wo.Id;
        insert obj;
        delete cd;
    }
}