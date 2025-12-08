@isTest
public class POE_ConciergeLeadStatusCalloutMock implements HttpCalloutMock {
    public static final String ERROR_MESSAGE = 'Test error';

    private Boolean isSuccess = false;

    public POE_ConciergeLeadStatusCalloutMock(Boolean isSuccess) {
        this.isSuccess = isSuccess;
    }
    
    public HTTPResponse respond(HTTPRequest request) {
        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
        List<Object> leadIds = (List<Object>) requestBody.get('leadIds');

        HTTPResponse res = new HTTPResponse();
        POE_ConciergeLeadStatusQueueable.LeadStatusResult result = new POE_ConciergeLeadStatusQueueable.LeadStatusResult();
        if (this.isSuccess) {
            result.status = 'success';
            POE_ConciergeLeadStatusQueueable.ConciergeLead updatedLead = new POE_ConciergeLeadStatusQueueable.ConciergeLead();
            updatedLead.leadId = (String) leadIds[0];
            updatedLead.leadStatus = 'Update';
            POE_ConciergeLeadStatusQueueable.ConciergeLead duplicateLead = new POE_ConciergeLeadStatusQueueable.ConciergeLead();
            duplicateLead.leadId = (String) leadIds[1];
            duplicateLead.leadStatus = 'Bad Data';
            duplicateLead.bad_data_reason = 'Duplicate';

            result.leads = new List<POE_ConciergeLeadStatusQueueable.ConciergeLead> {
                updatedLead, duplicateLead
            };
        } else {
            result.status = 'error';
            result.message = ERROR_MESSAGE;
        }
        
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(result));
        return res;
    }
}