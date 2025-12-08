@isTest
public class ClickerControllerTest {
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
                recordTypeId = rtype.Id
            );
            insert testAcc;

            Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
            insert userContact;

            Profile p = TestHelper.getGeneralProfile();
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
        }
    }
    
    @isTest
    static void testGetClickerCallCenterTrack() {
        List<User> user = [SELECT Id, AccountId FROM User WHERE LastName = 'Testing' LIMIT 1];
        
        test.startTest();
        Map<String, Object> result = ClickerController.getClickerCallCenterTrack(user[0].Id, null);
        System.debug('result:   '+result);
        test.stopTest();
        System.assert(result != null, 'Call Center Track is Null');
    }

    @isTest
    static void testGetStoreSuccess() {
        POE_Retail_Store__c retailStore = new POE_Retail_Store__c(
            Name = 'Test Store',
            POE_City__c = 'San Francisco',
            POE_State__c = 'California',
            POE_Street_Address__c = '416 Mission Street',
            POE_Zip_Code__c = '94103'
        );
        insert retailStore;

        List<User> user = [SELECT Id, AccountId FROM User WHERE LastName = 'Testing' LIMIT 1];
        POE_DealerStore__c dealerStore = new POE_DealerStore__c(
            POE_Dealer__c = user[0].AccountId,
            POE_Store__c = retailStore.Id,
            POE_Start_Date__c = Date.today().addDays(-1),
            POE_End_Date__c = null
        );
        insert dealerStore;

        System.runAs(user[0]) {
            Test.startTest();
            Map<String, Object> result = ClickerController.getStore();
            Test.stopTest();
            Assert.areEqual(user[0].Id, ((User) result.get('User'))?.Id, 'User Id does not match');
            Assert.areEqual(user[0].AccountId, ((Id) result.get('Account')), 'Account does not match');
            Assert.areEqual(
                dealerStore.Id,
                ((List<POE_DealerStore__c>) result.get('DealerStore'))[0]?.Id,
                'DealerStore does not match'
            );
        }
    }

    @isTest
    static void testGetStoreRetailStoreFail() {
        List<User> user = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];
        System.runAs(user[0]) {
            Test.startTest();
            Map<String, Object> result = ClickerController.getStore();
            Test.stopTest();
            Assert.areEqual('No Dealer Stores found', result.get('error'), 'Error does not match');
        }
    }

    @isTest
    static void testGetEventSuccess() {
        POE_Event__c event = new POE_Event__c(
            Name = 'Test Event',
            POE_City__c = 'San Francisco',
            POE_State__c = 'California',
            POE_Street_Address__c = '416 Mission Street',
            POE_Zip_Code__c = '94103'
        );
        insert event;

        List<User> user = [SELECT Id, AccountId FROM User WHERE LastName = 'Testing' LIMIT 1];
        POE_DealerEvent__c dealerEvent = new POE_DealerEvent__c(
            POE_Dealer__c = user[0].AccountId,
            POE_Event__c = event.Id
        );
        insert dealerEvent;

        System.runAs(user[0]) {
            Test.startTest();
            Map<String, Object> result = ClickerController.getEvent();
            Test.stopTest();

            Assert.areEqual(user[0].Id, ((User) result.get('User'))?.Id, 'User Id does not match');
            Assert.areEqual(user[0].AccountId, ((Id) result.get('Account')), 'Account does not match');
            Assert.areEqual(
                dealerEvent.Id,
                ((List<POE_DealerEvent__c>) result.get('DealerEvent'))[0]?.Id,
                'DealerEvent does not match'
            );
        }
    }

    @isTest
    static void testGetEventDealerEventFail() {
        List<User> user = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];
        System.runAs(user[0]) {
            Test.startTest();
            Map<String, Object> result = ClickerController.getEvent();
            Test.stopTest();
            Assert.areEqual('No Dealer Events found', result.get('error'), 'Error does not match');
        }
    }
    @isTest
    static void testLogAnInteractionStore() {
        POE_Retail_Store__c retailStore = new POE_Retail_Store__c(
            Name = 'Test Store',
            POE_City__c = 'San Francisco',
            POE_State__c = 'California',
            POE_Street_Address__c = '416 Mission Street',
            POE_Zip_Code__c = '94103'
        );
        insert retailStore;
        List<User> user = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];

        System.runAs(user[0]) {
            Id clickerLocationRecordType = ClickerController.getClickerLocationRecordType();
            maps__Location__c geoLocation = new maps__Location__c(
                RecordTypeId = clickerLocationRecordType,
                Name = 'Test Location',
                maps__Latitude__c = 0.0,
                maps__Longitude__c = 0.0
            );
            insert geoLocation;
            Test.startTest();
            Map<String, Object> result = ClickerController.logAnInteraction('retail', user[0].Id, retailStore.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('error'), 'Triggered an error');
            Assert.areEqual(1, result.get('countContact'), 'Counter should be 1');
        }
    }

    @isTest
    static void testLogAnInteractionEvent() {
        POE_Event__c event = new POE_Event__c(
            Name = 'Test Event',
            POE_City__c = 'San Francisco',
            POE_State__c = 'California',
            POE_Street_Address__c = '416 Mission Street',
            POE_Zip_Code__c = '94103'
        );
        insert event;
        List<User> user = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];

        System.runAs(user[0]) {
            Id clickerLocationRecordType = ClickerController.getClickerLocationRecordType();
            maps__Location__c geoLocation = new maps__Location__c(
                RecordTypeId = clickerLocationRecordType,
                Name = 'Test Location',
                maps__Latitude__c = 0.0,
                maps__Longitude__c = 0.0
            );
            insert geoLocation;
            Test.startTest();
            Map<String, Object> result = ClickerController.logAnInteraction('event', user[0].Id, event.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('error'), 'Triggered an error');
            Assert.areEqual(1, result.get('countContact'), 'Counter should be 1');
        }
    }

    @isTest
    static void testGetUserFraudFlag() {
        User testUser = [SELECT Id, POE_FraudObservation__c FROM User WHERE LastName = 'Testing' LIMIT 1];
        testUser.POE_FraudObservation__c = true;
        update testUser;

        System.runAs(testUser) {
            Test.startTest();
            Boolean isFraud = ClickerController.getUserFraudFlag(testUser.Id);
            Test.stopTest();
            Assert.isTrue(isFraud, 'Expected fraud flag to be true');
        }

    }

    @isTest
    static void testGetMDUSuccess() {
        MDU_Chuzo__c mdu = new MDU_Chuzo__c(
            Name = 'Test MDU'
        );
        insert mdu;

        List<User> user = [SELECT Id, AccountId FROM User WHERE LastName = 'Testing' LIMIT 1];
        DealerMDU__c dealerMDU = new DealerMDU__c(
            Dealer__c = user[0].AccountId,
            MDU_Chuzo__c = mdu.Id
        );
        insert dealerMDU;

        System.runAs(user[0]) {
            Test.startTest();
            Map<String, Object> result = ClickerController.getMDU();
            Test.stopTest();
            Assert.areEqual(user[0].Id, ((User) result.get('User'))?.Id, 'User Id does not match');
            Assert.areEqual(user[0].AccountId, ((Id) result.get('Account')), 'Account does not match');
            Assert.areEqual(
                dealerMDU.Id,
                ((List<DealerMDU__c>) result.get('DealerMDU'))[0]?.Id,
                'DealerMDU does not match'
            );
        }
    }

    @isTest
    static void testGetMDUDealerMDUFail() {
        List<User> user = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];
        System.runAs(user[0]) {
            Test.startTest();
            Map<String, Object> result = ClickerController.getMDU();
            Test.stopTest();
            Assert.areEqual('No Dealer MDUs found', result.get('error'), 'Error does not match');
        }
    }

    @isTest
    static void testGetClickerMDUTrack() {
        MDU_Chuzo__c mdu = new MDU_Chuzo__c(
            Name = 'Test MDU',
            DIRECTV_Dealer_Code_FFL__c = 'FFL123',
            DIRECTV_Dealer_Code_NFFL__c = 'NFFL456'
        );
        insert mdu;

        List<User> user = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];
        
        System.runAs(user[0]) {
            Test.startTest();
            Map<String, Object> result = ClickerController.getClickerMDUTrack(user[0].Id, null);
            Test.stopTest();
            System.assert(result != null, 'MDU Track is Null');
            Assert.areEqual(0, result.get('countContact'), 'Contact count should be 0');
            Assert.areEqual(0, result.get('countServiceability'), 'Serviceability count should be 0');
            Assert.areEqual(0, result.get('countProduct'), 'Product count should be 0');
            Assert.areEqual(0, result.get('countCompleted'), 'Completed count should be 0');
        }
    }

    @isTest
    static void testLogAnInteractionMDU() {
        MDU_Chuzo__c mdu = new MDU_Chuzo__c(
            Name = 'Test MDU'
        );
        insert mdu;
        List<User> user = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];

        System.runAs(user[0]) {
            Id clickerLocationRecordType = ClickerController.getClickerLocationRecordType();
            maps__Location__c geoLocation = new maps__Location__c(
                RecordTypeId = clickerLocationRecordType,
                Name = 'Test Location',
                maps__Latitude__c = 0.0,
                maps__Longitude__c = 0.0
            );
            insert geoLocation;
            Test.startTest();
            Map<String, Object> result = ClickerController.logAnInteraction('mdu', user[0].Id, mdu.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('error'), 'Triggered an error');
            Assert.areEqual(1, result.get('countContact'), 'Counter should be 1');
        }
    }
}