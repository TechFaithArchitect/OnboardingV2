public without sharing class InstallationTPVTabController {
    @AuraEnabled
    public static ResponseWrapper getTPVSettings(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');

            Opportunity opp = [
                SELECT Id, POE_QuantityOfAttempts__c, POE_Reference_Number__c, POE_TPV_Verified__c
                FROM Opportunity
                WHERE Id = :oppId
            ];
            User currentUser = [
                SELECT Id, Account.POE_Require_TPV__c, Contact.POE_Enable_Trial_Period__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            Boolean tpvBool =
                (!opp.POE_TPV_Verified__c) &&
                (currentUser.Contact.POE_Enable_Trial_Period__c || currentUser.Account.POE_Require_TPV__c);

            response.result = new Map<String, Object>{ 'TPVText' => tpvBool ? 'Yes' : 'No', 'referenceNumber' => opp };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getSelfInstallFlag() {
        try {
            User agent = [SELECT Id, AccountId FROM User WHERE Id = :System.UserInfo.getUserId() LIMIT 1];
            Account dealer = [SELECT Id, Self_Install_Allowed__c FROM Account WHERE Id = :agent.AccountId];
            return dealer.Self_Install_Allowed__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper convertDatesTimeZone(Map<String, Object> inputMap) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String zoneValue = (String) inputMap.get('timeZone');
            String payload = (String) inputMap.get('data');
            Timezone tz = Timezone.getTimeZone(zoneValue);

            List<Map<String, Object>> slots = new List<Map<String, Object>>();
            List<Object> deserialized = (List<Object>) JSON.deserializeUntyped(payload);
            for (Object result : deserialized) {
                Map<String, Object> data = (Map<String, Object>) result;
                String baseDate = ((String) data.get('day')).replace('-', '').replace('/', '');
                String startString = (String) data.get('startTime');
                String endString = (String) data.get('endTime');
                Integer year = Integer.valueOf(baseDate.substring(0, 4));
                Integer month = Integer.valueOf(baseDate.substring(4, 6));
                Integer day = Integer.valueOf(baseDate.substring(6, 8));
                Integer startTime = Integer.valueOf(startString.substring(0, 2));
                Integer endTime = Integer.valueOf(endString.substring(0, 2));
                DateTime startDate = DateTime.newInstanceGMT(year, month, day, startTime, 0, 0);
                DateTime endDate = DateTime.newInstanceGMT(year, month, day, endTime, 0, 0);
                Integer tzOffset = tz.getOffset(startDate);
                Datetime targetDatetimeStart = startDate.addSeconds(tzOffset / 1000);
                Datetime targetDatetimeEnd = endDate.addSeconds(tzOffset / 1000);
                Map<String, Object> d = new Map<String, Object>();
                d.put('startTime', targetDatetimeStart.toString());
                d.put('endTime', targetDatetimeEnd.toString());
                slots.add(d);
            }

            response.result = new Map<String, Object>{ 'slot' => slots };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateOrder(Map<String, Object> myData) {
        try {
            Order ord = new Order(
                Id = (String) myData.get('id'),
                POE_InstallationDate__c = Date.valueOf((String) myData.get('installationDate'))
            );

            update ord;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}