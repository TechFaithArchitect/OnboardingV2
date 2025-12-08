global without sharing class POEgetSiteDetails implements vlocity_cmt.VlocityOpenInterface2 {
    global Object invokeMethod(
        String methodName,
        Map<String, Object> input,
        Map<String, Object> output,
        Map<String, Object> options
    ) {
        Site site = [SELECT Id FROM Site WHERE UrlPathPrefix = 'poe' LIMIT 1];
        String communityUrl = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :site.Id].SecureUrl;
        return output.put('result', communityUrl);
    }
}