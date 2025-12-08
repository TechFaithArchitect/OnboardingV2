@isTest
public class POE_LeadsDataTableControllerTest {
    private static final String LEAD_RECORD_TYPE_NAME = 'Lead Master';
    @TestSetup
    static void makeData() {
        List<RecordType> leadRT = [SELECT Id FROM RecordType WHERE Name = :LEAD_RECORD_TYPE_NAME];
        List<Lead> importLeads = new List<Lead>();

        for (Integer i = 1; i < 11; i++) {
            Lead newLead = new Lead(
                RecordTypeId = leadRT[0].Id,
                Type__c = 'Phone Sales',
                LastName = '' + i,
                FirstName = 'Test',
                State = 'Georgia',
                Country = 'United States',
                PostalCode = '30620',
                Phone = '888888888' + i
            );
            importLeads.add(newLead);
        }
        insert (importLeads);
    }

    @isTest
    private static void searchLeadsNoName() {
        String sortedDirection = 'asc';
        String sortedBy = 'Name';
        String searchKey = '';
        List<Lead> getLeads = POE_LeadsDataTableController.getLeads(searchKey, sortedBy, sortedDirection);

        System.assertEquals(true, getLeads.size() == 10, 'All leads retrieved');
    }
    @isTest
    private static void searchLeadsWithName() {
        String sortedDirection = 'asc';
        String sortedBy = 'Name';
        String searchKey = '8';
        List<Lead> getLeads = POE_LeadsDataTableController.getLeads(searchKey, sortedBy, sortedDirection);

        System.assertEquals(true, getLeads.size() == 1, '1 lead retrieved');
    }

    @isTest
    static void testGetLeadsException() {
        Test.startTest();
        try {
            List<Lead> response = POE_LeadsDataTableController.getLeads('InvalidData', 'InvalidData', 'InvalidData');
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }
}