@isTest
public class CSATabControllerTest {
    @isTest
    static void saveFileTest() {
        Blob testFileBody = Blob.valueOf('test file Body');
        String base64file = EncodingUtil.base64Encode(testFileBody);
        String testFileName = 'Test File Name.pdf';

        Test.startTest();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Order newOrd = new Order();
        newOrd.accountId = acc.Id;
        newOrd.EffectiveDate = System.today();
        newOrd.Status = 'Draft';
        insert newOrd;
        CSATabController.ResponseWrapper response = CSATabController.saveFile(
            new Map<String, Object>{ 'title' => testFileName, 'fileContents' => base64file, 'orderId' => newOrd.Id }
        );
        Test.stopTest();

        Assert.isFalse((Boolean) response.result.get('error'), 'Save File method failed - error should return false');
        Assert.isNotNull((String) response.result.get('documentId'), 'No documentId was returned ');
        Assert.isNotNull((String) response.result.get('contentVersionId'), 'No contentVersionId was returned ');
    }

    @isTest
    static void sendCSAFormEmailTest() {
        String testFirstName = 'Dave';
        String testLastName = 'Smith';
        String testBtn = '3043447162';
        Blob testFileBody = Blob.valueOf('test file Body');
        String testFileName = 'Test File Name.pdf';

        ContentVersion version = new ContentVersion(
            Title = testFileName,
            VersionData = testFileBody,
            pathOnClient = testFileName,
            ContentLocation = 'S'
        );
        insert version;

        version = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

        Test.startTest();
        CSATabController.ResponseWrapper response = CSATabController.sendCSAFormEmail(
            new Map<String, Object>{
                'firstName' => testFirstName,
                'lastName' => testLastName,
                'btn' => testBtn,
                'documentId' => version.ContentDocumentId,
                'contentVersionId' => version.Id
            }
        );
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, emailInvocations, 'No email was sent or email invocations were not updated as expected.');
        Assert.areEqual(
            false,
            response.result.get('error'),
            'The response includes an error when the operation was successful.'
        );
    }
}