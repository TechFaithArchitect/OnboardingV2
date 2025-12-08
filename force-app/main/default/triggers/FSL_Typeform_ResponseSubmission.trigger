trigger FSL_Typeform_ResponseSubmission on Typeform_Responses__c (before insert) {
	
    FSL_TypeformTriggerHandler.assignWorkOrder(Trigger.new);
}