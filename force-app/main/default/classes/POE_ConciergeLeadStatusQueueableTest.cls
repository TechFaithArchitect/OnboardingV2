@isTest
public class POE_ConciergeLeadStatusQueueableTest {
    public static final String EXTERNAL_LEAD_ID = 'testleadid';

    @TestSetup
    static void setup() {
        List<Lead> testLeads = TestHelper.getLeads(2);
        for (Integer i = 0; i < testLeads.size(); i++) {
            Lead testLead = testLeads[i];
            testLead.Concierge_External_Id__c = EXTERNAL_LEAD_ID + i;
        }

        insert testLeads;

        Chuzo_Settings__c settings = new Chuzo_Settings__c(Concierge_Lost_Status__c= 'Closed - Lost;Duplicate;Disqualified', Concierge_Won_Status__c = 'Closed - Won');
        insert settings;
    }

    @isTest
    static void conciergeLeadCreationQueueableSuccessTest() {
        List<Lead> testLeads = [SELECT Id FROM Lead];
        List<String> leadIds = new List<String>{ testLeads[0].Id, testLeads[1].Id };

        Test.setMock(HttpCalloutMock.class, new POE_ConciergeLeadStatusCalloutMock(true));
        Test.startTest();
        System.enqueueJob(new POE_ConciergeLeadStatusQueueable(leadIds));
        Test.stopTest();

        List<Lead> updatedLeads = [SELECT Id, Concierge_Status__c FROM Lead WHERE Id IN :leadIds];
        Boolean duplicateLeadExists = false;
        Boolean updatedLeadExists = false;
        for (Lead updatedLead : updatedLeads) {
            duplicateLeadExists = updatedLead.Concierge_Status__c == 'Duplicate' || duplicateLeadExists;
            updatedLeadExists = updatedLead.Concierge_Status__c == 'Update' || updatedLeadExists;
        }

        Assert.isTrue(
            duplicateLeadExists && updatedLeadExists,
            'The Concierge Status fields of the Leads were not updated'
        );
    }

    @isTest
    static void conciergeLeadCreationQueueableFailureTest() {
        List<Lead> testLeads = [SELECT Id FROM Lead];
        List<String> leadIds = new List<String>{ testLeads[0].Id, testLeads[1].Id };

        Test.setMock(HttpCalloutMock.class, new POE_ConciergeLeadStatusCalloutMock(false));
        Test.startTest();
        System.enqueueJob(new POE_ConciergeLeadStatusQueueable(leadIds));
        Test.stopTest();

        List<Lead> updatedLeads = [SELECT Id, Concierge_Status__c FROM Lead WHERE Id IN :leadIds];
        Boolean duplicateLeadExists = false;
        Boolean updatedLeadExists = false;
        for (Lead updatedLead : updatedLeads) {
            duplicateLeadExists = updatedLead.Concierge_Status__c == 'Duplicate' || duplicateLeadExists;
            updatedLeadExists = updatedLead.Concierge_Status__c == 'Update' || updatedLeadExists;
        }

        Assert.isFalse(
            duplicateLeadExists || updatedLeadExists,
            'One or all Leads were updated when the callout failed'
        );
    }
}