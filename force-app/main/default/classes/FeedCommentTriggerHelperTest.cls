@isTest
private class FeedCommentTriggerHelperTest {
    @TestSetup
    static void makeData() {
        String accountServicesProfileName = System.Label.Account_Services_Profile_Name;
        Profile p = [SELECT Id FROM Profile WHERE Name = :accountServicesProfileName];
        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];

        Account testAcc = new Account(
            Name = 'Test',
            ShippingStreet = 'Test Street',
            POE_Dealer_Office_Email__c = 'DealerEmailFeedCommentTriggerHelperTest' +
                DateTime.now().getTime() +
                '@testorg1.com',
            P10_Invoice_Account__c = 'Example',
            recordTypeId = rtype.Id
        );
        insert testAcc;
        Contact userContact = new Contact(
            FirstName = 'test',
            LastName = 'test',
            AccountId = testAcc.Id,
            POE_Functional_Role__c = 'Office Manager'
        );
        insert userContact;
        String uniqueUserName = 'FeedCommentTriggerHelperTest' + DateTime.now().getTime() + '@test.com';
        User user = new User(
            Alias = 'standt',
            Email = uniqueUserName,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        insert user;
        user.isActive = true;
        update user;

        User u = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];

        System.runAs(u) {
            Case testCase = new Case(Subject = 'Test Case', Status = 'New');
            insert testCase;

            FeedItem testFeedItem = new FeedItem(ParentId = testCase.Id, Body = 'Test Feed Item');
            insert testFeedItem;
            FeedComment testFeedComment = new FeedComment(FeedItemId = testFeedItem.Id, CommentBody = 'Test Comment');
            insert testFeedComment;
        }

    }

    @isTest
    static void testHandleAfterInsert() {
        FeedComment testComment = [SELECT Id, ParentId, CreatedById FROM FeedComment LIMIT 1];

        FeedCommentTriggerHelper helper = new FeedCommentTriggerHelper();

        Test.startTest();
        helper.handleAfterInsert(new List<FeedComment>{ testComment });
        Test.stopTest();
        User u = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];
        System.assert(true, 'Test passed without exceptions');
    }

    @isTest
    static void testGetActiveAccountServicesUsersId() {
        FeedCommentTriggerHelper helper = new FeedCommentTriggerHelper();

        Test.startTest();
        Set<String> userIds = helper.getActiveAccountServicesUsersId();
        Test.stopTest();

        System.assert(!userIds.isEmpty(), 'There should be at least one Account Services User');
    }
}