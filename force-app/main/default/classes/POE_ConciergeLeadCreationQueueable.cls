public without sharing class POE_ConciergeLeadCreationQueueable implements Queueable, Database.AllowsCallouts {
    private static final Set<String> LEAD_TYPES = new Set<String>{ 'Telecom', 'Security' };
    private Id leadIdToCreate;

    public POE_ConciergeLeadCreationQueueable(Id leadIdToCreate) {
        this.leadIdToCreate = leadIdToCreate;
    }

    @InvocableMethod(label='Submit Lead to Concierge')
    public static void createJob(List<Id> leadIds) {
        System.enqueueJob(new POE_ConciergeLeadCreationQueueable(leadIds[0]));
    }

    public void execute(QueueableContext context) {
        Lead leadToCreate = [
            SELECT
                Id,
                Name,
                Phone,
                Email,
                Interested_Programs__c,
                Preferred_Contact_Method__c,
                Preferred_Contact_Time__c,
                Concierge_External_Id__c,
                Concierge_Status__c,
                Street,
                Address_Line_2__c,
                City,
                State,
                PostalCode,
                Country,
                Type__c,
                Referral_Code__c,
                Referral_Code__r.Referral_Code__c
            FROM Lead
            WHERE Id = :this.leadIdToCreate
        ];
        String programInterests = String.isBlank(leadToCreate.Interested_Programs__c)
            ? ''
            : leadToCreate.Interested_Programs__c.replaceAll(';', ', ');
        String leadComments = '';
        if (String.isNotBlank(leadToCreate.Preferred_Contact_Method__c)) {
            leadComments += 'Preferred Contact Method: ' + leadToCreate.Preferred_Contact_Method__c;
        }
        if (String.isNotBlank(leadToCreate.Preferred_Contact_Time__c)) {
            leadComments = String.isBlank(leadComments) ? '' : leadComments + '\n';
            leadComments += 'Preferred Contact Time: ' + leadToCreate.Preferred_Contact_Time__c;
        }
        if (String.isNotBlank(programInterests)) {
            leadComments = String.isBlank(leadComments) ? '' : leadComments + '\n';
            leadComments += 'Program Interests: ' + programInterests;
        }

        Map<String, Object> contactMap = new Map<String, Object>{
            'name' => leadToCreate.Name,
            'contactClass' => 'Applicant',
            'mobilePhone' => leadToCreate.Phone,
            'email' => leadToCreate.Email
        };

        String path = 'submitLeads';
        Map<String, Object> leadToCreateRequestMap = new Map<String, Object>{
            'path' => path,
            'partnerName' => 'mc',
            'apiVersion' => '1.9',
            'leadStatus' => 'new',
            'leadType' => LEAD_TYPES.contains(leadToCreate.Type__c) ? leadToCreate.Type__c : 'Other',
            'contacts' => new List<Object>{ contactMap },
            'comments' => leadComments,
            'externalField1' => this.leadIdToCreate
        };

        String referralCode = String.isBlank(leadToCreate.Referral_Code__c)
            ? 'PV' // Fallback for no Referral Code
            : leadToCreate.Referral_Code__r.Referral_Code__c;
        Map<String, Object> referralMap = new Map<String, Object>{ 'company' => referralCode };
        leadToCreateRequestMap.put('referral', referralMap);

        if (leadHasAddress(leadToCreate)) {
            Map<String, Object> addressMap = new Map<String, Object>{
                'addressType' => 'Current',
                'address' => leadToCreate.Street,
                'unit' => leadToCreate.Address_Line_2__c != null ? leadToCreate.Address_Line_2__c : '',
                'city' => leadToCreate.City,
                'state' => leadToCreate.State,
                'zip' => leadToCreate.PostalCode
            };
            leadToCreateRequestMap.put('addresses', new List<Object>{ addressMap });
        }

        String responseBody = POE_ProvidersApexCallout.callEndpoint(leadToCreateRequestMap);
        LeadCreationResult result = (LeadCreationResult) JSON.deserialize(responseBody, LeadCreationResult.class);

        if (result.status == 'success') {
            leadToCreate.Concierge_External_Id__c = result.leadId;
            update leadToCreate;
        } else {
            leadToCreate.Concierge_Status__c = null;
            update leadToCreate;

            ErrorLogWrapper error = new ErrorLogWrapper();
            error.type = 'API Error';
            error.component = POE_ConciergeLeadCreationQueueable.class.getName();
            error.error = result.message;
            error.endpoint = path;
            error.request = JSON.serialize(leadToCreateRequestMap);
            ErrorLogModel.logError(error);
        }
    }

    private static Boolean leadHasAddress(Lead l) {
        return String.isNotBlank(l.Street) &&
            String.isNotBlank(l.City) &&
            String.isNotBlank(l.State) &&
            String.isNotBlank(l.PostalCode);
    }

    public class LeadCreationResult {
        public String message;
        public String status;
        public String leadId;
    }
}