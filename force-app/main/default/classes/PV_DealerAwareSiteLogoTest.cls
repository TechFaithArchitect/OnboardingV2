@isTest
public with sharing class PV_DealerAwareSiteLogoTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = PV_TestDataFactory.createAccount('Test Dealer Account', true);
        Contact testContact = PV_TestDataFactory.createContact('Test', 'Contact', true, testAccount);
        
        User testUser = PV_TestDataFactory.createTechnicianUser(false, testContact);
        testUser.FirstName = 'Test';
        testUser.LastName = 'User';
        testUser.CommunityNickname = 'TestUser' + Math.random();
        insert testUser;

        System.runAs(testUser) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, testUser, 'FSL_Dispatcher_and_Technician');
        }
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Logo',
            PathOnClient = 'test-logo.png',
            VersionData = Blob.valueOf('Test Logo Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Title = 'Test Logo' LIMIT 1];
        
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = testAccount.Id;
        contentLink.ContentDocumentId = contentDocument.Id;
        contentLink.ShareType = 'V';
        contentLink.Visibility = 'AllUsers';
        insert contentLink;
        
        testAccount.Logo_Content_Document_Id__c = contentDocument.Id;
        update testAccount;
    }
    
    @isTest
    static void testGetSiteLogoWithValidLogo() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
        
        String result;
        Test.startTest();
        System.runAs(testUser) {
            result = PV_DealerAwareSiteLogo.getSiteLogo();
        }
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a valid URL for the logo');
    }
    
    @isTest
    static void testGetSiteLogoUserWithoutAccount() {
        String uniqueUsername = 'testuser' + DateTime.now().getTime() + '@test.com';

        User newUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = uniqueUsername,
            Username = uniqueUsername,
            Alias = 'testuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert newUser;
        
        String result;
        Test.startTest();
        System.runAs(newUser) {
            result = PV_DealerAwareSiteLogo.getSiteLogo();
        }
        Test.stopTest();

        Assert.isNull(result, 'Should return null for user without account');
    }
    
    @isTest
    static void testGetSiteLogoAccountWithoutLogo() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Dealer Account' LIMIT 1];
        
        testAccount.Logo_Content_Document_Id__c = null;
        update testAccount;
        
        String result;
        Test.startTest();
        System.runAs(testUser) {
            result = PV_DealerAwareSiteLogo.getSiteLogo();
        }
        Test.stopTest();

        Assert.isNull(result, 'Should return null when account has no logo content document');
    }
}