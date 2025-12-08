public with sharing class EmailCommSendAction {

   // Request: Flow-facing input DTO
   
    public class Request {
        // Recipients
        @InvocableVariable(label='[Recipients] To Address') 
        public String toAddress;

        @InvocableVariable(label='[Recipients] To Address List') 
        public List<String> toAddressList;

        @InvocableVariable(label='[Recipients] CC Email Address' required=false) 
        public List<String> ccEmailAddresses;

        @InvocableVariable(label='[Recipients] BCC Email Address' required=false) 
        public List<String> bccEmailAddresses;

        @InvocableVariable(label='[Recipients] Recipient ID (for templates)') 
        public Id recipientId;

        // Content
        @InvocableVariable(label='[Content] Email Template ID') 
        public String emailTemplateId;

        @InvocableVariable(label='[Content] Subject') 
        public String subject;

        @InvocableVariable(label='[Content] HTML Body') 
        public String htmlBody;

        @InvocableVariable(label='[Content] Text Body') 
        public String textBody;

        @InvocableVariable(label='[Content] Related Record ID (WhatId)') 
        public Id relatedRecordId;

        @InvocableVariable(label='[Content] Attachment IDs (Attachment or ContentDocument)') 
        public List<Id> attachmentIds;

        // Sender
        @InvocableVariable(label='[Sender] Sender Type (Manual | OrgWide | CurrentUser)') 
        public String senderType;

        @InvocableVariable(label='[Sender] Org-Wide Email Address ID') 
        public Id orgWideEmailAddressId;

        // Context
        @InvocableVariable(label='[Context] Contact ID') 
        public Id contactId;

        @InvocableVariable(label='[Context] Onboarding ID') 
        public Id onboardingId;

        @InvocableVariable(label='[Context] Account ID') 
        public Id accountId;

        @InvocableVariable(label='[Context] Communication Template Record ID') 
        public Id communicationTemplateId;

        // Logging
        @InvocableVariable(label='[Logging] Log Synchronously?') 
        public Boolean logSync = false;
    }

    // Result: Flow-facing output DTO
    
    public class Result {
        @InvocableVariable(label='Status') 
        public String status;

        @InvocableVariable(label='Error Message') 
        public String errorMessage;

        @InvocableVariable(label='Email Message ID') 
        public Id emailMessageId;

        public Result(String status, String errorMessage, Id emailMessageId) {
            this.status = status;
            this.errorMessage = errorMessage;
            this.emailMessageId = emailMessageId;
        }
    }

    // Invocable Method: 1:1 or bulk send
    
    @InvocableMethod(label='Send Email and Log Communication')
    public static List<Result> send(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request emailCommSendRequest : requests) {
            EmailCommSendRequestDTO emailCommSendRequestDTO = new EmailCommSendRequestDTO();

            // --- Recipients ---
            emailCommSendRequestDTO.toAddress          = emailCommSendRequest.toAddress;
            emailCommSendRequestDTO.toAddressList      = emailCommSendRequest.toAddressList;
            emailCommSendRequestDTO.ccAddressList      = emailCommSendRequest.ccEmailAddresses;
            emailCommSendRequestDTO.bccAddressList     = emailCommSendRequest.bccEmailAddresses;
            emailCommSendRequestDTO.recipientId        = emailCommSendRequest.recipientId;

            // --- Content ---
            emailCommSendRequestDTO.emailTemplateId    = emailCommSendRequest.emailTemplateId;
            emailCommSendRequestDTO.subject            = emailCommSendRequest.subject;
            emailCommSendRequestDTO.htmlBody           = emailCommSendRequest.htmlBody;
            emailCommSendRequestDTO.textBody           = emailCommSendRequest.textBody;
            emailCommSendRequestDTO.relatedRecordId    = emailCommSendRequest.relatedRecordId;
            emailCommSendRequestDTO.attachmentIds      = emailCommSendRequest.attachmentIds;

            // --- Sender ---
            emailCommSendRequestDTO.senderType             = emailCommSendRequest.senderType;
            emailCommSendRequestDTO.orgWideEmailAddressId = emailCommSendRequest.orgWideEmailAddressId;

            // --- Context ---
            emailCommSendRequestDTO.contactId              = emailCommSendRequest.contactId;
            emailCommSendRequestDTO.onboardingId           = emailCommSendRequest.onboardingId;
            emailCommSendRequestDTO.accountId              = emailCommSendRequest.accountId;
            emailCommSendRequestDTO.communicationTemplateId = emailCommSendRequest.communicationTemplateId;

            // --- Logging ---
            emailCommSendRequestDTO.logSync = emailCommSendRequest.logSync;

            // --- Orchestrate ---
            EmailCommSendResultDTO result = EmailSendAndLogOrchestrator.orchestrateSendAndLog(emailCommSendRequestDTO);
            results.add(new Result(result.status, result.errorMessage, result.emailMessageId));
        }

        return results;
    }
}
