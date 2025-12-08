@isTest
public with sharing class POE_DealerScoreCardControllerTest {
    @TestSetup
    static void makeData() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com'
            );
            insert testAcc;
            Contact testContact1 = new Contact(FirstName = 'testCont', LastName = 'testCont', AccountId = testAcc.Id);
            insert testContact1;

            Profile p = TestHelper.getGeneralProfile();
            User u2 = new User(
                Alias = 'standt',
                Email = '11034234standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing2',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = testContact1.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '110520333GDGstandarduser@testorg.com'
            );
            insert u2;
        }
    }

    @isTest
    private static void saveInteractionTest() {
        User partner = [SELECT Id FROM User WHERE LastName = 'Testing2' LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Boolean result;
        Test.startTest();
        System.runAs(partner) {
            POE_DealerScoreCardController.saveInteraction(false);
            POEInteractionTracker intp = new POEInteractionTracker();
            result = intp.invokeMethod('Test', inputMap, outMap, options);
        }
        Test.stopTest();
        Integer count = [SELECT COUNT() FROM POE_Interaction_Tracker__c];
        System.assertEquals(2, count, 'Interactions were not inserted');
        System.assertEquals(true, result, 'The invoke Method Process Failed');
    }

    @isTest
    private static void saveMapsInteractionWithPastInteractionTest() {
        User partner = [SELECT Id, ContactId FROM User WHERE LastName = 'Testing2' LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Boolean result;
        POE_Interaction_Tracker__c inter = new POE_Interaction_Tracker__c();
        inter.Contact__c = partner.ContactId;
        insert inter;
        Test.startTest();
        System.runAs(partner) {
            POE_DealerScoreCardController.saveInteraction(true);
            POEInteractionTracker intp = new POEInteractionTracker();
            result = intp.invokeMethod('Test', inputMap, outMap, options);
        }
        Test.stopTest();
        Integer count = [SELECT COUNT() FROM POE_Interaction_Tracker__c];
        System.assertEquals(3, count, 'Interactions were not inserted');
        System.assertEquals(true, result, 'The invoke Method Process Failed');
    }

    @isTest
    private static void saveNoMapsInteractionWithPastInteractionTest() {
        User partner = [SELECT Id, ContactId FROM User WHERE LastName = 'Testing2' LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Boolean result;
        POE_Interaction_Tracker__c inter = new POE_Interaction_Tracker__c();
        inter.Contact__c = partner.ContactId;
        insert inter;
        Test.startTest();
        System.runAs(partner) {
            POE_DealerScoreCardController.saveInteraction(false);
            POEInteractionTracker intp = new POEInteractionTracker();
            result = intp.invokeMethod('Test', inputMap, outMap, options);
        }
        Test.stopTest();
        Integer count = [SELECT COUNT() FROM POE_Interaction_Tracker__c];
        System.assertEquals(3, count, 'Interactions were not inserted');
        System.assertEquals(true, result, 'The invoke Method Process Failed');
    }

    @isTest
    private static void saveFirstInteractionTest() {
        User partner = [SELECT Id FROM User WHERE LastName = 'Testing2' LIMIT 1];
        Boolean result;
        Test.startTest();
        System.runAs(partner) {
            POE_DealerScoreCardController.saveFirstInteraction();
        }
        Test.stopTest();
        Integer count = [SELECT COUNT() FROM POE_Interaction_Tracker__c];
        System.assertEquals(1, count, 'Interactions were not inserted');
    }

    @isTest
    static void testSaveInteractionException() {
        POE_DealerScoreCardController.throwException = true;

        Test.startTest();
        try {
            POE_DealerScoreCardController.saveInteraction(true);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveFirstInteractionException() {
        POE_DealerScoreCardController.throwException = true;

        Test.startTest();
        try {
            POE_DealerScoreCardController.saveFirstInteraction();
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }
}