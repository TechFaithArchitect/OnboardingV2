public class FlowRedirectController {
    @AuraEnabled
    public static string getMyDomain(){
        return URL.getSalesforceBaseUrl().toExternalForm();
    }
}