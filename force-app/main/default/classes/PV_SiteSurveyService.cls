public without sharing class PV_SiteSurveyService {
    
    @AuraEnabled(cacheable=true)
    public static List <SiteSurveyWrapper> fetchSurveyQuestions(String vendorType, String workTypeId) {
        List<SiteSurveyWrapper> srWrapper = new List<SiteSurveyWrapper>();
        List<Site_Survey_Question__c> questions = [
            SELECT
                Id,
                Name,
                Options__c,
                Dependent_Question__c,
                Exp_Parent_Ques_Response__c,
                Is_Dependent_Question__c,
                Order__c,
                Question__c,
                Header__c,
                is_active__c,
                Type__c
            FROM Site_Survey_Question__c
            WHERE (Work_Type__c = :workTypeId AND Work_Type__c != null)
                OR (Vendor_Type__c LIKE :'%' + vendorType + '%' AND Work_Type__c = null)
            ORDER BY Order__c ASC
        ];
        
        for (Site_Survey_Question__c ssq : questions) {
            SiteSurveyWrapper siteSurveyResponse = new SiteSurveyWrapper();
            siteSurveyResponse.question = ssq.Question__c;
            siteSurveyResponse.options =  ssq.Options__c;
            siteSurveyResponse.dependentQuestion = ssq.Dependent_Question__c;
            siteSurveyResponse.order = ssq.Order__c;
            siteSurveyResponse.header = ssq.Header__c;
            siteSurveyResponse.isActive = ssq.is_active__c;
            siteSurveyResponse.type = ssq.Type__c;
            siteSurveyResponse.isDependentQuestion = ssq.Is_Dependent_Question__c;
            siteSurveyResponse.expParentQuesResponse = ssq.Exp_Parent_Ques_Response__c;
            siteSurveyResponse.QuestionId = ssq.ID;
            siteSurveyResponse.value = '';
            
            srWrapper.add(siteSurveyResponse);
        }
        
        return srWrapper;
    }
    
    @AuraEnabled
    public static List<Site_Survey_Response__c> createSurveyResponses(List<Site_Survey_Response__c> surveyResponses) {
        try {
            System.debug('surveyResponses' + surveyResponses);
            upsert surveyResponses;
            return surveyResponses;
        } catch(Exception ex) {
            ExceptionUtil.publishException('SiteSurveyService.createSurveyResponses', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<SiteSurveyWrapper> getVendorType(String recordId) {
        ServiceAppointment serviceAppointment = [
            SELECT
                Id,
                FSSK__FSK_Work_Order__r.Vendor__c,
                FSSK__FSK_Work_Order__r.WorkTypeId,
                FSSK__FSK_Work_Order__r.WorkType.Name,
                FSSK__FSK_Work_Order__r.WorkType.Site_Survey_Allowed_For_Closeout__c,
                Status
            FROM ServiceAppointment WHERE Id = :recordId
            LIMIT 1
        ];

        List<Site_Survey_Question__c> questions = [
            SELECT Id
            FROM Site_Survey_Question__c
            WHERE (Work_Type__c = :serviceAppointment.FSSK__FSK_Work_Order__r.WorkTypeId AND Work_Type__c != null)
                OR (Vendor_Type__c LIKE :'%' + serviceAppointment.FSSK__FSK_Work_Order__r.Vendor__c + '%' AND Work_Type__c = null)
            ORDER BY Order__c ASC
        ];
        
        Boolean isCompVisible = !questions.isEmpty();
        
        List<SiteSurveyWrapper> siteSurveyList = new List<SiteSurveyWrapper>();
        
        SiteSurveyWrapper wrapper = new SiteSurveyWrapper();
        if (isCompVisible) {
            wrapper.availableForComponent = true;
            wrapper.status = serviceAppointment.Status;
            wrapper.vendorType = serviceAppointment.FSSK__FSK_Work_Order__r.Vendor__c;
            wrapper.workTypeId = serviceAppointment.FSSK__FSK_Work_Order__r.WorkTypeId;
            wrapper.siteSurveyAllowedForCloseout = serviceAppointment.FSSK__FSK_Work_Order__r.WorkType.Site_Survey_Allowed_For_Closeout__c;
            siteSurveyList.add(wrapper);
            return siteSurveyList;
        } else {
            wrapper.availableForComponent = false;
            wrapper.status = serviceAppointment.Status;
            siteSurveyList.add(wrapper);
            return siteSurveyList;
        }
    }
    
    @AuraEnabled
    public static List <SiteSurveyWrapper> getSurveyResponse(String recordId, String vendorType, String workTypeId) {
        List <SiteSurveyWrapper> srWrapper = new List<SiteSurveyWrapper>();
        Map<Id, Site_Survey_Response__c> responseMap = new Map<Id, Site_Survey_Response__c>();
        List<Site_Survey_Response__c> response = [
            SELECT
                Id,
                Service_Appointment__c,
                response__c,
                question__c
            FROM Site_Survey_Response__c
            WHERE Service_Appointment__c = :recordId
        ];
        
        List<Site_Survey_Question__c> questions = [
            SELECT
                Id,
                Name,
                Options__c,
                Dependent_Question__c,
                Exp_Parent_Ques_Response__c,
                Is_Dependent_Question__c,
                Order__c,
                Question__c,
                Header__c,
                is_active__c,
                Type__c
            FROM Site_Survey_Question__c
            WHERE (Work_Type__c = :workTypeId AND Work_Type__c != null)
                OR (Vendor_Type__c LIKE :'%' + vendorType + '%' AND Work_Type__c = null)
            ORDER BY Order__c ASC
        ];
        
        for (Site_Survey_Response__c surveyResponses : response) {
            responseMap.put(surveyResponses.question__c,surveyResponses);
        }
        for (Site_Survey_Question__c surveyQuestion : questions) {
            SiteSurveyWrapper siteSurveyResponse = new SiteSurveyWrapper();
            if (responseMap.containsKey(surveyQuestion.Id)) {
                Site_Survey_Response__c responseRecord = responseMap.get(surveyQuestion.Id);
                if (responseRecord != null && responseRecord.question__c == surveyQuestion.Id) {
                    siteSurveyResponse.responseId = responseRecord.Id;
                    siteSurveyResponse.value = responseRecord.response__c;
                }
            }
            siteSurveyResponse.question = surveyQuestion.Question__c;
            siteSurveyResponse.options =  surveyQuestion.Options__c;
            siteSurveyResponse.dependentQuestion = surveyQuestion.Dependent_Question__c;
            siteSurveyResponse.order = surveyQuestion.Order__c;
            siteSurveyResponse.header = surveyQuestion.Header__c;
            siteSurveyResponse.isActive = surveyQuestion.is_active__c;
            siteSurveyResponse.type = surveyQuestion.Type__c;
            siteSurveyResponse.isDependentQuestion = surveyQuestion.Is_Dependent_Question__c;
            siteSurveyResponse.expParentQuesResponse = surveyQuestion.Exp_Parent_Ques_Response__c;
            siteSurveyResponse.QuestionId = surveyQuestion.Id;
            srWrapper.add(siteSurveyResponse);
        }
        return srWrapper;
    }
    
    @AuraEnabled
    public static List<Site_Survey_Response__c> getResponse(String saId) {
        return [
            SELECT response__c, Question_Label__c
            FROM Site_Survey_Response__c
            WHERE Service_Appointment__c = :saId
        ];
    }
    
    public class SiteSurveyWrapper {
        @AuraEnabled
        public boolean availableForComponent;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String vendorType;
        @AuraEnabled
        public String workTypeId;
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String options {get; set;}
        @AuraEnabled
        public String dependentQuestion {get; set;}
        @AuraEnabled
        public String expParentQuesResponse {get; set;}
        @AuraEnabled
        public Boolean isDependentQuestion {get; set;}
        @AuraEnabled
        public Decimal order {get; set;}
        @AuraEnabled
        public String question {get; set;}
        @AuraEnabled
        public String header {get; set;}
        @AuraEnabled
        public Boolean isActive {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public String QuestionId {get; set;}
        @AuraEnabled
        public String responseId {get; set;}
        @AuraEnabled
        public Boolean siteSurveyAllowedForCloseout {get; set;}
        
    }
    
}