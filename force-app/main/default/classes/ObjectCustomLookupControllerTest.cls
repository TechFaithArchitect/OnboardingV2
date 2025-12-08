@isTest
public with sharing class ObjectCustomLookupControllerTest {
    @isTest
    static void test_fetchLookupData(){
        Contact c = new Contact(
            LastName = 'test',
            FirstName = 'test',
            Email = 'test@test.com'
        );
        insert c;

        test.startTest();
        List<SObject> response = ObjectCustomLookupController.fetchLookupData('test', 'Contact', '  email = \'test@test.com\'', 'Email');
        test.stopTest();

        system.assertEquals(c.Id, response[0].Id, 'Ids must match');
    }
}