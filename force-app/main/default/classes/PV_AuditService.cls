public class PV_AuditService {
    @testVisible private static Boolean throwException = false;

    @AuraEnabled(cacheable=true)
    public static boolean getCompletedAudit(String workOrderId) {
        try {
            if (Test.isRunningTest() && throwException) {
                throw new CustomException();
            }

            String ExceptionStatus = PV_FSL_Config__mdt.getInstance('Audit_status_exception').Value__c;
            List<Audit__c> auditList = [select id from Audit__c where Work_Order__c = :workOrderId order by CreatedDate desc limit 1];
            List<string> ExceptionStatusList;
            List<ServiceAppointment> appointmentList;

            if (ExceptionStatus != null && ExceptionStatus != ' ') {
                ExceptionStatusList=ExceptionStatus.split(',');
            }
            
            boolean py = false;
            
            if (ExceptionStatusList != null) {
                appointmentList = [
                    SELECT  id, Status 
                    FROM    ServiceAppointment 
                    WHERE   Status NOT IN :ExceptionStatusList AND ParentRecordId = :workOrderId
                    ORDER BY CreatedDate desc 
                    LIMIT 1
                ];
            } else {
                appointmentList = [
                    SELECT  id, Status
                    FROM    ServiceAppointment
                    WHERE   ParentRecordId = :workOrderId
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
            }

            Boolean hasCustomEditPermission = FeatureManagement.checkPermission('Audit_edit_access');
            Boolean hasCustomViewPermission = FeatureManagement.checkPermission('QA_Auditor_view_only');
         
            if (!appointmentList.isEmpty() && hasCustomViewPermission &&(!auditList.isEmpty())) {
                py = true;
            } else if (!appointmentList.isEmpty() && hasCustomEditPermission) {
                py = true; 
            }
            
            return py;
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_AuditService.class.getName(), e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Method to get fetchAuditQuestions
    @AuraEnabled(cacheable=true)
    public static List<Audit_Question__c> fetchAuditQuestions(String workTypeId) {
        List<Audit_Question__c> questions = [
            SELECT
                Id, Name, Options__c, Dependent_Question__c, Exp_Parent_Ques_Response__c, Is_Dependent_Question__c, Order__c, Question__c,
                Header__c, is_active__c, Width__c, Default_value__c, Type__c, WorkType__c
            FROM    Audit_Question__c 
            WHERE   WorkType__c = :workTypeId
            ORDER BY Order__c ASC
        ];
        return questions;
    }

    // Method to get related audit of work order
    @AuraEnabled(cacheable=true)
    public static List<Audit_Response__c> fetchRelatedAudit(String AuditId) {
        List<Audit_Response__c> questions = [
            SELECT  
                Id, Name, Audit_Question__r.Options__c, Audit_Question__r.Dependent_Question__c, Audit_Question__r.Exp_Parent_Ques_Response__c,
                Audit_Question__r.Is_Dependent_Question__c, Audit_Question__r.Order__c, Audit_Question__r.Width__c, Audit_Question__r.Question__c,
                Audit_Question__r.Header__c, IsActive__c, Audit_Question__r.Type__c, Audit_Question__r.Read_only__c, Audit_Question__r.WorkType__c,
                Response__c
            FROM    Audit_Response__c
            WHERE   Audit__c = :AuditId
            ORDER BY Audit_Question__r.Order__c ASC
        ];
        
        return questions;
    }
    
    // Method to get all the setting related to Audit
    @AuraEnabled
    public static List<AuditWrapper> getAuditConfiguration(string recordId) {
        try {
            List<Audit__c> auditList = [SELECT Id FROM Audit__c WHERE Work_Order__c = :recordId ORDER BY CreatedDate DESC LIMIT 1];
            List<Audit_Response__c> auditResponseList = new List<Audit_Response__c>();

            if (!auditList.isEmpty()) {
                auditResponseList = fetchRelatedAudit(auditList[0].Id);
            }

            List<WorkOrder> wo = [SELECT Id, Vendor__c, WorkTypeId, Status FROM WorkOrder WHERE Id = :recordId];
            List<string> nosinglefailurevendor = PV_FSL_Config__mdt.getInstance('Audit_no_single_failure').Value__c.split(',');
            Boolean hasCustomEditPermission = FeatureManagement.checkPermission('Audit_edit_access');
            List<AuditWrapper> AuditWrapperList = new List<AuditWrapper>();
            
            AuditWrapper wrapperObj = new AuditWrapper();
            if (!auditList.isEmpty() && !auditResponseList.isEmpty()) {
                wrapperObj.auditId = auditList[0].Id;
                wrapperObj.IsUpdate = true;
            } else if (!auditList.isEmpty() && auditResponseList.isEmpty()) {
                wrapperObj.auditId = auditList[0].Id;
                wrapperObj.IsUpdate = false;
            } else {
                wrapperObj.auditId = '';
                wrapperObj.IsUpdate = false;
            }
            
            if (hasCustomEditPermission) {
                wrapperObj.IsReadOnlyUser = false;
            } else {
                wrapperObj.IsReadOnlyUser = true;
            }
            
            if (nosinglefailurevendor.contains(wo[0].Vendor__c)) {
                wrapperObj.noSingleFailure = true;
            } else {
                wrapperObj.noSingleFailure = false;
            }
            
            wrapperObj.isAvailable = getCompletedAudit(recordId);
            wrapperObj.availableForComponent = true;
            wrapperObj.status = wo[0].Status;
            wrapperObj.workTypeId = wo[0].WorkTypeId;
            AuditWrapperList.add(wrapperObj);
            
            return AuditWrapperList;
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_AuditService.class.getName(), e.getMessage());
            
            if (!Test.isRunningTest()) {
                throw new AuraHandledException(e.getMessage());
            }
            return null;
        }
    }

    // Method to insert audit
    @AuraEnabled
    public static Id insertAudit(string recordId) {
        try {
            Audit__c au = new Audit__c();
            au.Work_Order__c = recordId;
            insert au;
            return au.id;
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_AuditService.class.getName(), e.getMessage());
            
            if (!Test.isRunningTest()) {
                throw new AuraHandledException(e.getMessage());
            }
            return null;
        }
    }
    
    // Method to update audit response
    @AuraEnabled
    public static List<Audit_Response__c> handleAudit(List<Audit_Response__c> auditResponses,Boolean IsUpdate) {
        try {
            if (Test.isRunningTest() && throwException) {
                throw new CustomException();
            }

            if (IsUpdate) {
                update auditResponses;
            } else {
                insert auditResponses;
            }
            
            return auditResponses;  
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_AuditService.class.getName(), e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
       
    public class AuditWrapper {
        @AuraEnabled
        public Boolean availableForComponent;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String workTypeId;
        @AuraEnabled
        public String workType;
        @AuraEnabled
        public Boolean IsUpdate;
        @AuraEnabled
        public String auditId;
        @AuraEnabled
        public Boolean IsReadOnly;
        @AuraEnabled
        public Boolean IsReadOnlyUser;
        @AuraEnabled
        public Boolean noSingleFailure;
        @AuraEnabled
        public Boolean isAvailable;   
    }   
}