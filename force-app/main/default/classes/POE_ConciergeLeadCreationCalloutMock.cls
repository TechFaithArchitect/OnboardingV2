@isTest
public class POE_ConciergeLeadCreationCalloutMock implements HttpCalloutMock {
    public static final String ERROR_MESSAGE = 'Test error';

    private Boolean isSuccess = false;

    public POE_ConciergeLeadCreationCalloutMock(Boolean isSuccess) {
        this.isSuccess = isSuccess;
    }

    public HTTPResponse respond(HTTPRequest request) {
        HTTPResponse res = new HTTPResponse();
        POE_ConciergeLeadCreationQueueable.LeadCreationResult result = new POE_ConciergeLeadCreationQueueable.LeadCreationResult();
        if (this.isSuccess) {
            result.status = 'success';
            result.leadId = POE_ConciergeLeadCreationQueueableTest.EXTERNAL_LEAD_ID;
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