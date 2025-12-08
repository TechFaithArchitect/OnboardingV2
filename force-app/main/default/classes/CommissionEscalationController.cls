public with sharing class CommissionEscalationController {
    public class CommissionEscalationResult {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String caseId;
        @AuraEnabled
        public Boolean existingCaseFound;
        @AuraEnabled
        public String existingCaseId;
        @AuraEnabled
        public String existingCaseUrl;
        @AuraEnabled
        public String errorMessage;

        public CommissionEscalationResult(
            Boolean success,
            String caseId,
            Boolean existingCaseFound,
            String existingCaseId,
            String existingCaseUrl,
            String errorMessage
        ) {
            this.success = success;
            this.caseId = caseId;
            this.existingCaseFound = existingCaseFound;
            this.existingCaseId = existingCaseId;
            this.existingCaseUrl = existingCaseUrl;
            this.errorMessage = errorMessage;
        }
    }

    @AuraEnabled
    public static CommissionEscalationResult createCommissionEscalationCase(Id orderId, String description) {
        try {
            if (orderId == null) {
                return new CommissionEscalationResult(false, null, false, null, null, 'Order ID cannot be null');
            }

            // Get the order record with all necessary fields
            Order orderRecord = [
                SELECT
                    Id,
                    OrderNumber,
                    POE_OrderNumber__c,
                    POE_AccountNumber__c,
                    ActivatedDate,
                    ShippingCity,
                    ShippingState,
                    ShippingStreet,
                    ShippingPostalCode,
                    POE_Program__c,
                    POE_OrderId__c,
                    EffectiveDate,
                    Account.FirstName,
                    Account.LastName
                FROM Order
                WHERE Id = :orderId
                LIMIT 1
            ];

            if (orderRecord == null) {
                return new CommissionEscalationResult(false, null, false, null, null, 'Order not found');
            }

            // Check if a case already exists for this order (any status except Closed)
            List<Case> existingCases = [
                SELECT Id, CaseNumber, Case_URL__c, Status
                FROM Case
                WHERE Order__c = :orderId AND Status != 'Closed'
                LIMIT 1
            ];

            if (!existingCases.isEmpty()) {
                Case existingCase = existingCases[0];

                // Extract URL from Case_URL__c HTML field
                String extractedUrl = extractUrlFromHtml(existingCase.Case_URL__c);

                return new CommissionEscalationResult(false, null, true, existingCase.Id, extractedUrl, null);
            }

            User currentUser = [
                SELECT Id, ContactId, AccountId, Partner_Account_Id__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            // Get the Commissions record type
            RecordType commissionsRecordType = [
                SELECT Id
                FROM RecordType
                WHERE DeveloperName = 'Commissions' AND SObjectType = 'Case'
                LIMIT 1
            ];

            // Get order products for ProductNames
            List<OrderItem> orderItems = [SELECT Id, Product2.Name FROM OrderItem WHERE OrderId = :orderId];

            String productNames = '';
            for (OrderItem item : orderItems) {
                if (productNames != '') {
                    productNames += ', ';
                }
                productNames += item.Product2.Name;
            }

            // Get the Commission Escalation Team first (like the flow does)
            Group commissionTeam = null;
            try {
                // Look for Commission Escalation Team as Queue
                commissionTeam = [
                    SELECT Id, Type
                    FROM Group
                    WHERE DeveloperName = 'Commission_Escalation_Team'
                    LIMIT 1
                ];
            } catch (Exception e) {
                System.debug('Commission Escalation Team queue not found: ' + e.getMessage());
            }

            // Create the case with proper owner assignment
            Case newCase = new Case(
                AccountId = currentUser.AccountId,
                ContactId = currentUser.ContactId, // Current user as contact
                POE_ICLRep__c = currentUser.ContactId,
                Description = description, // Use the provided description
                Order_Number__c = orderRecord.OrderNumber,
                Order__c = orderRecord.Id,
                Origin = 'Chuzo',
                POE_Account_Number__c = orderRecord.POE_AccountNumber__c,
                POE_Activation_Date__c = orderRecord.ActivatedDate != null ? orderRecord.ActivatedDate.date() : null,
                POE_Channel__c = 'Chuzo',
                POE_City__c = orderRecord.ShippingCity,
                POE_Confirmation_Number__c = orderRecord.POE_OrderNumber__c,
                POE_Customer_FirstName__c = orderRecord.Account.FirstName,
                POE_Customer_LastName__c = orderRecord.Account.LastName,
                POE_Product_s_Sold__c = productNames,
                POE_Program__c = orderRecord.POE_Program__c,
                POE_Sales_Date__c = orderRecord.EffectiveDate,
                POE_State__c = orderRecord.ShippingState,
                POE_Street_Address__c = orderRecord.ShippingStreet,
                POE_Work_Order_Number__c = orderRecord.POE_OrderId__c,
                POE_Zip_Code__c = orderRecord.ShippingPostalCode,
                RecordTypeId = commissionsRecordType.Id,
                Status = 'New',
                Subject = 'Commission Escalations',
                Type = 'Commissions',
                OwnerId = commissionTeam != null ? commissionTeam.Id : UserInfo.getUserId()
            );

            insert newCase;

            // Get the partner group for sharing (like the flow's Get Group element)
            Group partnerGroup = null;
            try {
                if (currentUser.Partner_Account_Id__c != null) {
                    // Look for group where Name contains Partner_Account_Id__c and Type is Regular
                    partnerGroup = [
                        SELECT Id
                        FROM Group
                        WHERE Name LIKE :'%' + currentUser.Partner_Account_Id__c + '%' AND Type = 'Regular'
                        LIMIT 1
                    ];
                }
            } catch (Exception e) {
                System.debug('Partner group not found: ' + e.getMessage());
            }

            // Share the case with the partner group using CaseSharingService (like the flow does)
            if (partnerGroup != null) {
                try {
                    CaseSharingService.ShareInput shareInput = new CaseSharingService.ShareInput();
                    shareInput.recordId = newCase.Id;
                    shareInput.groupId = partnerGroup.Id;
                    shareInput.accessLevel = 'Read';

                    CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ shareInput });
                } catch (Exception e) {
                    System.debug('Error sharing case with partner group: ' + e.getMessage());
                }
            }

            // Get the newly created case with Case_URL__c field
            Case createdCase = [SELECT Id, Case_URL__c, CaseNumber, Type FROM Case WHERE Id = :newCase.Id LIMIT 1];

            // Send email notification to Commission Escalations Team
            sendCommissionEscalationNotification(createdCase);

            return new CommissionEscalationResult(true, newCase.Id, false, null, createdCase.Case_URL__c, null);
        } catch (Exception e) {
            return new CommissionEscalationResult(
                false,
                null,
                false,
                null,
                null,
                'Error creating Commission Escalation Case: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserFunctionalRole() {
        try {
            User currentUser = [
                SELECT Id, Contact.POE_Functional_Role__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];

            return currentUser.Contact?.POE_Functional_Role__c;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting user functional role: ' + e.getMessage());
        }
    }

    /**
     * Helper method to extract URL from HTML anchor tag
     * Example: <a href="https://example.com" target="_blank">Link Text</a>
     * Returns: https://example.com
     */
    private static String extractUrlFromHtml(String htmlContent) {
        if (String.isBlank(htmlContent)) {
            return '';
        }

        // First, try to decode URL encoding if present
        String decodedContent = htmlContent;
        try {
            decodedContent = EncodingUtil.urlDecode(htmlContent, 'UTF-8');
        } catch (Exception e) {
            // If decoding fails, use original content
            decodedContent = htmlContent;
        }

        // Look for href="..." pattern
        Pattern urlPattern = Pattern.compile('href="([^"]+)"');
        Matcher matcher = urlPattern.matcher(decodedContent);

        if (matcher.find()) {
            String extractedUrl = matcher.group(1);
            // Clean up any remaining HTML entities
            extractedUrl = extractedUrl.replace('&amp;', '&');
            return extractedUrl;
        }

        // If no href found, check if the content itself is a URL
        if (decodedContent.startsWith('http')) {
            return decodedContent;
        }

        // Fallback: return empty string if no valid URL found
        return '';
    }

    /**
     * Send email notification to Commission Escalations Team
     */
    private static void sendCommissionEscalationNotification(Case caseRecord) {
        try {
            // Get the email address from custom label
            String teamEmail = System.Label.CommissionEscalationsTeamEmail;

            if (String.isNotBlank(teamEmail)) {
                // Create email body with the specified template
                String emailBody = createEmailBody(caseRecord);
                String emailSubject = 'NEW CASE NOTIFICATION - Commission Escalation';

                // Send email using Messaging
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ teamEmail });
                email.setSubject(emailSubject);
                email.setHtmlBody(emailBody);
                email.setSaveAsActivity(false);
                email.setSenderDisplayName('Chuzo Commission Escalation');
                email.setReplyTo('no-reply@chuzo.com');

                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            }
        } catch (Exception e) {
            System.debug('Error sending commission escalation notification: ' + e.getMessage());
        }
    }

    /**
     * Create email body with the specified template
     */
    private static String createEmailBody(Case caseRecord) {
        // Construct Lightning CRM URL for the case
        String lightningUrl =
            System.URL.getSalesforceBaseUrl().toExternalForm().replace('.my.site.com', '.lightning.force.com') +
            '/lightning/r/Case/' +
            caseRecord.Id +
            '/view';

        String emailBody = '<html><body>';
        emailBody += '<h2>*** NEW CASE NOTIFICATION ***</h2>';
        emailBody += '<p>The following case has been created.</p>';
        emailBody += '<p><strong>Case Type:</strong> ' + (caseRecord.Type != null ? caseRecord.Type : 'N/A') + '</p>';
        emailBody +=
            '<p><strong>Case #:</strong> ' +
            (caseRecord.CaseNumber != null ? caseRecord.CaseNumber : 'N/A') +
            '</p>';
        emailBody +=
            '<p><strong>Click here to access the case:</strong> <a href="' +
            lightningUrl +
            '">' +
            caseRecord.CaseNumber +
            '</a></p>';
        emailBody += '</body></html>';

        return emailBody;
    }
}