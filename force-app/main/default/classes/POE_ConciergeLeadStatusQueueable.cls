public without sharing class POE_ConciergeLeadStatusQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> leadIds;

    public POE_ConciergeLeadStatusQueueable(List<Id> leadIds) {
        this.leadIds = leadIds;
    }

    public void execute(QueueableContext context) {
        if (this.leadIds.isEmpty()) {
            return;
        }

        Map<String, Lead> leadsToGetByExternalId = new Map<String, Lead>();
        for (Lead leadToGet : [
            SELECT Id, Concierge_Status__c, Concierge_External_Id__c, Status
            FROM Lead
            WHERE Id IN :leadIds
        ]) {
            leadsToGetByExternalId.put(leadToGet.Concierge_External_Id__c, leadToGet);
        }

        String path = 'leadStatus';
        Map<String, Object> leadsToGetMap = new Map<String, Object>{
            'path' => path,
            'partnerName' => 'mc',
            'apiVersion' => '1.9',
            'leadIds' => leadsToGetByExternalId.keySet()
        };

        String responseBody = POE_ProvidersApexCallout.callEndpoint(leadsToGetMap);
        LeadStatusResult result = (LeadStatusResult) JSON.deserialize(responseBody, LeadStatusResult.class);

        if (result.status == 'success') {
            Set<String> conciergeStatusValues = getConciergeStatusValues();
            Chuzo_Settings__c setting = Chuzo_Settings__c.getOrgDefaults();
            List<String> lostStatus = setting.Concierge_Lost_Status__c.split(';');
            List<String> wonStatus = setting.Concierge_Won_Status__c.split(';');
            List<Lead> leadsToUpdate = new List<Lead>();

            for (ConciergeLead cLead : result.leads) {
                if (String.isBlank(cLead.leadStatus)) {
                    continue;
                }

                String conciergeLeadStatus = cLead.leadStatus;
                if (conciergeLeadStatus == 'bad data' && String.isNotBlank(cLead.bad_data_reason)) {
                    String badDataReason = cLead.bad_data_reason;
                    if (badDataReason == 'duplicate') {
                        conciergeLeadStatus = badDataReason;
                    }
                }

                if (!conciergeStatusValues.contains(conciergeLeadStatus)) {
                    continue;
                }

                Lead sfLead = leadsToGetByExternalId.get(cLead.leadId);
                if (sfLead?.Concierge_Status__c != cLead.leadStatus) {
                    sfLead.Concierge_Status__c = conciergeLeadStatus;
                    if (wonStatus.contains(conciergeLeadStatus) && sfLead.Status != 'Closed Won') {
                        sfLead.Status = 'Closed Won';
                        for (ConciergeService serv : cLead.services) {
                            if (serv.type == 'security' && serv.activation_date != null) {
                                sfLead.Concierge_Activation_Date__c = Date.valueOf(serv.activation_date);
                            }
                        }
                    } else if (lostStatus.contains(conciergeLeadStatus) && sfLead.Status != 'Closed Lost') {
                        sfLead.Status = 'Closed Lost';
                    }
                    leadsToUpdate.add(sfLead);
                }
            }

            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate;
            }
        } else {
            ErrorLogWrapper error = new ErrorLogWrapper();
            error.type = 'API Error';
            error.component = POE_ConciergeLeadStatusQueueable.class.getName();
            error.error = result.message;
            error.endpoint = path;
            error.request = JSON.serialize(leadsToGetMap);
            ErrorLogModel.logError(error);
        }
    }

    public static Set<String> getConciergeStatusValues() {
        List<Schema.PicklistEntry> conciergeStatusEntries = Lead.Concierge_Status__c.getDescribe().getPicklistValues();

        Set<String> conciergeStatusValues = new Set<String>();
        for (Schema.PicklistEntry conciergeStatusEntry : conciergeStatusEntries) {
            conciergeStatusValues.add(conciergeStatusEntry.getValue());
        }

        return conciergeStatusValues;
    }

    public class LeadStatusResult {
        public String message;
        public String status;
        public List<ConciergeLead> leads;
    }

    public class ConciergeLead {
        public String leadId;
        public String leadStatus;
        public String bad_data_reason;
        public List<ConciergeService> services;
    }

    public class ConciergeService {
        public String type;
        public String stage;
        public String activation_date;
    }
}