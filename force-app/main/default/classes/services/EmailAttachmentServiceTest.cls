@isTest
private class EmailAttachmentServiceTest {

    @isTest
    static void testGetAttachments_withLegacyAttachment() {
        Attachment legacy = new Attachment(
            Name = 'Legacy.txt',
            Body = Blob.valueOf('Legacy Content'),
            ContentType = 'text/plain',
            ParentId = UserInfo.getUserId()
        );
        insert legacy;

        Test.startTest();
        List<Messaging.EmailFileAttachment> results =
            EmailAttachmentService.getAttachments(new List<Id>{ legacy.Id });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one attachment');
        System.assertEquals('Legacy.txt', results[0].getFileName());
    }

    @isTest
    static void testGetAttachments_withContentVersion() {
        // ✅ Create ContentVersion with valid writable fields
        ContentVersion cv = new ContentVersion(
            Title = 'Doc1',
            PathOnClient = 'Doc1.pdf',
            VersionData = Blob.valueOf('PDF Data')
        );
        insert cv;

        // ✅ Create link (simulate a real shared file)
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = UserInfo.getUserId(),
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        List<Messaging.EmailFileAttachment> results =
            EmailAttachmentService.getAttachments(new List<Id>{ cv.ContentDocumentId });
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return a ContentVersion attachment');
        System.assert(results[0].getFileName().startsWith('Doc1'), 'Should contain filename from ContentVersion');
    }
}
