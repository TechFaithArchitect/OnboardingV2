/**
 * Service for applying/removing external overrides on Onboarding__c.
 */
public with sharing class OnboardingExternalOverrideService {

    public class OverrideRequest {
        @AuraEnabled public Id onboardingId;
        @AuraEnabled public String reason;
        @AuraEnabled public List<String> allowedPrograms;
        @AuraEnabled public String sourceSystem;
        @AuraEnabled public String requestId;
        @AuraEnabled public Boolean resetRequirements;
    }

    public class OverrideResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id onboardingId;
        @AuraEnabled public String previousStatus;
        @AuraEnabled public String newStatus;
    }

    public static OverrideResponse applyOverride(OverrideRequest request) {
        OverrideResponse resp = new OverrideResponse();
        if (request == null || request.onboardingId == null) {
            resp.success = false;
            resp.message = 'onboardingId is required';
            return resp;
        }

        Onboarding__c ob = [
            SELECT Id, Onboarding_Status__c, External_Override_Enabled__c,
                   External_Override_Programs__c
            FROM Onboarding__c
            WHERE Id = :request.onboardingId
            LIMIT 1
        ];

        String prevStatus = ob.Onboarding_Status__c;
        ob.External_Override_Enabled__c = true;
        ob.External_Override_Reason__c = request.reason;
        ob.External_Override_Date__c = Datetime.now();
        ob.External_Override_Source__c = request.sourceSystem;
        ob.External_Override_Programs__c = request.allowedPrograms != null ? String.join(request.allowedPrograms, ',') : null;
        ob.Previous_Status_Before_Override__c = prevStatus;
        ob.External_Override_Request_ID__c = request.requestId;
        update ob;

        // Audit log
        OnboardingOverrideAuditService.AuditEntry entry = new OnboardingOverrideAuditService.AuditEntry();
        entry.onboardingId = ob.Id;
        entry.action = 'Applied';
        entry.sourceSystem = request.sourceSystem;
        entry.requestId = request.requestId;
        entry.reason = request.reason;
        entry.allowedPrograms = ob.External_Override_Programs__c;
        entry.previousStatus = prevStatus;
        entry.newStatus = ob.Onboarding_Status__c;
        entry.requestedBy = UserInfo.getName();
        entry.processedBy = UserInfo.getUserId();
        entry.processedDate = Datetime.now();
        OnboardingOverrideAuditService.log(entry);

        resp.success = true;
        resp.message = 'Override applied';
        resp.onboardingId = ob.Id;
        resp.previousStatus = prevStatus;
        resp.newStatus = ob.Onboarding_Status__c;
        return resp;
    }

    public static OverrideResponse removeOverride(Id onboardingId, String reason) {
        OverrideResponse resp = new OverrideResponse();
        if (onboardingId == null) {
            resp.success = false;
            resp.message = 'onboardingId is required';
            return resp;
        }
        Onboarding__c ob = [
            SELECT Id, Onboarding_Status__c, External_Override_Enabled__c,
                   Previous_Status_Before_Override__c
            FROM Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];

        String prevStatus = ob.Onboarding_Status__c;
        ob.External_Override_Enabled__c = false;
        ob.External_Override_Reason__c = reason;
        ob.External_Override_Date__c = Datetime.now();
        ob.External_Override_Source__c = null;
        ob.External_Override_Programs__c = null;
        ob.External_Override_Request_ID__c = null;
        ob.Onboarding_Status__c = ob.Previous_Status_Before_Override__c;
        update ob;

        // Audit log
        OnboardingOverrideAuditService.AuditEntry entry = new OnboardingOverrideAuditService.AuditEntry();
        entry.onboardingId = ob.Id;
        entry.action = 'Removed';
        entry.sourceSystem = null;
        entry.requestId = null;
        entry.reason = reason;
        entry.allowedPrograms = null;
        entry.previousStatus = prevStatus;
        entry.newStatus = ob.Onboarding_Status__c;
        entry.requestedBy = UserInfo.getName();
        entry.processedBy = UserInfo.getUserId();
        entry.processedDate = Datetime.now();
        OnboardingOverrideAuditService.log(entry);

        resp.success = true;
        resp.message = 'Override removed';
        resp.onboardingId = ob.Id;
        resp.previousStatus = prevStatus;
        resp.newStatus = ob.Onboarding_Status__c;
        return resp;
    }

    public static Boolean isProgramAllowed(Id onboardingId, String programName) {
        if (onboardingId == null || String.isBlank(programName)) {
            return false;
        }
        List<Onboarding__c> obs = [
            SELECT External_Override_Enabled__c, External_Override_Programs__c
            FROM Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];
        if (obs.isEmpty()) {
            return false;
        }
        Onboarding__c ob = obs[0];
        if (ob.External_Override_Enabled__c != true) {
            return true; // no override restriction
        }
        if (String.isBlank(ob.External_Override_Programs__c)) {
            return true; // override enabled but no restriction specified
        }
        Set<String> allowed = new Set<String>();
        for (String p : ob.External_Override_Programs__c.split(',')) {
            if (!String.isBlank(p)) {
                allowed.add(p.trim().toLowerCase());
            }
        }
        return allowed.isEmpty() ? true : allowed.contains(programName.toLowerCase());
    }
}