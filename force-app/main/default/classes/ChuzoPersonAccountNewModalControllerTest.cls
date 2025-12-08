@isTest
public without sharing class ChuzoPersonAccountNewModalControllerTest {
    @isTest
    public static void createPersonAccountPositiveTest(){
        String jsonMessage = '{ "firstName": "TestFinal", "lastName": "PersonAccountOne", "streetLineOne": "42916 Alexo Drive", "streetLineTwo": "Suite 40", "city": "Lancaster", "state": "CA", "zip": "93536", "country": "United States", "phoneOne": "88999999", "phoneTwo": "321333333", "emailOne": "test@test.com", "emailTwo": "test+test@test.com", "leadOrigin": "Referral", "leadOriginOther": "Per", "programLeadType": "Optimum;ViaSat;Windstream", "programLeadTypeOther": "", "currentProviders": "Test", "currentProvidersCost": "434", "underContract": true, "contractExpirationDate": "2024-09-18", "suggestedProviders": "None", "suggestedProvidersCost": "123", "firstDateContacted": "2024-09-01", "secondDateContacted": "2024-09-05", "thirdDateContacted": "2024-09-07", "soldDate": "2024-09-18", "stage": "Not interested", "rating": "Warm" }';
        Test.startTest();
        ChuzoPersonAccountNewModalController.createPersonAccount(jsonMessage);
        Test.stopTest();

        List<Account> accounts = [SELECT FirstName, LastName, BillingStreet, BillingCity, BillingStateCode, Billing_Address_Line_2__c, BillingPostalCode,  PersonEmail, Phone, Current_Provider_s__pc, Suggested_Provider_s__pc 
            FROM Account WHERE FirstName = 'TestFinal' AND LastName = 'PersonAccountOne' AND IsPersonAccount = true];
        System.assertEquals(1, accounts.size(), 'Expected exactly one Person Account to be created.');
        
        Account createdAccount = accounts[0];
        
        System.assertEquals('TestFinal', createdAccount.FirstName, 'FirstName does not match');
        System.assertEquals('PersonAccountOne', createdAccount.LastName, 'LastName does not match');
        System.assertEquals('42916 Alexo Drive', createdAccount.BillingStreet, 'BillingStreet does not match');
        System.assertEquals('Suite 40', createdAccount.Billing_Address_Line_2__c, 'Street line 2 does not match');
        System.assertEquals('Lancaster', createdAccount.BillingCity, 'BillingCity does not match');
        System.assertEquals('CA', createdAccount.BillingStateCode, 'BillingStateCode does not match');
        System.assertEquals('93536', createdAccount.BillingPostalCode, 'BillingPostalCode does not match');
        System.assertEquals('test@test.com', createdAccount.PersonEmail, 'PersonEmail does not match');
        System.assertEquals('88999999', createdAccount.Phone, 'Phone does not match');
        System.assertEquals('Test', createdAccount.Current_Provider_s__pc, 'Current Providers does not match');
        System.assertEquals('None', createdAccount.Suggested_Provider_s__pc, 'Suggested Providers does not match');
    }

    @isTest
    public static void createPersonAccountNegativeTest(){
        Test.startTest();
        try{
            ChuzoPersonAccountNewModalController.createPersonAccount('');
            Assert.fail('Code should not reach this point');
        } catch(Exception e){

        }
        Test.stopTest();
    }
}