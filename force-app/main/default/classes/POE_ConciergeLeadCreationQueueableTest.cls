@isTest
public class POE_ConciergeLeadCreationQueueableTest {
    public static final String EXTERNAL_LEAD_ID = 'testleadid';

    @TestSetup
    static void setup() {
        Lead testLead = TestHelper.getLeads(1)[0];
        insert testLead;
    }
    
    @isTest
    static void conciergeLeadCreationQueueableSuccessTest() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1]; 

        Test.setMock(HttpCalloutMock.class, new POE_ConciergeLeadCreationCalloutMock(true));
        Test.startTest();
        System.enqueueJob(new POE_ConciergeLeadCreationQueueable(testLead.Id));
        Test.stopTest();

        Lead updatedLead = [
            SELECT Id, Concierge_External_Id__c
            FROM Lead
            WHERE Id = :testLead.Id
        ];
        Assert.isTrue(
            String.isNotBlank(updatedLead.Concierge_External_Id__c),
            'The Concierge External Id field was not set when the callout was successful'
        );
    }

    @isTest
    static void conciergeLeadCreationQueueableFailureTest() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1]; 

        Test.setMock(HttpCalloutMock.class, new POE_ConciergeLeadCreationCalloutMock(false));
        Test.startTest();
        System.enqueueJob(new POE_ConciergeLeadCreationQueueable(testLead.Id));
        Test.stopTest();

        Lead updatedLead = [
            SELECT Id, Concierge_External_Id__c
            FROM Lead
            WHERE Id = :testLead.Id
        ];
        Assert.isTrue(
            String.isBlank(updatedLead.Concierge_External_Id__c),
            'The Concierge External Id field was set when the callout failed'
        );

        List<Error_Log__c> errorLogList = [
            SELECT Id, Error__c
            FROM Error_Log__c
        ];
        Boolean errorLogExists = false;
        for (Error_Log__c errorLog : errorLogList) {
            errorLogExists = errorLog.Error__c == POE_ConciergeLeadCreationCalloutMock.ERROR_MESSAGE
                             || errorLogExists;
        }

        Assert.isTrue(
            errorLogExists,
            'No error was created with the error message from the response'
        );
    }
}