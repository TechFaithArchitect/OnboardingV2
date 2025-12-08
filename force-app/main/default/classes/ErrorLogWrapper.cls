public with sharing class ErrorLogWrapper {
    public static final String SENSITIVE_INFO_PLACEHOLDER = '*****';
    public static final List<String> SENSITIVE_INFO_FIELD_SET = new List<String>{
        'ccSSN',
        'repeatSSN',
        'ccDOB',
        'ccDL',
        'ccDLstate',
        'ccDLexpDate',
        'DLstate',
        'DLnumber',
        'passcode',
        'passcodeConfirmation',
        'cvv',
        'ccNumber',
        'autopayCvv',
        'autopayCcNumber',
        'ccTypes',
        'cards'
    };

    public String id { get; set; }
    public String name { get; set; }
    @AuraEnabled
    public String type { get; set; }
    @AuraEnabled
    public String provider { get; set; }
    @AuraEnabled
    public String providerSubtype { get; set; }
    @AuraEnabled
    public String tab { get; set; }
    @AuraEnabled
    public String component { get; set; }
    @AuraEnabled
    public String error { get; set; }
    @AuraEnabled
    public String endpoint { get; set; }
    @AuraEnabled
    public String request {
        get {
            return request;
        }
        set {
            request = removeSensitiveInfo(value);
        }
    }
    @AuraEnabled
    public String opportunity { get; set; }
    @AuraEnabled
    public String userId { get; set; }

    @AuraEnabled
    public static String removeSensitiveInfo(String request) {
        try {
            Map<String, Object> rawJsonRequest = (Map<String, Object>) JSON.deserializeUntyped(request);

            for (String fieldName : rawJsonRequest.keySet()) {
                if (fieldName != null && SENSITIVE_INFO_FIELD_SET.contains(fieldName)) {
                    rawJsonRequest.put(fieldName, SENSITIVE_INFO_PLACEHOLDER);
                }
            }

            String clearedJsonRequest = JSON.serialize(rawJsonRequest);
            return clearedJsonRequest;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }
}