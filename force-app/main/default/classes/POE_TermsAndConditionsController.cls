public without sharing class POE_TermsAndConditionsController {
    @AuraEnabled
    public static void confirmTermsAgreement(String recordId) {
        try {
            String opportunityId = recordId;
            if (POE_PublicRecordAccessUtility.isEncryptedId(recordId)) {
                opportunityId = POE_PublicRecordAccessUtility.decryptRecordId(recordId);
            }

            Opportunity opp = [
                SELECT Id, POE_Terms_and_Conditions_Accepted__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

            opp.POE_Terms_and_Conditions_Accepted__c = true;
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getTermsAgreement(String opportunityId) {
        try {
            Opportunity opp = [
                SELECT Id, POE_Terms_and_Conditions_Accepted__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

            ResponseWrapper response = new ResponseWrapper();
            response.result = new Map<String, Object>{ 'termsAgreed' => opp.POE_Terms_and_Conditions_Accepted__c };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getTermsAndConditions(String recordId) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            String opportunityId = recordId;
            if (POE_PublicRecordAccessUtility.isEncryptedId(recordId)) {
                try {
                    opportunityId = POE_PublicRecordAccessUtility.decryptRecordId(recordId);
                } catch (Exception e) {
                    response.result = new Map<String, Object>{ 'noOppFound' => true };
                    return response;
                }
            }

            List<Opportunity> oppList = [
                SELECT
                    POE_Cart_Terms_And_Conditions__c,
                    POE_Terms_and_Conditions_Accepted__c,
                    Maps_Street__c,
                    Maps_Appartment__c,
                    Maps_City__c,
                    Maps_State__c,
                    Maps_PostalCode__c,
                    Account.FirstName,
                    Account.LastName
                FROM Opportunity
                WHERE Id = :opportunityId
            ];
            if (oppList.size() == 0) {
                response.result = new Map<String, Object>{ 'noOppFound' => true };
                return response;
            }

            Opportunity opp = oppList[0];
            String signatureName = opp.Account.FirstName + ' ' + opp.Account.LastName;
            String signatureAddress = opp.Maps_Street__c;
            if (String.isNotBlank(opp.Maps_Appartment__c)) {
                signatureAddress += ' ' + opp.Maps_Appartment__c;
            }
            signatureAddress += ' ' + opp.Maps_City__c + ' ' + opp.Maps_State__c + ', ' + opp.Maps_PostalCode__c;
            String termsJSON = opp.POE_Cart_Terms_And_Conditions__c;

            response.result = new Map<String, Object>{
                'terms' => JSON.deserializeUntyped(termsJSON),
                'termsAccepted' => opp.POE_Terms_and_Conditions_Accepted__c,
                'signatureName' => signatureName,
                'signatureAddress' => signatureAddress
            };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveTermsAndConditions(String opportunityId, String termsJSON) {
        try {
            Opportunity opp = [
                SELECT Id, POE_Cart_Terms_And_Conditions__c, POE_Terms_and_Conditions_Accepted__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

            opp.POE_Cart_Terms_And_Conditions__c = termsJSON;
            opp.POE_Terms_and_Conditions_Accepted__c = false;
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateCommunicationConsent(String opportunityId) {
        try {
            String recordId;
            if (POE_PublicRecordAccessUtility.isEncryptedId(opportunityId)) {
                recordId = POE_PublicRecordAccessUtility.decryptRecordId(opportunityId);
            } else {
                recordId = opportunityId;
            }

            Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :recordId LIMIT 1];

            Account acc = [SELECT Id, DTV_Communication_Consent__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];

            if (!acc.DTV_Communication_Consent__c) {
                acc.DTV_Communication_Consent__c = true;
                update acc;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper sendTermsAndConditionSMS(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            POE_Callout_Config_API__mdt twilioConfig = POE_Callout_Config_API__mdt.getInstance('Twilio');
            Map<String, Object> input = new Map<String, Object>{
                'To' => (String) myData.get('clientPhone'),
                'From' => twilioConfig.Phone__c,
                'Body' => ((String) myData.get('body')).replaceAll('&', '%26'),
                'AccountId' => twilioConfig.User__c,
                'Password' => twilioConfig.Password__c
            };

            POESendPCISMS sendTermsSMS = new POESendPCISMS();
            Boolean success = sendTermsSMS.invokeMethod(null, input, null, null);

            response.result = new Map<String, Object>{ 'success' => success };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper sendTermsAndConditionEmail(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String email = (String) myData.get('email');
            String body = (String) myData.get('body');
            body = body == null ? '' : body;

            OrgWideEmailAddress orgWideEmail = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = 'no-reply@chuzo.com'
            ];
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setOrgWideEmailAddressId(orgWideEmail.Id);
            emailMessage.setToAddresses(new List<String>{ email });
            emailMessage.setSubject(System.Label.POE_Terms_Email_Subject);
            emailMessage.setHtmlBody(System.Label.POE_Terms_Email_Body.replace('{HREF}', body));

            Messaging.SendEmailResult emailResult = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ emailMessage }
            )[0];

            response.result = new Map<String, Object>{ 'success' => emailResult.isSuccess() };
            if (!emailResult.isSuccess()) {
                response.result.put('errorMessage', emailResult.getErrors()[0].getMessage());
            }

            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getTermsAndConditionsPath(String opportunityId) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String encryptedOppId = POE_PublicRecordAccessUtility.encryptRecordId(opportunityId);

            Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();
            String publicTermsPath = settings.Chuzo_Terms_Public_Page_Path__c;
            publicTermsPath = publicTermsPath + '?recordId=' + EncodingUtil.urlEncode(encryptedOppId, 'UTF-8');

            response.result = new Map<String, Object>{ 'termsAndConditionsPath' => publicTermsPath };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}