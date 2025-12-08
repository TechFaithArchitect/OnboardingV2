@isTest
public class POEDynamicUIDFieldsControllerTest {
    @TestSetup
    static void makeData() {
        Account newAcc = new Account();
        newAcc.Name = 'Test Account';
        newAcc.POE_Dealer_Office_Email__c = 'test@test.com';
        insert newAcc;

        Contact newCont = new Contact();
        newCont.FirstName = 'Test First';
        newCont.LastName = 'Test Last';
        newCont.AccountId = newAcc.Id;
        insert newCont;
    }

    @isTest
    private static void getAccountEmailTest() {
        Contact newCont = [SELECT Id FROM Contact LIMIT 1];

        String email = '';
        List<String> cc = new List<String>();
        cc.add('test2@test.com');
        Test.startTest();
        email = POEDynamicUIDFieldsController.getDealerEmail(newCont.Id);
        POEDynamicUIDFieldsController.sendEmail('test body', email, cc);
        Test.stopTest();

        System.assertEquals('test@test.com', email, 'Email was not retrieved');
    }

    @isTest
    private static void testSendEmailException() {
        List<String> cc = new List<String>();
        cc.add('InvalidEmail');

        Test.startTest();
        try {
            POEDynamicUIDFieldsController.sendEmail('testSendEmail', 'testSendEmail', cc);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }
}