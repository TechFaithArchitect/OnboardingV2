@isTest
public class POE_ConciergeLeadStatusSchedulableTest {
    public static final String EXTERNAL_LEAD_ID = 'testleadid';

    @TestSetup
    static void setup() {
        List<Lead> testLeads = TestHelper.getLeads(4);
        for (Integer i = 0; i < testLeads.size() / 2; i++) {
            Lead testLead = testLeads[i];
            testLead.Concierge_External_Id__c = EXTERNAL_LEAD_ID + i;
        }

        insert testLeads;

        Chuzo_Settings__c settings = new Chuzo_Settings__c(
            Concierge_Lost_Status__c = 'Closed - Lost;Duplicate;Disqualified',
            Concierge_Won_Status__c = 'Closed - Won'
        );
        insert settings;
    }

    @isTest
    static void conciergeLeadStatusSchedulableScheduleTest() {
        String jobName = 'POE_ConciergeLeadStatusSchedulableTest' + Datetime.now().getTime();
        Test.setMock(HttpCalloutMock.class, new POE_ConciergeLeadStatusCalloutMock(true));
        Test.startTest();
        System.schedule(jobName, '0 0 0 * * ?', new POE_ConciergeLeadStatusSchedulable());
        Test.stopTest();

        CronTrigger job = [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType
            FROM CronTrigger
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Assert.areEqual(
            job.CronJobDetail.Name,
            jobName,
            'The POE_ConciergeLeadStatusSchedulableTest job was not scheduled'
        );
    }

    @isTest
    static void conciergeLeadStatusSchedulableExecuteTest() {
        Test.setMock(HttpCalloutMock.class, new POE_ConciergeLeadStatusCalloutMock(true));
        Test.startTest();
        new POE_ConciergeLeadStatusSchedulable().execute(null);
        Test.stopTest();

        List<Lead> notUpdatedLeads = [SELECT Id, Concierge_Status__c FROM Lead WHERE Concierge_External_Id__c = NULL];
        for (Lead notUpdatedLead : notUpdatedLeads) {
            Assert.isTrue(
                notUpdatedLead.Concierge_Status__c == 'new',
                'The Leads with no Concierge External Id were updated'
            );
        }

        List<Lead> updatedLeads = [SELECT Id, Concierge_Status__c FROM Lead WHERE Concierge_External_Id__c != NULL];
        for (Lead updatedLead : updatedLeads) {
            Assert.isTrue(
                updatedLead.Concierge_Status__c != 'new',
                'The Leads with a Concierge External Id were not updated'
            );
        }
    }
}