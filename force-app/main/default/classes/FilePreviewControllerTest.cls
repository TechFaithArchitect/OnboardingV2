@isTest
public class FilePreviewControllerTest {
    @TestSetup
    static void makeData() {
        UserLicense licence = [SELECT Id FROM UserLicense WHERE Name = 'Salesforce'];
        Profile profile = [SELECT Id FROM Profile WHERE UserLicenseId = :licence.Id LIMIT 1];

        System.runAs(new User(Id = UserInfo.getUserId())) {
            User testUser = new User();
            testUser.FirstName = 'Test';
            testUser.LastName = 'User';
            testUser.Email = 'randomtestuser@scienzadevtest.' + String.valueOf(Datetime.now().getTime()) + '.com';
            testUser.UserName = 'randomtestuser@scienzadevtest.' + String.valueOf(Datetime.now().getTime()) + '.com';
            testUser.EmailEncodingKey = 'UTF-8';
            testUser.Alias = 'testuser';
            testUser.LanguageLocaleKey = 'en_US';
            testUser.LocaleSidKey = 'en_US';
            testUser.ProfileId = profile.Id;
            testUser.TimeZoneSidKey = 'America/Los_Angeles';
            insert testUser;

            List<ContentWorkspace> cws = [SELECT Id FROM ContentWorkspace WHERE Name = 'Asset Library'];

            ContentVersion cv = new ContentVersion();
            cv.Description = 'test description';
            cv.PathOnClient = 'test_file.pdf';
            cv.Title = 'test file ' + DateTime.now();
            cv.versiondata = Blob.valueOf('test file body');
            insert cv;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id]
            .ContentDocumentId;
            cdl.LinkedEntityId = cws[0].Id;
            cdl.ShareType = 'I';
            insert cdl;
        }
    }

    @isTest
    private static void getRelatedFilesByRecordIdTest() {
        List<User> user = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test'];
        List<ContentWorkspace> cws = [SELECT Id FROM ContentWorkspace WHERE Name = 'Asset Library'];
        Map<String, Object> inputMap = new Map<String,Object>();
        inputMap.put('libraryName', 'Asset Library'); 

        Test.startTest();
        FilePreviewController.ResponseWrapper response = FilePreviewController.getRelatedFilesByRecordId(
            inputMap
        );
        Test.stopTest();
        
        List<Object> documents = (List<Object>) response.result.get('Documents');
        System.assert(documents != null && documents.size() > 0, 
            'No files were included in the response.'
        );
    }
}