@isTest
public class POE_ScheduleCallControllerTest {
    
    @TestSetup
    static void setup() {
        Account testAccount = TestHelper.getAccounts(1)[0];
        insert testAccount;
    }

    @isTest
    static void createChuzoLeadTest() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        POE_ScheduleCallController.ChuzoLead lead = new POE_ScheduleCallController.ChuzoLead();
        lead.accountId = testAccount.Id;
        lead.firstName = 'Lead';
        lead.lastName = 'Test';
        lead.phone = '4444444484';
        lead.email = 'leadTest@test.com';
        lead.preferredContactMethod = 'Email';
        lead.preferredContactTime = '1:00 pm to 2:00 pm';
        lead.programs = new List<String> { 'DIRECTV', 'Spectrum' };
        lead.address = new POE_ScheduleCallController.AddressInfo();
        lead.address.addressLine1 = 'Test Street';
        lead.address.addressLine2 = 'Test Apt';
        lead.address.city = 'Test City';
        lead.address.state = 'CA';
        lead.address.zipCode = '91750';

        Test.setMock(HttpCalloutMock.class, new POE_ConciergeLeadCreationCalloutMock(true));
        Test.startTest();
        Map<String, Object> result = POE_ScheduleCallController.createChuzoLead(lead);
        Test.stopTest();

        Assert.isTrue(
            result.containsKey('leadId') && 
            String.isNotBlank((String) result.get('leadId')),
            'The Lead Id was not included in the response.'
        );

        String leadId = (String) result.get('leadId');
        Integer resultLeadCount = [
            SELECT COUNT()
            FROM Lead
            WHERE Id = :leadId
        ];
        Assert.areEqual(
            1, resultLeadCount,
            'The Id included in the response does not correspond to an existing Lead'
        );
    }

    @isTest
    static void createChuzoLeadWithShopLinkEmailTest() {
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        POE_ScheduleCallController.ChuzoLead lead = new POE_ScheduleCallController.ChuzoLead();
        lead.accountId = testAccount.Id;
        lead.firstName = 'ShopLink';
        lead.lastName = 'Test';
        lead.phone = '4444444485';
        lead.email = 'shoplink@test.com';
        lead.preferredContactMethod = 'Email';
        lead.preferredContactTime = '1:00 pm to 2:00 pm';
        lead.programs = new List<String> { 'DIRECTV', 'Spectrum' };
        lead.ShopLinkEmail = 'dealer@test.com';
        lead.type = 'Other'; 
        
        Test.startTest();
        
        Map<String, Object> result = POE_ScheduleCallController.createChuzoLead(lead);
        
        Test.stopTest();

        String leadId = (String) result.get('leadId');
        Lead createdLead = [
            SELECT Id, Concierge_Status__c, Type__c
            FROM Lead
            WHERE Id = :leadId
        ];
        
        Assert.areEqual('Non Concierge', createdLead.Concierge_Status__c, 'Lead should be marked as Non Concierge');
    }
}