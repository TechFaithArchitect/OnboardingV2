/**
 * Invocable action for Flow/LWC to validate Requirement_Field_Value__c records.
 * Runs synchronous validation and returns statuses/messages.
 */
public with sharing class RequirementFieldValidationAction {

    public class Request {
        @InvocableVariable(required=true)
        public Id requirementFieldValueId;
    }

    public class Response {
        @InvocableVariable public Id requirementFieldValueId;
        @InvocableVariable public String status;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Validate Requirement Field Values' description='Runs validation on Requirement_Field_Value__c records and returns status/message.')
    public static List<Response> validate(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Set<Id> ids = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.requirementFieldValueId != null) {
                ids.add(req.requirementFieldValueId);
            }
        }
        if (ids.isEmpty()) {
            return responses;
        }

        List<RequirementFieldValidationService.ValidationResult> results =
            RequirementFieldValidationService.validateAndUpdate(ids);

        for (RequirementFieldValidationService.ValidationResult r : results) {
            Response res = new Response();
            res.requirementFieldValueId = r.fieldValueId;
            res.status = r.status;
            res.message = r.message;
            responses.add(res);
        }
        return responses;
    }
}