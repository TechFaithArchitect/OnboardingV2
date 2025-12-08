@IsTest
private class ContentDistributionCreatorTest {
    
    @TestSetup
    static void setupTestData() {
        // Create a test ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test File';
        cv.PathOnClient = 'test.txt';
        cv.VersionData = Blob.valueOf('Test content');
        insert cv;
        
        // Create a test video ContentVersion
        ContentVersion videoCV = new ContentVersion();
        videoCV.Title = 'Test Video';
        videoCV.PathOnClient = 'test.mp4';
        videoCV.VersionData = Blob.valueOf('Test video content');
        insert videoCV;
    }
    
    @IsTest
    static void testCreatePublicLink_Success() {
        // Get the test ContentVersion
        ContentVersion testCV = [SELECT Id FROM ContentVersion WHERE Title = 'Test File' LIMIT 1];
        
        // Create request
        ContentDistributionCreator.ContentDistributionRequest request = 
            new ContentDistributionCreator.ContentDistributionRequest();
        request.contentVersionId = testCV.Id;
        
        List<ContentDistributionCreator.ContentDistributionRequest> requests = 
            new List<ContentDistributionCreator.ContentDistributionRequest>{request};
        
        Test.startTest();
        List<ContentDistributionCreator.ContentDistributionResult> results = 
            ContentDistributionCreator.createPublicLink(requests);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Operation should be successful');
        System.assertNotEquals(null, results[0].distributionPublicUrl, 'Should have a public URL');
        System.assertEquals(null, results[0].errorMessage, 'Should not have error message');
        System.assertEquals(false, results[0].isVideo, 'Should not be identified as video');
        System.assertNotEquals(null, results[0].fileForcePublicUrl, 'Should have fileForce public URL');
        System.assertNotEquals(null, results[0].documentForcePublicUrl, 'Should have documentForce public URL');
        
        // Verify ContentDistribution was created
        List<ContentDistribution> distributions = [
            SELECT Id, ContentVersionId, DistributionPublicUrl 
            FROM ContentDistribution 
            WHERE ContentVersionId = :testCV.Id
        ];
        System.assertEquals(1, distributions.size(), 'Should create one ContentDistribution');
    }
    
    @IsTest
    static void testCreatePublicLink_VideoFile() {
        // Get the test video ContentVersion
        ContentVersion testVideoCV = [SELECT Id FROM ContentVersion WHERE Title = 'Test Video' LIMIT 1];
        
        // Create request
        ContentDistributionCreator.ContentDistributionRequest request = 
            new ContentDistributionCreator.ContentDistributionRequest();
        request.contentVersionId = testVideoCV.Id;
        
        List<ContentDistributionCreator.ContentDistributionRequest> requests = 
            new List<ContentDistributionCreator.ContentDistributionRequest>{request};
        
        Test.startTest();
        List<ContentDistributionCreator.ContentDistributionResult> results = 
            ContentDistributionCreator.createPublicLink(requests);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Operation should be successful');
        System.assertEquals(true, results[0].isVideo, 'Should be identified as video');
        System.assertNotEquals(null, results[0].fileForcePublicUrl, 'Should have fileForce public URL');
        System.assertNotEquals(null, results[0].documentForcePublicUrl, 'Should have documentForce public URL');
    }
    
    @IsTest
    static void testCreatePublicLink_MultipleFiles() {
        // Get both test ContentVersions
        List<ContentVersion> testCVs = [SELECT Id FROM ContentVersion WHERE Title IN ('Test File', 'Test Video')];
        
        // Create requests for both files
        List<ContentDistributionCreator.ContentDistributionRequest> requests = 
            new List<ContentDistributionCreator.ContentDistributionRequest>();
        
        for(ContentVersion cv : testCVs) {
            ContentDistributionCreator.ContentDistributionRequest request = 
                new ContentDistributionCreator.ContentDistributionRequest();
            request.contentVersionId = cv.Id;
            requests.add(request);
        }
        
        Test.startTest();
        List<ContentDistributionCreator.ContentDistributionResult> results = 
            ContentDistributionCreator.createPublicLink(requests);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(2, results.size(), 'Should return two results');
        System.assertEquals(true, results[0].isSuccess, 'First operation should be successful');
        System.assertEquals(true, results[1].isSuccess, 'Second operation should be successful');
        
        // Verify ContentDistributions were created
        List<ContentDistribution> distributions = [
            SELECT Id, ContentVersionId 
            FROM ContentDistribution 
            WHERE ContentVersionId IN :testCVs
        ];
        System.assertEquals(2, distributions.size(), 'Should create two ContentDistributions');
    }
    
    @IsTest
    static void testCreatePublicLink_EmptyRequest() {
        List<ContentDistributionCreator.ContentDistributionRequest> requests = 
            new List<ContentDistributionCreator.ContentDistributionRequest>();
        
        Test.startTest();
        List<ContentDistributionCreator.ContentDistributionResult> results = 
            ContentDistributionCreator.createPublicLink(requests);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty results for empty request');
    }
    
    @IsTest
    static void testCreatePublicLink_NullContentVersionId() {
        ContentDistributionCreator.ContentDistributionRequest request = 
            new ContentDistributionCreator.ContentDistributionRequest();
        request.contentVersionId = null;
        
        List<ContentDistributionCreator.ContentDistributionRequest> requests = 
            new List<ContentDistributionCreator.ContentDistributionRequest>{request};
        
        Test.startTest();
        List<ContentDistributionCreator.ContentDistributionResult> results = 
            ContentDistributionCreator.createPublicLink(requests);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty results for null ContentVersionId');
    }
}