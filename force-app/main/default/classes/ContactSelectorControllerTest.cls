@isTest
public with sharing class ContactSelectorControllerTest {
    @isTest
    static void test_saveContact(){
        Map<String, Object> myData = new Map<String, Object>{
            'firstName' => 'test',
            'lastName' => 'test',
            'email' => 'test@test.com',
            'phone' => '123123123'
        };

        test.startTest();
        Contact response = ContactSelectorController.saveContact(myData);
        test.stopTest();

        System.assertNotEquals(null, response.Id, 'response must have and Id');
    }
}