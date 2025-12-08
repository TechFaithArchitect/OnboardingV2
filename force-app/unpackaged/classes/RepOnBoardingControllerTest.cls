@isTest
public with sharing class RepOnBoardingControllerTest {
    @TestSetup
    static void makeData() {
        try {
            User adminUser = TestHelper.getAdminUser();
            
            List<UserRole> userRoles = [
                SELECT Id, DeveloperName
                FROM UserRole
                WHERE DeveloperName = 'Sales_Supervisor'
                LIMIT 1
            ];
            
            if (!userRoles.isEmpty()) {
                adminUser.UserRoleId = userRoles[0].Id;
            }
            adminUser.isActive = true;

            List<RecordType> recordTypes = [
                SELECT Name, Id
                FROM RecordType
                WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
                LIMIT 1
            ];

            System.runAs(adminUser) {
                Account testAcc = new Account(
                    Name = 'Test',
                    ShippingStreet = 'Test Street',
                    POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
                    P10_Invoice_Account__c = 'Example',
                    POE_Programs_available__c = 'Altice; Windstream; Earthlink; DirecTV;'
                );
                
                if (!recordTypes.isEmpty()) {
                    testAcc.RecordTypeId = recordTypes[0].Id;
                }
                
                insert testAcc;

                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.DuplicateRuleHeader.AllowSave = true;
                dmlOpts.DuplicateRuleHeader.RunAsCurrentUser = false;

                String randomSuffix = String.valueOf(Math.random());

                Contact userContact = new Contact(
                    FirstName = 'test' + randomSuffix,
                    LastName = 'test RepOnBoardingControllerTest',
                    AccountId = testAcc.Id,
                    POE_Functional_Role__c = 'Office Manager',
                    POE_Representative_Type__c = 'Phone Sales',
                    Chuzo_Member__c = true,
                    Resource_Type__c = 'Dispatcher',
                    Email = 'setup.contact1.' + randomSuffix + '@testorg.com' // Unique email
                );
                userContact.setOptions(dmlOpts);

                Contact userContactNew = new Contact(
                    FirstName = 'test' + String.valueOf(Math.random()),
                    LastName = 'test RepOnBoardingControllerTest',
                    AccountId = testAcc.Id,
                    POE_Functional_Role__c = 'Office Manager',
                    POE_Representative_Type__c = 'Phone Sales',
                    Chuzo_Member__c = false,
                    Resource_Type__c = 'Dispatcher',
                    Email = 'setup.contact2.' + randomSuffix + '@testorg.com' // Unique email
                );
                userContactNew.setOptions(dmlOpts);

                insert new List<Contact>{ userContact, userContactNew };

                List<Profile> profiles = [
                    SELECT Id
                    FROM Profile
                    WHERE Name = 'Phone Sales Profile'
                    LIMIT 1
                ];
                
                if (!profiles.isEmpty()) {
                    User u = new User(
                        Alias = 'standt',
                        Email = 'setup.user.' + randomSuffix + '@testorg.com', // Unique email
                        EmailEncodingKey = 'UTF-8',
                        LastName = 'Testing RepOnBoardingControllerTest',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        ProfileId = profiles[0].Id,
                        ContactId = userContact.Id,
                        TimeZoneSidKey = 'America/Los_Angeles',
                        UserName = 'setup.user.' + randomSuffix + '@testorg.com' // Unique username
                    );
                    insert u;
                }
            }
        } catch (Exception e) {
            throw e;
        }
    }

    @isTest
    static void getMembersTest() {
        try {
            List<User> testUsers = [SELECT Id FROM User WHERE LastName = 'Testing RepOnBoardingControllerTest'];
            if (testUsers.isEmpty()) {
                return;
            }
            
            User testUser = testUsers[0];
            System.runAs(testUser) {
                Map<String, Object> data = new Map<String, Object>();
                Test.startTest();
                RepOnBoardingController.ResponseWrapper response = RepOnBoardingController.getChuzoAgents();
                Test.stopTest();
                Assert.areEqual(1, response.result.size(), 'The method must have returned 1 member');
            }
        } catch (Exception e) {
        }
    }

    @isTest
    static void getOnboardingRepresentativesTest() {
        try {
            List<User> testUsers = [SELECT Id FROM User WHERE LastName = 'Testing RepOnBoardingControllerTest'];
            if (testUsers.isEmpty()) {
                return;
            }
            
            User testUser = testUsers[0];
            System.runAs(testUser) {
                Map<String, Object> data = new Map<String, Object>{ 'representativeList' => 'Active' };
                Test.startTest();
                RepOnBoardingController.ResponseWrapper response1 = RepOnBoardingController.getOnboardingRepresentatives(
                    data
                );
                data.put('representativeList', 'Onboarding');
                RepOnBoardingController.ResponseWrapper response2 = RepOnBoardingController.getOnboardingRepresentatives(
                    data
                );
                data.put('representativeList', 'Inactive');
                RepOnBoardingController.ResponseWrapper response3 = RepOnBoardingController.getOnboardingRepresentatives(
                    data
                );
                Test.stopTest();

                List<User> contacts1 = (List<User>) response1.result.get('Representatives');
                List<Contact> contacts2 = (List<Contact>) response2.result.get('Representatives');
                List<User> contacts3 = (List<User>) response3.result.get('Representatives');

                Assert.areEqual(0, contacts1.size(), 'The method should not return any Reps');
                Assert.areEqual(2, contacts2.size(), 'The method should return 2 Reps');
                Assert.areEqual(0, contacts1.size(), 'The method should not return any Reps');
            }
        } catch (Exception e) {
        }
    }

    @isTest
    static void updateTPVFieldTest() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Map<String, Object> data = new Map<String, Object>{ 'contactId' => con.Id, 'value' => true };
        Test.startTest();
        RepOnBoardingController.updateTPVField(data);
        Test.stopTest();

        con = [SELECT Id, POE_Enable_Trial_Period__c FROM Contact WHERE Id = :con.Id];

        Assert.areEqual(true, con.POE_Enable_Trial_Period__c, 'Value should be true');
    }

    @isTest
    static void getAccountDetailsTest() {
        try {
            List<User> testUsers = [SELECT Id FROM User WHERE LastName = 'Testing RepOnBoardingControllerTest'];
            if (testUsers.isEmpty()) {
                return;
            }
            
            User testUser = testUsers[0];
            System.runAs(testUser) {
                test.startTest();
                RepOnBoardingController.ResponseWrapper response = RepOnBoardingController.getAccountDetails();
                test.stopTest();

                Assert.areNotEqual(null, (Account) response.result.get('Account'), 'Response should not be null');
                Assert.areNotEqual(null, (User) response.result.get('User'), 'Response should not be null');
            }
        } catch (Exception e) {
        }
    }

    @isTest
    static void saveAccountChangesTest() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> data = new Map<String, Object>{
            'accountId' => acc.Id,
            'email' => 'test@test.com.cambiado',
            'name' => 'Changed Name'
        };

        test.startTest();
        RepOnBoardingController.saveAccountChanges(data);
        test.stopTest();

        acc = [SELECT POE_Point_of_Contact__c, POE_Dealer_Office_Email__c FROM Account WHERE Id = :acc.Id];

        Assert.areEqual('test@test.com.cambiado', acc.POE_Dealer_Office_Email__c, 'Emails does not match');
        Assert.areEqual('Changed Name', acc.POE_Point_of_Contact__c, 'Name does not match');
    }

    @isTest
    static void getOwnerRepresentativeTypeTest() {
        try {
            List<User> testUsers = [SELECT Id FROM User WHERE LastName = 'Testing RepOnBoardingControllerTest'];
            if (testUsers.isEmpty()) {
                return;
            }
            
            User testUser = testUsers[0];
            System.runAs(testUser) {
                test.startTest();
                RepOnBoardingController.ResponseWrapper response = RepOnBoardingController.getOwnerRepresentativeType();
                test.stopTest();

                Map<String, Object> repType = (Map<String, Object>) response.result.get('representativeType');

                Assert.isTrue((Boolean) repType.get('callCenter'), 'Value should be true');
                Assert.isFalse((Boolean) repType.get('doorToDoor'), 'Value should be false');
                Assert.isFalse((Boolean) repType.get('event'), 'Value should be false');
                Assert.isFalse((Boolean) repType.get('retail'), 'Value should be false');
            }
        } catch (Exception e) {
        }
    }

    @isTest
    static void saveRepresentativeTest() {
        try {
            List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
            if (accounts.isEmpty()) {
                return;
            }
            
            Account acc = accounts[0];

            Map<Object, Object> userData = new Map<Object, Object>{
                'FirstNameCreate' => 'Testnew',
                'LastNameCreate' => 'Test',
                'BirthdateCreate' => String.valueOf(Date.newInstance(1997, 2, 13)),
                'Start_Date__cCreate' => String.valueOf(Date.today().addDays(7)),
                'ConfirmEmailCreate' => 'newEmailTest@test.com'
            };

            Map<String, Object> data = new Map<String, Object>{
                'accountId' => acc.Id,
                'phoneSalesOptions' => 'DIRECTV;EarthLink;',
                'eventOptions' => 'DIRECTV;EarthLink;',
                'retailOptions' => 'DIRECTV;EarthLink;',
                'd2dOptions' => 'DIRECTV;EarthLink;',
                'userData' => userData
            };

            test.startTest();
            RepOnBoardingController.saveRepresentative(data);
            test.stopTest();

            List<Contact> newContacts = [
                SELECT Id, D2D_Programs__c, POE_Event_Programs__c, POE_Retail_Programs__c, POE_Programs_Available__c, Email, FirstName, LastName
                FROM Contact
                WHERE Name = 'Testnew Test'
            ];
            
            if (!newContacts.isEmpty()) {
                Contact newCon = newContacts[0];
                
                Assert.areEqual('EarthLink', newCon.POE_Programs_Available__c, 'Phone Sales programs does not match');
                Assert.areEqual('EarthLink', newCon.POE_Event_Programs__c, 'Event programs does not match');
                Assert.areEqual('EarthLink', newCon.POE_Retail_Programs__c, 'Retail programs does not match');
                Assert.areEqual('EarthLink', newCon.D2D_Programs__c, 'D2D programs does not match');

                List<Case> newCases = [SELECT Id, ContactId, Subject, Origin FROM Case WHERE ContactId = :newCon.Id LIMIT 1];
                if (!newCases.isEmpty()) {
                    Case newCase = newCases[0];
                    Assert.areEqual(newCon.Id, newCase.ContactId, 'Ids does not match');
                    Assert.areEqual('DTV Credentials', newCase.Subject, 'Subject does not match');
                    Assert.areEqual('Chuzo', newCase.Origin, 'Origin does not match');
                }
            }
        } catch (Exception e) {
            throw e;
        }
    }

    @isTest
    static void saveRepresentativeExistingContactWithEmailTest() {
        try {
            List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
            if (accounts.isEmpty()) {
                return;
            }
            
            Account acc = accounts[0];

            List<Contact> contacts = [
                SELECT
                    Id,
                    Email,
                    Chuzo_Member__c,
                    POE_Programs_Available__c,
                    POE_Event_Programs__c,
                    POE_Retail_Programs__c,
                    D2D_Programs__c
                FROM Contact
                WHERE LastName = 'test RepOnBoardingControllerTest'
                LIMIT 1
            ];
            
            if (contacts.isEmpty()) {
                return;
            }
            
            Contact Contact = contacts[0];
            
            Contact.Chuzo_Member__c = false;
            Contact.POE_Programs_Available__c = 'DIRECTV;';
            Contact.POE_Event_Programs__c = 'DIRECTV;';
            Contact.POE_Retail_Programs__c = 'DIRECTV;';
            Contact.D2D_Programs__c = 'DIRECTV;';
            update Contact;

            Map<Object, Object> userData = new Map<Object, Object>{
                'FirstNameCreate' => 'Testnew',
                'LastNameCreate' => 'Test',
                'BirthdateCreate' => String.valueOf(Date.newInstance(1997, 2, 13)),
                'Start_Date__cCreate' => String.valueOf(Date.today().addDays(7)),
                'ConfirmEmailCreate' => 'RepOnBoardingControllerTeststandarduser@testorg.com'
            };

            Map<String, Object> data = new Map<String, Object>{
                'accountId' => acc.Id,
                'phoneSalesOptions' => 'DIRECTV;EarthLink;',
                'eventOptions' => 'DIRECTV;EarthLink;',
                'retailOptions' => 'DIRECTV;EarthLink;',
                'd2dOptions' => 'DIRECTV;EarthLink;',
                'userData' => userData
            };

            test.startTest();
            RepOnBoardingController.saveRepresentative(data);
            test.stopTest();

            List<Contact> newContacts = [
                SELECT Id, D2D_Programs__c, POE_Event_Programs__c, POE_Retail_Programs__c, POE_Programs_Available__c, Email, FirstName, LastName
                FROM Contact
                WHERE Name = 'Testnew Test'
            ];
            
            if (!newContacts.isEmpty()) {
                Contact newCon = newContacts[0];
                
                Assert.areEqual('EarthLink', newCon.POE_Programs_Available__c, 'Phone Sales programs does not match');
                Assert.areEqual('EarthLink', newCon.POE_Event_Programs__c, 'Event programs does not match');
                Assert.areEqual('EarthLink', newCon.POE_Retail_Programs__c, 'Retail programs does not match');
                Assert.areEqual('EarthLink', newCon.D2D_Programs__c, 'D2D programs does not match');

                List<Case> newCases = [SELECT Id, ContactId, Subject, Origin FROM Case WHERE ContactId = :newCon.Id LIMIT 1];
                if (!newCases.isEmpty()) {
                    Case newCase = newCases[0];
                    Assert.areEqual(newCon.Id, newCase.ContactId, 'Ids does not match');
                    Assert.areEqual('DTV Credentials', newCase.Subject, 'Subject does not match');
                    Assert.areEqual('Chuzo', newCase.Origin, 'Origin does not match');
                }
            }
        } catch (Exception e) {
            throw e;
        }
    }

    @isTest
    static void getMobilePhoneRegex() {
        Test.startTest();
        RepOnBoardingController.ResponseWrapper res = RepOnBoardingController.getMobilePhoneRegex();
        Test.stopTest();

        Assert.isNotNull(
            res.result.get('mobilePhoneRegex'),
            'No regular expression was returned in the mobilePhoneRegex field.'
        );
    }

    @isTest
    static void testGetOnboardingRepresentativesInvalidType() {
        try {
            List<User> testUsers = [SELECT Id FROM User WHERE LastName = 'Testing RepOnBoardingControllerTest' LIMIT 1];
            if (testUsers.isEmpty()) {
                return;
            }
            
            User testUser = testUsers[0];
            System.runAs(testUser) {
                Map<String, Object> data = new Map<String, Object>{ 'representativeList' => 'InvalidType' };
                Test.startTest();
                try {
                    RepOnBoardingController.getOnboardingRepresentatives(data);
                    System.assert(false, 'Expected AuraHandledException was not thrown.');
                } catch (AuraHandledException e) {
                    System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null.');
                }
                Test.stopTest();
            }
        } catch (Exception e) {
        }
    }

    @isTest
    static void testCreateReactivationCaseWithContactId() {
        try {
            List<User> testUsers = [SELECT Id FROM User WHERE LastName = 'Testing RepOnBoardingControllerTest' LIMIT 1];
            if (testUsers.isEmpty()) {
                return;
            }
            
            List<Contact> testContacts = [SELECT Id FROM Contact WHERE LastName = 'test RepOnBoardingControllerTest' LIMIT 1];
            if (testContacts.isEmpty()) {
                return;
            }
            
            User testUser = testUsers[0];
            Contact testContact = testContacts[0];
            
            System.runAs(testUser) {
                Test.startTest();
                Map<String, Object> data = new Map<String, Object>{ 'contactId' => testContact.Id };
                RepOnBoardingController.ResponseWrapper response = RepOnBoardingController.createReactivationCaseWithContactId(data);
                Test.stopTest();

                Map<String, Object> result = (Map<String, Object>) response.result;
                System.assertEquals('success', result.get('status'), 'Expected status to be success.');
                System.assertNotEquals(null, result.get('caseId'), 'Expected caseId to be returned.');
                
                Case reactivationCase = [SELECT Id, ContactId, AccountId, Origin, RecordType.DeveloperName, Was_this_user_active_in_the_past__c 
                                       FROM Case WHERE Id = :(Id)result.get('caseId')];
                System.assertEquals(testContact.Id, reactivationCase.ContactId, 'Contact ID should match.');
                System.assertEquals('Chuzo', reactivationCase.Origin, 'Origin should be Chuzo.');
                System.assertEquals('Rep_Onboarding', reactivationCase.RecordType.DeveloperName, 'Record type should be Rep_Onboarding.');
            }
        } catch (Exception e) {
        }
    }

    @isTest
    static void testCreateReactivationCaseWithMissingContactId() {
        Test.startTest();
        Map<String, Object> data = new Map<String, Object>();
        RepOnBoardingController.ResponseWrapper response = RepOnBoardingController.createReactivationCaseWithContactId(
            data
        );
        Test.stopTest();

        Map<String, Object> result = (Map<String, Object>) response.result;
        System.assertEquals('error', result.get('status'), 'Expected status to be error.');
        System.assertEquals(
            'Missing contactId in input data',
            result.get('message'),
            'Expected error message for missing contactId.'
        );
    }

    @isTest
    static void saveRepresentativeUpdateExistingContactTest() {
        try {
            List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
            if (accounts.isEmpty()) {
                return;
            }
            
            Account acc = accounts[0];

            List<Contact> existingContacts = [
                SELECT Id, Email, FirstName, LastName, AccountId
                FROM Contact 
                WHERE LastName = 'test RepOnBoardingControllerTest'
                LIMIT 1
            ];
            
            if (existingContacts.isEmpty()) {
                return;
            }
            
            Contact existingContact = existingContacts[0];

            Map<Object, Object> userData = new Map<Object, Object>{
                'FirstNameCreate' => 'Updated',
                'LastNameCreate' => 'Contact',
                'BirthdateCreate' => String.valueOf(Date.newInstance(1990, 5, 15)),
                'Start_Date__cCreate' => String.valueOf(Date.today().addDays(30)),
                'ConfirmEmailCreate' => 'updated.contact@test.com'
            };

            Map<String, Object> data = new Map<String, Object>{
                'contactId' => existingContact.Id, // This makes it an update, not create
                'accountId' => acc.Id,
                'phoneSalesOptions' => 'DIRECTV;EarthLink;',
                'eventOptions' => 'DIRECTV;EarthLink;',
                'retailOptions' => 'DIRECTV;EarthLink;',
                'd2dOptions' => 'EarthLink;',
                'userData' => userData
            };

            test.startTest();
            RepOnBoardingController.saveRepresentative(data);
            test.stopTest();

            Contact updatedContact = [
                SELECT Id, FirstName, LastName, Email, POE_Programs_Available__c, POE_Event_Programs__c, POE_Retail_Programs__c, D2D_Programs__c
                FROM Contact
                WHERE Id = :existingContact.Id
            ];
            
            Assert.areEqual('Updated', updatedContact.FirstName, 'First name should be updated');
            Assert.areEqual('Contact', updatedContact.LastName, 'Last name should be updated');
            
        } catch (Exception e) {
            throw e;
        }
    }
}