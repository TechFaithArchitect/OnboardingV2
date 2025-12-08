@isTest
public class DynamicRelatedListPaneControllerTest {
    @TestSetup
    static void makeData() {
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        User adminUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;
        update adminUser;
        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];

        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test Account',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
                P10_Invoice_Account__c = 'Example',
                POE_Spectrum_AffiliateId__c = 'test',
                recordTypeId = rtype.Id
            );
            insert testAcc;
            Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
            insert userContact;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'Owner Profile'];
            User u = new User(
                Alias = 'standt',
                Email = '11052022standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '11052022GDGstandarduser@testorg.com'
            );
            insert u;

            Opportunity opp = new Opportunity(
                Name = 'test opp',
                StageName = 'Presentation',
                CloseDate = Date.today(),
                POE_Dealer__c = testAcc.Id
            );
            insert opp;
        }
    }

    @isTest
    public static void getRecordsByCriteriaTest() {
        Account acct = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputData = new Map<String, Object>{
            'parentRecordId' => acct.Id,
            'objectName' => 'Opportunity',
            'fieldList' => 'Name, StageName, Amount',
            'filterCriteria' => 'POE_Dealer__c = '
        };

        Test.startTest();
        List<SObject> response = DynamicRelatedListPaneController.getRecordsByCriteria(inputData);
        Test.stopTest();

        Assert.areEqual(0, response.size(), 'An Opportunity record should be found');
    }

    @isTest
    public static void getParentRecordInfoTest() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Object> result = DynamicRelatedListPaneController.getParentRecordInfo(testAccount.Id);
        Test.stopTest();

        String sobjectPluralLabel = (String) result.get('sobjectPluralLabel');
        String sobjectApiName = (String) result.get('sobjectApiName');
        String parentRecordLabel = (String) result.get('parentRecordLabel');
        Assert.areEqual('Accounts', sobjectPluralLabel, 'The SObject\'s plural label was not correct');
        Assert.areEqual('Account', sobjectApiName, 'The SObject\'s API name was not correct');
        Assert.areEqual(testAccount.Name, parentRecordLabel, 'The parent record\'s name was not correct');
    }
}