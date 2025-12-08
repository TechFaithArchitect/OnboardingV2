public without sharing class POE_ScheduleCallController {
    @AuraEnabled
    public static Map<String, Object> createChuzoLead(ChuzoLead leadToCreate) {
        try {
            Id chuzoLeadRTId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('Chuzo_Lead')
                .getRecordTypeId();

            String interestedPrograms = String.join(leadToCreate.programs, ';');
            Lead newLead = new Lead(
                Id = leadToCreate.leadId,
                Person_Account__c = leadToCreate.accountId,
                RecordTypeId = chuzoLeadRTId,
                FirstName = leadToCreate.firstName,
                LastName = leadToCreate.lastName,
                Phone = leadToCreate.phone,
                Email = leadToCreate.email,
                LeadSource = leadToCreate.leadSource,
                Concierge_Status__c = 'new',
                Interested_Programs__c = interestedPrograms,
                Preferred_Contact_Method__c = leadToCreate.preferredContactMethod,
                Preferred_Contact_Time__c = leadToCreate.preferredContactTime
            );

            if (String.isNotBlank(leadToCreate.type)) {
                newLead.Type__c = leadToCreate.type;
            }

            if (String.isNotBlank(leadToCreate.owner)) {
                newLead.OwnerId = leadToCreate.owner;
            }

            if (String.isNotBlank(leadToCreate.referralCodeId)) {
                newLead.Referral_Code__c = leadToCreate.referralCodeId;
            }

            if (String.isNotBlank(leadToCreate.ip)) {
                newLead.Consent_IP__c = leadToCreate.ip;
            }

            if (leadToCreate.latitude != 0) {
                newLead.Consent_Geolocation__latitude__s = leadToCreate.latitude;
            }

            if (leadToCreate.longitude != 0) {
                newLead.Consent_Geolocation__longitude__s = leadToCreate.longitude;
            }

            if (leadToCreate.address != null) {
                newLead.Street = leadToCreate.address.addressLine1;
                newLead.Address_Line_2__c = leadToCreate.address.addressLine2;
                newLead.Address_Line_2_Type__c = String.isNotBlank(newLead.Address_Line_2__c) ? 'None' : '';
                newLead.City = leadToCreate.address.city;
                newLead.StateCode = leadToCreate.address.state;
                newLead.PostalCode = leadToCreate.address.zipCode;
                if (String.isNotBlank(leadToCreate.address.country)) {
                    newLead.Country = leadToCreate.address.country;
                } else {
                    newLead.Country = 'United States';
                }
            }

            if (String.isNotBlank(leadToCreate.ShopLinkEmail)) {
                newLead.Concierge_Status__c = 'Non Concierge';
            }

            Database.DMLOptions options = new Database.DMLOptions();
            options.DuplicateRuleHeader.AllowSave = true;
            options.optAllOrNone = true;
            if (String.isBlank(newLead.Id)) {
                Database.insert(newLead, options);
            } else {
                Database.update(newLead, options);
            }

            if (String.isNotBlank(leadToCreate.ShopLinkEmail)) {
                sendEmailToDealer(leadToCreate.ShopLinkEmail, newLead);
            }

            return new Map<String, Object>{ 'leadId' => newLead.Id };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void sendEmailToDealer(String shopLinkEmail, Lead newLead) {
        try {
            
            String emailBody = buildEmailBody(newLead);
            String emailSubject = 'New Lead Assignment - ' + newLead.FirstName + ' ' + newLead.LastName;
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { shopLinkEmail });
            mail.setSubject(emailSubject);
            mail.setHtmlBody(emailBody);
            mail.setSaveAsActivity(false);
            
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply@chuzo.com' LIMIT 1];
            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea[0].Id);
            }
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         
        } catch (Exception e) {
            System.debug('Exception in sendEmailToDealer: ' + e.getMessage());
        }
    }

    private static String buildEmailBody(Lead leadData) {
        String firstName = leadData.FirstName != null ? leadData.FirstName : '';
        String lastName = leadData.LastName != null ? leadData.LastName : '';
        String phone = leadData.Phone != null ? leadData.Phone : '';
        String email = leadData.Email != null ? leadData.Email : '';
        String contactTime = leadData.Preferred_Contact_Time__c != null ? leadData.Preferred_Contact_Time__c : '';
        String programs = leadData.Interested_Programs__c != null ? leadData.Interested_Programs__c : '';
        
        String programsHtml = '';
        if (String.isNotBlank(programs)) {
            List<String> programList = programs.split(';');
            for (String program : programList) {
                if (String.isNotBlank(program)) {
                    programsHtml += program.trim() + '<br />';
                }
            }
        }

        String headerImageUrl = 'https://storage.pardot.com/1014532/17476701192yVaORPA/Chuzo_Shoplink_bnr.jpg';
        String footerImageUrl = 'https://storage.pardot.com/1014532/1747673392HRsy5Ztj/PV_logo_e.jpg';
        String currentYear = String.valueOf(System.today().year());

        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'emailTemplates' LIMIT 1];
        String template = sr.Body.toString();

        template = template.replace('{!firstName}', firstName);
        template = template.replace('{!lastName}', lastName);
        template = template.replace('{!email}', email);
        template = template.replace('{!phone}', phone);
        template = template.replace('{!contactTime}', contactTime);
        template = template.replace('{!programsHtml}', programsHtml);
        template = template.replace('{!headerImageUrl}', headerImageUrl);
        template = template.replace('{!footerImageUrl}', footerImageUrl);
        template = template.replace('{!currentYear}', currentYear);

        return template;
    }

    public class ChuzoLead {
        @AuraEnabled
        public String leadId { get; set; }
        @AuraEnabled
        public String accountId { get; set; }
        @AuraEnabled
        public String referralCodeId { get; set; }
        @AuraEnabled
        public String firstName { get; set; }
        @AuraEnabled
        public String lastName { get; set; }
        @AuraEnabled
        public String phone { get; set; }
        @AuraEnabled
        public String email { get; set; }
        @AuraEnabled
        public String preferredContactMethod { get; set; }
        @AuraEnabled
        public String preferredContactTime { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String leadSource { get; set; }
        @AuraEnabled
        public List<String> programs { get; set; }
        @AuraEnabled
        public AddressInfo address { get; set; }
        @AuraEnabled
        public Decimal latitude { get; set; }
        @AuraEnabled
        public Decimal longitude { get; set; }
        @AuraEnabled
        public String ip { get; set; }
        @AuraEnabled
        public String owner { get; set; }
        @AuraEnabled
        public String ShopLinkEmail { get; set; }
        @AuraEnabled
        public String ShopLinkPrograms { get; set; }
    }

    public class AddressInfo {
        @AuraEnabled
        public String addressLine1 { get; set; }
        @AuraEnabled
        public String addressLine2 { get; set; }
        @AuraEnabled
        public String city { get; set; }
        @AuraEnabled
        public String state { get; set; }
        @AuraEnabled
        public String zipCode { get; set; }
        @AuraEnabled
        public String country { get; set; }
    }
}