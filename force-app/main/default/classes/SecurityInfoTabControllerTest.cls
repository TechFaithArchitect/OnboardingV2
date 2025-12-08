@isTest
public with sharing class SecurityInfoTabControllerTest {
    @isTest
    static void test_sendValidationEmail(){
        Test.startTest();
        SecurityInfoTabController.ResponseWrapper response = SecurityInfoTabController.sendValidationEmail(new Map<String, Object>{
            'emailAddress' => 'test@test.com',
            'contactName' => 'Test Name'
        });
        test.stopTest();

        System.assertEquals(true, response.result.containsKey('pincode'), 'The method should return a pincode');
    }
}