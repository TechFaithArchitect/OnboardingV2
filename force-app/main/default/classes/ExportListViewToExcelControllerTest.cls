@isTest
private class ExportListViewToExcelControllerTest {
     @isTest static void testAllAccountList() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        PageReference pageRef = Page.ExportListViewToExcel;
        Test.setCurrentPage(pageRef);
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User']; // Replace with the appropriate profile name
        User newUser = new User(
            Alias = 'testUser',
            Email = 'testuser125@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser5888@example.com'
        );
        insert newUser;
        List<ServiceResource> testRecords = new List<ServiceResource>();
        for (Integer i = 0; i < 1; i++) {
            testRecords.add(new ServiceResource(Name = 'Test Record ' + i,ResourceType ='T',RelatedRecordId = newUser.Id));
        }
        insert testRecords;
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(testRecords);
        ExportListViewToExcelController extension = new ExportListViewToExcelController(stdSetController);
        pageRef.getParameters().put('vfRetURLInSFX', 'https://perfectvisionpoe--impdev.sandbox.lightning.force.com/lightning/o/ServiceResource/list?filterName=00B5f00000Q1q66EAB');
        pageRef.getParameters().put('Object', 'Account');
        pageRef.getParameters().put('listName', 'All Account');
        Test.startTest();
        extension.fetchListviewRecords();
        Test.StopTest();
    }  

}