@isTest
global class POESMSHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(
            '{"sid": "SM665257d28c9748848ebfa853aa1de6a7","date_created": "Tue, 24 May 2022 22:59:49 +0000", "date_updated": "Tue, 24 May 2022 22:59:49 +0000","date_sent": null,"account_sid": "ACdc82f57944869cb7cf90dbf66880a029","to": "+5491140457664","from": "+18506045257","messaging_service_sid": null,"body": "Sent from your Twilio trial account - Test","status": "queued","num_segments": "1","num_media": "0","direction": "outbound-api","api_version": "2010-04-01","price": null,"price_unit": "USD","error_code": null,"error_message": null,"uri": "/2010-04-01/Accounts/ACdc82f57944869cb7cf90dbf66880a029/Messages/SM665257d28c9748848ebfa853aa1de6a7.json","subresource_uris": {"media": "/2010-04-01/Accounts/ACdc82f57944869cb7cf90dbf66880a029/Messages/SM665257d28c9748848ebfa853aa1de6a7/Media.json"}}'
        );
        response.setStatusCode(200);
        return response;
    }
}