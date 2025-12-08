global without sharing class POE_ProvidersApexCallout implements vlocity_cmt.VlocityOpenInterface {
    @testVisible
    private Boolean throwException = false;
    
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;
        try {
            if (throwException) {
                throw new CustomException();
            }

            if ('callEndpoint'.equalsIgnoreCase(methodName)) {
                callEndpoint(inputMap, outMap, options);
            } else {
                result = false;
            }
        } catch (Exception e) {
            outMap.put('error', e.getMessage());
            result = false;
        }
        return result;
    }

    public void callEndpoint(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        String path = (String) inputMap.get('path');
        Map<string, Object> body = (Map<string, Object>) inputMap.get('body');
        HttpRequest req = new HttpRequest();
        
        String nameCredUrl = 'callout:Mulesoft/';

        if(path == 'cmsUrl' && System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName() == 'poetrainin'){
            nameCredUrl = 'callout:Mulesoft_Training_Dev/';
        }

        req.setEndpoint(nameCredUrl + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(body));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        outMap.put('response', res.getBody());
    }

    @AuraEnabled
    public static String callEndpoint(Map<String, Object> inputMap) {
        String path = (String) inputMap.get('path');
        String httpMethod = (String) inputMap.get('httpMethod');
        HttpRequest req = new HttpRequest();

        String nameCredUrl = 'callout:Mulesoft/';

        if(path == 'cmsUrl' && System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName() == 'poetrainin'){
            nameCredUrl = 'callout:Mulesoft_Training_Dev/';
        }

        req.setEndpoint(nameCredUrl + path);
        req.setMethod(String.isNotBlank(httpMethod) ? httpMethod : 'POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(inputMap));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
}