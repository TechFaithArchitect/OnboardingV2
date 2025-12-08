global class CheckoutTabControllerHttpCalloutMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(
            'PIE.L = 4/n PIE.E = 2/n PIE.K = "12312312312312312312312312312312"/n PIE.key_id = "12345678"/n PIE.phase = 3'
        );
        response.setStatusCode(200);
        return response;
    }
}