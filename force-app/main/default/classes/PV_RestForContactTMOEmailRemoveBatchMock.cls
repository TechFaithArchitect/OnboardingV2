@isTest
global class PV_RestForContactTMOEmailRemoveBatchMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"Batch started"}');
        res.setStatusCode(200);
        return res;
    }
}