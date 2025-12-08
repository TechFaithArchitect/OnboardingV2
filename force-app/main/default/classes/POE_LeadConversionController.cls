public class POE_LeadConversionController {
    @InvocableMethod(
        label='Convert POE Leads'
        description='Takes a List of Leads to Convert and returns a List of Opportunities'
        category='Lead'
    )
    public static List<List<Opportunity>> convertLead(List<List<Lead>> inputLeadList) {
        List<Account> accountsToAssign = new List<Account>();
        List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
        List<Lead> inputLeads = inputLeadList[0];
        Map<String, Account> accountById = new Map<String, Account>();
        Set<String> companyIds = new Set<String>();
        Set<String> contactIds = new Set<String>();
        Map<String,String> userIdByContactId = new Map<String,String>();
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        for (Lead inputLead : inputLeads) {
            Account newPersonAccount = new Account();
            newPersonAccount.FirstName = inputLead.FirstName;
            newPersonAccount.LastName = inputLead.LastName;
            newPersonAccount.Phone = inputLead.Phone;
            newPersonAccount.PersonEmail = inputLead.Email;
            newPersonAccount.RecordTypeId = personAccountRecordTypeId;
            newPersonAccount.BillingCity = inputLead.City;
            newPersonAccount.BillingCountry = inputLead.Country;
            newPersonAccount.BillingPostalCode = inputLead.PostalCode;
            newPersonAccount.BillingState = inputLead.State;
            newPersonAccount.BillingStreet = inputLead.Street;
            newPersonAccount.ShippingCity = inputLead.City;
            newPersonAccount.ShippingCountry = inputLead.Country;
            newPersonAccount.ShippingPostalCode = inputLead.PostalCode;
            newPersonAccount.ShippingState = inputLead.State;
            newPersonAccount.ShippingStreet = inputLead.Street;
            if (String.isNotBlank(inputLead.Company)) {
                companyIds.add(inputLead.Company);
            }
            accountsToAssign.add(newPersonAccount);
        }
        insert accountsToAssign;

        if (!companyIds.isEmpty()) {
            for (Account acc : [
                SELECT Id, P10_Invoice_Account__c, POE_ICL_Owner__c
                FROM Account
                WHERE P10_Invoice_Account__c IN :companyIds
            ]) {
                accountById.put(acc.P10_Invoice_Account__c, acc);
                contactIds.add(acc.POE_ICL_Owner__c);
            }
        }

        for (User owner : [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIds]) {
            userIdByContactId.put(owner.ContactId, owner.Id);
        }

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];

        for (Integer i = 0; i < accountsToAssign.size(); i++) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setAccountId(accountsToAssign[i].Id);
            lc.setLeadId(inputLeads[i].Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            String name = inputLeads[i].FirstName + ' ' + inputLeads[i].LastName;
            if (inputLeads[i].FirstName == null) {
                name = inputLeads[i].LastName;
            }
            lc.setOpportunityName(name);
            leadsToConvert.add(lc);
        }

        List<String> createdOpportunitiesId = new List<String>();

        for (Integer i = 0; i <= leadsToConvert.size() / 100; i++) {
            list<Database.LeadConvert> tempList = new List<Database.LeadConvert>();
            Integer startIndex = i * 100;
            Integer endIndex = ((startIndex + 100) < leadsToConvert.size()) ? startIndex + 100 : leadsToConvert.size();
            for (Integer j = startIndex; j < endIndex; j++) {
                tempList.add(leadsToConvert[j]);
            }
            Database.LeadConvertResult[] lcrList = Database.convertLead(tempList);

            for (Database.LeadConvertResult convertResult : lcrList) {
                createdOpportunitiesId.add(convertResult.getOpportunityId());
            }
        }

        Map<Id, Lead> LeadByOpportunityId = new Map<Id, Lead>();
        for (Lead convertedLead : [
            SELECT
                ConvertedOpportunityId,
                Id,
                IsConverted,
                Type__c,
                Address_Line_2__c,
                Address_Line_2_Type__c,
                Programs__c,
                Company
            FROM Lead
            WHERE IsConverted = TRUE AND ConvertedOpportunityId IN :createdOpportunitiesId
        ]) {
            LeadByOpportunityId.put(convertedLead.ConvertedOpportunityId, convertedLead);
        }

        List<Opportunity> createdOpportunitiesToUpdateAddress = [
            SELECT
                Id,
                StageName,
                POE_Clicker_Origin__c,
                Account.BillingCity,
                Account.BillingCountry,
                Account.BillingPostalCode,
                Account.BillingState,
                Account.BillingStreet
            FROM Opportunity
            WHERE ID IN :createdOpportunitiesId
        ];

        List<Opportunity> auxOppList = new List<Opportunity>();
        for (Opportunity opp : createdOpportunitiesToUpdateAddress) {
            opp.Maps_City__c = opp.Account.BillingCity;
            opp.Maps_Country__c = opp.Account.BillingCountry;
            opp.Maps_PostalCode__c = opp.Account.BillingPostalCode;
            opp.Maps_State__c = opp.Account.BillingState;
            opp.Maps_Street__c = opp.Account.BillingStreet;
            opp.Maps_Appartment__c =
                LeadByOpportunityId.get(opp.Id).Address_Line_2_Type__c +
                ' ' +
                LeadByOpportunityId.get(opp.Id).Address_Line_2__c;
            opp.POE_Program__c = LeadByOpportunityId.get(opp.Id).Programs__c;
            opp.StageName = 'Opportunity';
            opp.POE_Clicker_Origin__c = LeadByOpportunityId.get(opp.Id).Type__c + '-Lead';
            if (String.isNotBlank(LeadByOpportunityId.get(opp.Id).Company)) {
                opp.POE_Dealer__c = accountById.get(LeadByOpportunityId.get(opp.Id).Company).Id;
                opp.OwnerId =  userIdByContactId.get(accountById.get(LeadByOpportunityId.get(opp.Id).Company).POE_ICL_Owner__c);
            }
            auxOppList.add(opp);
        }
        update auxOppList;

        List<Opportunity> createdOpportunities = [
            SELECT POE_Dealer__c
            FROM Opportunity
            WHERE ID IN :createdOpportunitiesId
        ];

        List<List<Opportunity>> returnList = new List<List<Opportunity>>();
        returnList.add(createdOpportunities);
        return returnList;
    }
}