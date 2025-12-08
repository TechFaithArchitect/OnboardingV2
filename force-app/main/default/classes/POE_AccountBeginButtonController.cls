public without sharing class POE_AccountBeginButtonController {
    @AuraEnabled
    public static ResponseWrapper getAvailablePrograms(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String zipCode = (String) myData.get('zip');
            Set<String> programs = new Set<String>();
            String types;
            Set<String> agentPrograms = new Set<String>();

            User agent = [
                SELECT
                    Id,
                    Contact.POE_Programs_Available__c,
                    Contact.POE_Retail_Programs__c,
                    Contact.POE_Event_Programs__c,
                    Contact.D2D_Programs__c,
                    Contact.POE_Representative_Type__c,
                    Contact.MDU_Programs_Available__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];

            types = agent.Contact.POE_Representative_Type__c;

            if (!String.isBlank(agent.Contact.POE_Programs_Available__c)) {
                List<String> phonePrograms = agent.Contact.POE_Programs_Available__c.split(';');
                for (String phoneProgram : phonePrograms) {
                    agentPrograms.add(phoneProgram);
                }
            }

            if (!String.isBlank(agent.Contact.POE_Retail_Programs__c)) {
                List<String> retailPrograms = agent.Contact.POE_Retail_Programs__c.split(';');
                for (String retailProgram : retailPrograms) {
                    agentPrograms.add(retailProgram);
                }
            }

            if (!String.isBlank(agent.Contact.POE_Event_Programs__c)) {
                List<String> eventPrograms = agent.Contact.POE_Event_Programs__c.split(';');
                for (String eventProgram : eventPrograms) {
                    agentPrograms.add(eventProgram);
                }
            }

            if (!String.isBlank(agent.Contact.D2D_Programs__c)) {
                List<String> d2dPrograms = agent.Contact.D2D_Programs__c.split(';');
                for (String d2dProgram : d2dPrograms) {
                    agentPrograms.add(d2dProgram);
                }
            }

            if (!String.isBlank(agent.Contact.MDU_Programs_Available__c)) {
                List<String> mduPrograms = agent.Contact.MDU_Programs_Available__c.split(';');
                for (String mduProgram : mduPrograms) {
                    agentPrograms.add(mduProgram);
                }
            }

            for (POE_ProgramZipCode__c prog : [
                SELECT Program__c
                FROM POE_ProgramZipCode__c
                WHERE Zip_Code__c = :zipCode
            ]) {
                programs.add(prog.Program__c);
            }

            response.result = new Map<String, Object>{
                'agentPrograms' => agentPrograms,
                'types' => types,
                'zipPrograms' => programs
            };

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