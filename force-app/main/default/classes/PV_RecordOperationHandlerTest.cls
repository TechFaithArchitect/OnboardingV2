@isTest
public class PV_RecordOperationHandlerTest {
    @isTest
    static void processSaveResultsTest() {
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test')
        };

        Test.startTest();
        List<Database.SaveResult> saveResults = Database.insert(contacts, false);
        PV_RecordOperationHandler.ProcessResult result = PV_RecordOperationHandler.processSaveResults(saveResults);
        Test.stopTest();

        System.assertNotEquals(null, result.firstErrorType, 'Expected an error due to missing LastName');
        System.assert(result.firstErrorType.contains(
            'REQUIRED_FIELD_MISSING'), 
         	'Expected REQUIRED_FIELD_MISSING error but got: ' + result.firstErrorType
     	);
    }

    @isTest
    static void processDeleteResultsTest() {
        Contact contact = new Contact(FirstName = 'Test', LastName = 'WithCase');
        insert contact;

        Case newCase = new Case(ContactId = contact.Id, Subject = 'Test Case');
        insert newCase;

        List<Contact> contacts = [SELECT Id FROM Contact];

        Test.startTest();
        List<Database.DeleteResult> deleteResults = Database.delete(contacts, false);
        PV_RecordOperationHandler.ProcessResult result = PV_RecordOperationHandler.processDeleteResults(deleteResults);
        Test.stopTest();
        
        System.assertNotEquals(null, result.firstErrorType, 'Expected an error due to related Case');
        System.assert(result.firstErrorType.contains(
            'DELETE_FAILED'),
            'Expected DELETE_FAILED error but got: ' + result.firstErrorType
        );
    }
}