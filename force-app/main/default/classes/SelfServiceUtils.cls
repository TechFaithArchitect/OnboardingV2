public without sharing class SelfServiceUtils {
    private static final string CHUZO_DEFAULT_REFERRAL_CODE = System.label.Self_Service_Default_Referral_Code;

    @AuraEnabled
    public static ResponseWrapper getReferralCode(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            response.result = new Map<String, Object>();
            String refCode = (String) myData.get('refCode');

            List<Referral_code__c> codes = [
                SELECT
                    Id,
                    Referral_Code__c,
                    Name,
                    Logo_URL__c,
                    Body__c,
                    Primary_Brand_Color__c,
                    Secondary_Brand_Color__c,
                    Subtitle__c,
                    Title__c,
                    Terms_Of_Use_Link__c,
                    Privacy_Policy_Link__c,
                    Contact_Phone_Number__c,
                    Banner_Description__c,
                    Banner_Logo__c,
                    Has_Exclusive_Offer__c,
                    Exclusive_Offer_Banner_Background_Color__c,
                    Offer_Title__c,
                    Offer_Main_Text__c,
                    Offer_Secondary_Text__c,
                    Offer_Claim_Button_Label__c,
                    Secondary_Banner_URL__c,
                    Secondary_Banner_Redirect_URL__c,
                    Secondary_Banner_Video__c,
                    Primary_Banner_URL__c,
                    Primary_Banner_Video__c,
                    Primary_Banner_Title__c,
                    Primary_Banner_Subtitle__c,
                    Primary_Banner_Button__c,
                    Referral_Account__r.ShopLink_Email__c,
                    Referral_Account__r.ShopLink_Programs__c,
                    Referral_Account__r.Programs_In_Order__c
                FROM Referral_Code__c
                WHERE Name = :refCode
            ];

            if (codes.isEmpty()) {
                codes = [
                    SELECT
                        Id,
                        Referral_Code__c,
                        Name,
                        Logo_URL__c,
                        Body__c,
                        Primary_Brand_Color__c,
                        Secondary_Brand_Color__c,
                        Subtitle__c,
                        Title__c,
                        Terms_Of_Use_Link__c,
                        Privacy_Policy_Link__c,
                        Contact_Phone_Number__c,
                        Banner_Description__c,
                        Banner_Logo__c,
                        Has_Exclusive_Offer__c,
                        Exclusive_Offer_Banner_Background_Color__c,
                        Offer_Title__c,
                        Offer_Main_Text__c,
                        Offer_Secondary_Text__c,
                        Offer_Claim_Button_Label__c,
                        Secondary_Banner_URL__c,
                        Secondary_Banner_Redirect_URL__c,
                        Secondary_Banner_Video__c,
                        Primary_Banner_URL__c,
                        Primary_Banner_Video__c,
                        Primary_Banner_Title__c,
                        Primary_Banner_Subtitle__c,
                        Primary_Banner_Button__c,
                        Referral_Account__r.ShopLink_Email__c,
                        Referral_Account__r.ShopLink_Programs__c,
                        Referral_Account__r.Programs_In_Order__c
                    FROM Referral_Code__c
                    WHERE Referral_Code__c = :CHUZO_DEFAULT_REFERRAL_CODE
                ];
            }

            response.result.put('Code', codes[0]);
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveSelfServiceStatistic(Map<String, Object> myData) {
        try {
            Self_Service_Statistic__c statistic = new Self_Service_Statistic__c(
                Start_Time__c = (Datetime) JSON.deserialize((String) myData.get('startTime'), Datetime.class),
                Tab_Name__c = String.valueOf(myData.get('tabName')),
                Program__c = String.valueOf(myData.get('program')),
                Opportunity__c = String.valueOf(myData.get('opportunityId')),
                Order__c = String.valueOf(myData.get('orderId'))
            );

            insert statistic;

            ResponseWrapper response = new ResponseWrapper();
            response.result = new Map<String, Object>{ 'statistic' => statistic };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper setSelfServiceStatisticEndTime(Map<String, Object> myData) {
        try {
            Self_Service_Statistic__c statistic = new Self_Service_Statistic__c(
                Id = String.valueOf(myData.get('id')),
                End_Time__c = (Datetime) JSON.deserialize((String) myData.get('endTime'), Datetime.class)
            );
            update statistic;

            ResponseWrapper response = new ResponseWrapper();
            response.result = new Map<String, Object>{ 'statistic' => statistic };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getSpectrumSiteId() {
        try {
            Chuzo_Settings__c settings = Chuzo_Settings__c.getInstance();
            return settings != null ? settings.Spectrum_Self_Service_Site_Id__c : null;
        } catch (Exception ex) {
            throw new AuraHandledException('Unable to retrieve Spectrum Site Id. Please contact your administrator.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static Chuzo_Settings__c getChuzoSettings() {
        try {
            return Chuzo_Settings__c.getOrgDefaults();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}