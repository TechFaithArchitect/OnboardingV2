@isTest
public class RecaptchaControllerTestMock implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"success": true}');
        res.setStatusCode(200);
        return res;
    }
}