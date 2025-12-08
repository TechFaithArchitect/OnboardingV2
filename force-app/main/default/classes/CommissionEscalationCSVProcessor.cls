public without sharing class CommissionEscalationCSVProcessor {
    public class CSVRow {
        @InvocableVariable(required=true)
        public String confirmationNumber;

        @InvocableVariable(required=true)
        public String program;

        @InvocableVariable(required=true)
        public String customerFirstName;

        @InvocableVariable(required=true)
        public String customerLastName;

        @InvocableVariable(required=true)
        public String zipCode;

        @InvocableVariable(required=true)
        public Date salesDate;

        @InvocableVariable(required=true)
        public String product;

        @InvocableVariable(required=true)
        public String customerAddress;

        @InvocableVariable(required=true)
        public String customerCity;

        @InvocableVariable(required=true)
        public String customerState;

        @InvocableVariable(required=true)
        public String description;

        @InvocableVariable
        public String accountNumber;

        @InvocableVariable
        public String workOrderNumber;

        @InvocableVariable(required=false)
        public String partnerSalesCode;

        @InvocableVariable
        public Date activationDate;

        @InvocableVariable
        public String customerMobilityPhone;

        @InvocableVariable(required=false)
        public String channel;

        // Store original date strings for validation
        public String originalSalesDate;
        public String originalActivationDate;
    }

    public class ProcessingResult {
        @InvocableVariable
        public String parentCaseId;

        @InvocableVariable
        public String parentCaseNumber;

        @InvocableVariable
        public String parentCaseURL;

        @InvocableVariable
        public Integer totalRows;

        @InvocableVariable
        public Integer successfulCases;

        @InvocableVariable
        public Integer failedCases;

        @InvocableVariable
        public String errorMessages;

        @InvocableVariable
        public String successMessage;
    }

    // Cache for picklist values
    private static Map<String, String> PROGRAM_MAPPING;
    private static Set<String> VALID_CHANNELS;
    private static Set<String> VALID_STATES;

    /**
     * Validates required fields and returns specific error messages for missing fields
     * @param row The CSV row to validate
     * @return List of specific error messages for missing fields
     */
    private static List<String> validateRequiredFields(CSVRow row) {
        List<String> missingFields = new List<String>();

        // Check required fields based on @InvocableVariable(required=true)
        if (String.isBlank(row.confirmationNumber)) {
            missingFields.add('Confirmation Number');
        }
        if (String.isBlank(row.program)) {
            missingFields.add('Program');
        }
        if (String.isBlank(row.customerFirstName)) {
            missingFields.add('Customer First Name');
        }
        if (String.isBlank(row.customerLastName)) {
            missingFields.add('Customer Last Name');
        }
        if (String.isBlank(row.zipCode)) {
            missingFields.add('Customer Zip Code');
        }
        if (row.salesDate == null) {
            missingFields.add('Sales Date');
        }
        if (String.isBlank(row.product)) {
            missingFields.add('Product');
        }
        if (String.isBlank(row.customerAddress)) {
            missingFields.add('Customer Address');
        }
        if (String.isBlank(row.customerCity)) {
            missingFields.add('Customer City');
        }
        if (String.isBlank(row.customerState)) {
            missingFields.add('Customer State');
        }
        if (String.isBlank(row.description)) {
            missingFields.add('Description');
        }

        return missingFields;
    }

    // Initialize picklist values from Case object
    private static void initializePicklistValues() {
        if (PROGRAM_MAPPING == null) {
            PROGRAM_MAPPING = new Map<String, String>();
            VALID_CHANNELS = new Set<String>();
            VALID_STATES = new Set<String>();

            // Get POE_Program__c picklist values
            Schema.DescribeFieldResult programField = Case.POE_Program__c.getDescribe();
            List<Schema.PicklistEntry> programEntries = programField.getPicklistValues();

            // First, add all picklist values as direct mappings (key = value)
            for (Schema.PicklistEntry entry : programEntries) {
                if (entry.isActive()) {
                    PROGRAM_MAPPING.put(entry.getValue(), entry.getValue());
                }
            }

            // Then add special mappings where key != value (from old hardcoded logic)
            Map<String, String> specialMappings = new Map<String, String>{
                'DIRECTV' => 'DirecTV',
                'Optimum' => 'Altice',
                'Spectrum Residential' => 'Charter/Spectrum'
            };

            // Only add special mappings if the target value exists in picklist
            for (String key : specialMappings.keySet()) {
                String targetValue = specialMappings.get(key);
                if (PROGRAM_MAPPING.containsKey(targetValue)) {
                    PROGRAM_MAPPING.put(key, targetValue);
                }
            }

            // Handle case sensitivity for common variations
            if (PROGRAM_MAPPING.containsKey('Earthlink')) {
                PROGRAM_MAPPING.put('EarthLink', 'Earthlink');
            }

            // Get POE_Channel__c picklist values
            VALID_CHANNELS = new Set<String>{
                'D2D/F2F/Events',
                'National Agent',
                'National Retail',
                'Chuzo',
                'Call-In Order'
            };

            // Get POE_State__c picklist values
            Schema.DescribeFieldResult stateField = Case.POE_State__c.getDescribe();
            List<Schema.PicklistEntry> stateEntries = stateField.getPicklistValues();
            for (Schema.PicklistEntry entry : stateEntries) {
                if (entry.isActive()) {
                    VALID_STATES.add(entry.getValue());
                }
            }
        }
    }

    private static String validateAndTransformProgram(String program) {
        initializePicklistValues();

        if (String.isBlank(program)) {
            throw new CSVProcessingException('Program is required and cannot be blank.');
        }

        String normalizedProgram = program.trim();
        if (!PROGRAM_MAPPING.containsKey(normalizedProgram)) {
            throw new CSVProcessingException(
                'Invalid program value: "' +
                normalizedProgram +
                '". Valid values are: ' +
                String.join(new List<String>(PROGRAM_MAPPING.keySet()), ', ')
            );
        }

        return PROGRAM_MAPPING.get(normalizedProgram);
    }

    private static String validateChannel(String channel) {
        initializePicklistValues();

        if (String.isBlank(channel)) {
            return 'Chuzo'; // Default to 'Chuzo' when channel is empty
        }

        String normalizedChannel = channel.trim();

        // Map CSV input values to API field values
        Map<String, String> channelMapping = new Map<String, String>{
            'Call-In Order' => 'Call-In',
            'D2D/F2F/Events' => 'Door-to-Door',
            'National Agent' => 'National Agent',
            'National Retail' => 'National Retail',
            'Chuzo' => 'Chuzo'
        };

        if (channelMapping.containsKey(normalizedChannel)) {
            return channelMapping.get(normalizedChannel); // Return the API value
        }

        throw new CSVProcessingException(
            'Invalid channel value: "' +
            normalizedChannel +
            '". Valid values are: D2D/F2F/Events, National Agent, National Retail, Chuzo, Call-In Order'
        );
    }

    private static String validateState(String state) {
        initializePicklistValues();

        if (String.isBlank(state)) {
            throw new CSVProcessingException('State is required and cannot be blank.');
        }

        String normalizedState = state.trim();

        // Check if the state is valid
        if (VALID_STATES.contains(normalizedState)) {
            return normalizedState;
        }

        // If we get here, the state is invalid
        throw new CSVProcessingException(
            'Invalid state value: "' +
            normalizedState +
            '". Valid values are: ' +
            String.join(new List<String>(VALID_STATES), ', ')
        );
    }

    public class CSVProcessingException extends Exception {
    }

    /**
     * Share case with partner group using CaseSharingService
     */
    private static void shareCaseWithPartnerGroup(Id caseId, Id partnerGroupId) {
        if (partnerGroupId == null) {
            return;
        }

        try {
            // Share the case with the partner group
            CaseSharingService.ShareInput shareInput = new CaseSharingService.ShareInput();
            shareInput.recordId = caseId;
            shareInput.groupId = partnerGroupId;
            shareInput.accessLevel = 'Edit';

            CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ shareInput });
        } catch (Exception e) {
            System.debug('Error sharing case with partner group: ' + e.getMessage());
        }
    }

    /**
     * Share multiple cases with partner group using CaseSharingService in bulk
     */
    private static void bulkShareCasesWithPartnerGroup(List<Id> caseIds, Id partnerGroupId) {
        if (partnerGroupId == null || caseIds == null || caseIds.isEmpty()) {
            return;
        }

        try {
            List<CaseSharingService.ShareInput> shareInputs = new List<CaseSharingService.ShareInput>();
            for (Id caseId : caseIds) {
                CaseSharingService.ShareInput shareInput = new CaseSharingService.ShareInput();
                shareInput.recordId = caseId;
                shareInput.groupId = partnerGroupId;
                shareInput.accessLevel = 'Edit';
                shareInputs.add(shareInput);
            }

            if (!shareInputs.isEmpty()) {
                CaseSharingService.shareCaseWithGroup(shareInputs);
            }
        } catch (Exception e) {
            System.debug('Error during bulk sharing: ' + e.getMessage());
            throw e; // Re-throw to be handled by caller
        }
    }

    @InvocableMethod(
        label='Process Commission Escalation CSV'
        description='Process CSV file for multiple commission escalation cases'
    )
    public static List<ProcessingResult> processCSV(List<String> csvContent) {
        ProcessingResult result = new ProcessingResult();
        result.totalRows = 0;
        result.successfulCases = 0;
        result.failedCases = 0;
        result.errorMessages = '';
        result.successMessage = '';

        try {
            // CSV content received from Flow via LWC

            // Get current user information
            User currentUser = [
                SELECT Id, ContactId, AccountId, Partner_Account_Id__c, Contact.Email
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

            // Get the Commission Escalation Team
            Group commissionTeam = [SELECT Id FROM Group WHERE DeveloperName = 'Commission_Escalation_Team' LIMIT 1];

            // Get the partner group for sharing cases
            Group partnerGroup = null;
            if (String.isNotBlank(currentUser.Partner_Account_Id__c)) {
                try {
                    partnerGroup = [
                        SELECT Id
                        FROM Group
                        WHERE Name LIKE :'%' + currentUser.Partner_Account_Id__c + '%' AND Type = 'Regular'
                        LIMIT 1
                    ];
                } catch (Exception e) {
                    System.debug('Could not find partner group for account: ' + currentUser.Partner_Account_Id__c);
                }
            }

            // Extract actual CSV content from the file upload data
            String actualCSVContent = extractCSVContent(csvContent[0]);

            if (String.isBlank(actualCSVContent)) {
                result.errorMessages = 'Could not extract CSV content from uploaded file. Please try again.';
                return new List<ProcessingResult>{ result };
            }

            // Parse CSV content
            List<CSVRow> csvRows = parseCSV(actualCSVContent);
            result.totalRows = csvRows.size();

            // First, validate all rows and prepare cases to insert
            List<Case> casesToInsert = new List<Case>();
            List<String> errors = new List<String>();
            Integer successfulCases = 0;
            Integer failedCases = 0;

            // Collect all confirmation numbers to bulk query orders
            Set<String> confirmationNumbers = new Set<String>();
            for (CSVRow row : csvRows) {
                if (String.isNotBlank(row.confirmationNumber)) {
                    confirmationNumbers.add(row.confirmationNumber);
                }
            }

            // Bulk query all orders for all confirmation numbers
            Map<String, Order> ordersByConfirmationNumber = new Map<String, Order>();
            if (!confirmationNumbers.isEmpty() && String.isNotBlank(currentUser.Partner_Account_Id__c)) {
                List<Order> allOrders = [
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
                        AccountId,
                        Account.FirstName,
                        Account.LastName
                    FROM Order
                    WHERE
                        POE_OrderNumber__c IN :confirmationNumbers
                        AND POE_Dealer__c = :currentUser.Partner_Account_Id__c
                ];

                for (Order order : allOrders) {
                    ordersByConfirmationNumber.put(order.POE_OrderNumber__c, order);
                }
            }

            // Bulk query all existing cases for all orders to check for duplicates
            Set<Id> orderIds = new Set<Id>();
            for (Order order : ordersByConfirmationNumber.values()) {
                orderIds.add(order.Id);
            }

            Map<Id, Case> existingCasesByOrderId = new Map<Id, Case>();
            if (!orderIds.isEmpty()) {
                List<Case> allExistingCases = [
                    SELECT Id, CaseNumber, Case_URL__c, Status, Order__c
                    FROM Case
                    WHERE Order__c IN :orderIds AND Status != 'Closed'
                ];

                for (Case existingCase : allExistingCases) {
                    existingCasesByOrderId.put(existingCase.Order__c, existingCase);
                }
            }

            // Bulk query all order items for all orders
            Map<Id, List<OrderItem>> orderItemsByOrderId = new Map<Id, List<OrderItem>>();
            if (!orderIds.isEmpty()) {
                List<OrderItem> allOrderItems = [
                    SELECT Id, OrderId, Product2.Name
                    FROM OrderItem
                    WHERE OrderId IN :orderIds
                ];

                for (OrderItem item : allOrderItems) {
                    if (!orderItemsByOrderId.containsKey(item.OrderId)) {
                        orderItemsByOrderId.put(item.OrderId, new List<OrderItem>());
                    }
                    orderItemsByOrderId.get(item.OrderId).add(item);
                }
            }

            for (Integer i = 0; i < csvRows.size(); i++) {
                CSVRow row = csvRows[i];
                Integer rowNumber = i + 2; // +2 because CSV has header and we're 0-indexed
                Boolean rowProcessed = false;

                try {
                    // Check if this is an error row from date parsing
                    if (row.program == 'ERROR') {
                        errors.add(row.description);
                        failedCases++;
                        continue;
                    }

                    // Validate date formats FIRST (before required fields)
                    List<String> dateErrors = validateDateFormats(row);
                    if (!dateErrors.isEmpty()) {
                        errors.add('Row ' + rowNumber + ': ' + String.join(dateErrors, ', '));
                        failedCases++;
                        continue;
                    }

                    // Validate required fields based on CSV template
                    List<String> missingFields = validateRequiredFields(row);
                    if (!missingFields.isEmpty()) {
                        errors.add(
                            'Row ' +
                            rowNumber +
                            ': Missing required fields: ' +
                            String.join(missingFields, ', ')
                        );
                        failedCases++;
                        continue;
                    }

                    // Validate and transform program and channel values
                    try {
                        row.program = validateAndTransformProgram(row.program);
                        row.channel = validateChannel(row.channel);
                        row.customerState = validateState(row.customerState);
                    } catch (CSVProcessingException e) {
                        errors.add('Row ' + rowNumber + ': ' + e.getMessage());
                        failedCases++;
                        continue;
                    }

                    // Check if order exists using the bulk query results
                    Order existingOrder = ordersByConfirmationNumber.get(row.confirmationNumber);

                    Case newCase;

                    if (existingOrder != null) {
                        // Check if there's already an open case for this order using the bulk query results
                        Case existingCase = existingCasesByOrderId.get(existingOrder.Id);

                        if (existingCase != null) {
                            errors.add(
                                'Row ' +
                                rowNumber +
                                ': An open case already exists for this order. Case #: ' +
                                existingCase.CaseNumber +
                                ' - ' +
                                existingCase.Case_URL__c
                            );
                            failedCases++;
                            continue;
                        }

                        // Create case based on existing order
                        newCase = createCaseFromOrder(
                            existingOrder,
                            null, // Will set parent ID later
                            currentUser,
                            commissionsRecordType.Id,
                            commissionTeam.Id,
                            row,
                            orderItemsByOrderId.get(existingOrder.Id)
                        );
                    } else {
                        // Create manual case
                        newCase = createManualCase(
                            row,
                            null, // Will set parent ID later
                            currentUser,
                            commissionsRecordType.Id,
                            commissionTeam.Id
                        );
                    }

                    casesToInsert.add(newCase);
                    successfulCases++;
                } catch (Exception e) {
                    errors.add('Row ' + rowNumber + ': ' + e.getMessage());
                    failedCases++;
                }
            }

            // Only create parent case if we have successful cases to process
            Case parentCase = null;
            if (successfulCases > 0) {
                // Create Parent Case
                parentCase = new Case(
                    AccountId = currentUser.AccountId,
                    ContactId = currentUser.ContactId,
                    POE_ICLRep__c = currentUser.ContactId,
                    Origin = 'Chuzo',
                    POE_Channel__c = 'Chuzo',
                    RecordTypeId = commissionsRecordType.Id,
                    OwnerId = commissionTeam.Id,
                    Status = 'New',
                    Subject = 'Commission Escalations - Multiple Orders',
                    Type = 'Commissions',
                    Description = 'Parent commission escalation cases created from CSV upload'
                );

                insert parentCase;
                result.parentCaseId = parentCase.Id;

                // Get the parent case details for URL and case number
                Case parentCaseDetails = [
                    SELECT Id, CaseNumber, Case_URL__c
                    FROM Case
                    WHERE Id = :parentCase.Id
                    LIMIT 1
                ];
                result.parentCaseNumber = parentCaseDetails.CaseNumber;
                result.parentCaseURL = parentCaseDetails.Case_URL__c;

                // Attach the CSV file to the parent case
                try {
                    if (String.isNotBlank(actualCSVContent)) {
                        // Get the POE network ID
                        String poeNetworkId = null;
                        List<Network> networks = [SELECT Id, Name FROM Network WHERE Name = 'POE' LIMIT 1];
                        if (!networks.isEmpty()) {
                            poeNetworkId = networks[0].Id;
                        }

                        // Create ContentVersion with POE network
                        ContentVersion csvAttachment = new ContentVersion(
                            Title = 'Commission_Escalations_CSV_' +
                                Datetime.now().format('yyyy-MM-dd_HH-mm-ss') +
                                '.csv',
                            PathOnClient = 'Commission_Escalations_CSV.csv',
                            VersionData = Blob.valueOf(actualCSVContent),
                            IsMajorVersion = true,
                            NetworkId = poeNetworkId
                        );
                        insert csvAttachment;

                        // Get the ContentDocument ID and create link to parent case
                        ContentVersion insertedCV = [
                            SELECT ContentDocumentId
                            FROM ContentVersion
                            WHERE Id = :csvAttachment.Id
                            LIMIT 1
                        ];

                        ContentDocumentLink cdl = new ContentDocumentLink(
                            LinkedEntityId = parentCase.Id,
                            ContentDocumentId = insertedCV.ContentDocumentId,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        );
                        insert cdl;
                    }
                } catch (Exception e) {
                    // Log the error but don't fail the entire process
                    System.debug('Error attaching CSV to parent case: ' + e.getMessage());
                }

                // Only process child cases if we have any to insert
                if (!casesToInsert.isEmpty()) {
                    // Update all child cases with the parent case ID
                    for (Case childCase : casesToInsert) {
                        childCase.ParentId = parentCase.Id;
                    }

                    // Insert child cases in smaller batches to avoid hitting SOQL limits from triggers/validation rules
                    Integer batchSize = 50; // Smaller batch size to avoid SOQL limits

                    // Dynamically adjust batch size based on current SOQL usage
                    if (Limits.getQueries() > 70) {
                        batchSize = 25; // Reduce batch size if we're using a lot of SOQL queries
                    } else if (Limits.getQueries() > 50) {
                        batchSize = 35; // Moderate batch size
                    }

                    Integer totalBatches = Integer.valueOf(Math.ceil(casesToInsert.size() / (Decimal) batchSize));

                    // Collect all successful case IDs for bulk sharing
                    List<Id> successfulCaseIds = new List<Id>();

                    for (Integer batchNum = 0; batchNum < totalBatches; batchNum++) {
                        Integer startIndex = batchNum * batchSize;
                        Integer endIndex = Math.min(startIndex + batchSize - 1, casesToInsert.size() - 1);

                        List<Case> currentBatch = new List<Case>();
                        for (Integer i = startIndex; i <= endIndex; i++) {
                            currentBatch.add(casesToInsert[i]);
                        }

                        // Insert current batch
                        Database.SaveResult[] results = Database.insert(currentBatch, false);

                        // Process results and handle any failures
                        for (Integer j = 0; j < results.size(); j++) {
                            Database.SaveResult sr = results[j];
                            if (sr.isSuccess()) {
                                // Success - collect case ID for bulk sharing
                                successfulCaseIds.add(sr.getId());
                            } else {
                                // Individual case failed - log the error but continue processing
                                String errorMsg = 'Row ' + (startIndex + j + 2) + ': Failed to create case: ';
                                for (Database.Error error : sr.getErrors()) {
                                    errorMsg += error.getMessage() + '; ';
                                }
                                errors.add(errorMsg);
                                failedCases++;
                                successfulCases--; // Decrement since we counted this as successful earlier
                            }
                        }

                        // Clear the batch to free memory
                        currentBatch.clear();
                    }

                    // Perform bulk sharing for all successful cases
                    if (!successfulCaseIds.isEmpty() && partnerGroup != null) {
                        try {
                            bulkShareCasesWithPartnerGroup(successfulCaseIds, partnerGroup.Id);
                        } catch (Exception e) {
                            System.debug('Error during bulk sharing: ' + e.getMessage());
                            // Add to errors but don't fail the entire process
                            errors.add('Warning: Some cases could not be shared with partner group: ' + e.getMessage());
                        }
                    }
                    // Share parent case with partner group
                    shareCaseWithPartnerGroup(parentCase.Id, partnerGroup != null ? partnerGroup.Id : null);
                }
            }

            // Set final results
            result.successfulCases = successfulCases;
            result.failedCases = failedCases;

            // Compile error messages
            if (!errors.isEmpty()) {
                result.errorMessages = String.join(errors, '\n');
            }

            // Create success message
            if (successfulCases > 0) {
                result.successMessage =
                    'Successfully processed ' +
                    successfulCases +
                    ' out of ' +
                    result.totalRows +
                    ' rows.';
                if (failedCases > 0) {
                    result.successMessage += ' ' + failedCases + ' rows failed.';
                }
            } else {
                result.successMessage = 'No valid cases could be created from the CSV file.';
            }
        } catch (Exception e) {
            result.errorMessages = 'Error processing CSV: ' + e.getMessage();
            result.failedCases = result.totalRows;
        }

        return new List<ProcessingResult>{ result };
    }

    private static String extractCSVContent(String flowFileData) {
        try {
            // For now, let's try a different approach - use the raw CSV content directly
            // The Flow file upload component might be passing the content differently
            // flowFileData can be raw CSV content or legacy metadata string

            // Check if the flowFileData is actually CSV content (not metadata)
            if (flowFileData.contains('Program,Customer First Name') || flowFileData.contains('\n')) {
                return flowFileData;
            }

            // Parse the JSON-like structure to get contentVersionId and contentDocId
            String contentVersionId = null;
            String contentDocId = null;

            // Look for contentVersionIds pattern
            Pattern p1 = Pattern.compile('contentVersionIds=\\[([^\\]]+)\\]');
            Matcher m1 = p1.matcher(flowFileData);

            if (m1.find()) {
                contentVersionId = m1.group(1);
            }

            // Look for contentDocIds pattern
            Pattern p2 = Pattern.compile('contentDocIds=\\[([^\\]]+)\\]');
            Matcher m2 = p2.matcher(flowFileData);

            if (m2.find()) {
                contentDocId = m2.group(1);
            }

            if (String.isBlank(contentVersionId) && String.isBlank(contentDocId)) {
                return null;
            }

            // Try to get the ContentVersion record with different approaches
            List<ContentVersion> cvList = new List<ContentVersion>();

            // Try direct ContentVersion query
            if (String.isNotBlank(contentVersionId)) {
                try {
                    cvList = [SELECT Id, VersionData, Title FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
                } catch (Exception e) {
                }
            }

            // Try ContentDocument approach
            if (cvList.isEmpty() && String.isNotBlank(contentDocId)) {
                try {
                    cvList = [
                        SELECT Id, VersionData, Title
                        FROM ContentVersion
                        WHERE ContentDocumentId = :contentDocId AND IsLatest = TRUE
                        LIMIT 1
                    ];
                } catch (Exception e) {
                }
            }

            // Try without IsLatest filter
            if (cvList.isEmpty() && String.isNotBlank(contentDocId)) {
                try {
                    cvList = [
                        SELECT Id, VersionData, Title
                        FROM ContentVersion
                        WHERE ContentDocumentId = :contentDocId
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                } catch (Exception e) {
                }
            }

            // Try using ContentDocument directly
            if (cvList.isEmpty() && String.isNotBlank(contentDocId)) {
                try {
                    // Try to get the ContentDocument and then the latest version
                    List<ContentDocument> docs = [
                        SELECT Id, Title
                        FROM ContentDocument
                        WHERE Id = :contentDocId
                        LIMIT 1
                    ];

                    if (!docs.isEmpty()) {
                        // Try to get the latest version of this document
                        cvList = [
                            SELECT Id, VersionData, Title
                            FROM ContentVersion
                            WHERE ContentDocumentId = :contentDocId
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                        ];
                    }
                } catch (Exception e) {
                }
            }

            if (!cvList.isEmpty()) {
                ContentVersion cv = cvList[0];

                if (cv.VersionData != null) {
                    String csvContent = cv.VersionData.toString();
                    return csvContent;
                }
            } else {
                // No ContentVersion found with any approach
            }

            return null;
        } catch (Exception e) {
            System.debug('Error extracting CSV content: ' + e.getMessage());
            return null;
        }
    }

    private static List<CSVRow> parseCSV(String csvContent) {
        List<CSVRow> rows = new List<CSVRow>();

        // First, normalize the CSV content to handle multi-line quoted fields
        String normalizedContent = normalizeCSVContent(csvContent);
        List<String> lines = normalizedContent.split('\n');

        // Skip header row
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i].trim();
            if (String.isNotBlank(line)) {
                CSVRow row = parseCSVRow(line);
                if (row != null) {
                    rows.add(row);
                }
            }
        }

        return rows;
    }

    private static String normalizeCSVContent(String csvContent) {
        // Handle multi-line quoted fields by replacing newlines within quotes with a placeholder
        String normalized = '';
        Boolean inQuotes = false;

        for (Integer i = 0; i < csvContent.length(); i++) {
            String currentChar = csvContent.substring(i, i + 1);

            if (currentChar == '"') {
                inQuotes = !inQuotes;
                normalized += currentChar;
            } else if (currentChar == '\n' && inQuotes) {
                // Replace newlines within quotes with a space
                normalized += ' ';
            } else {
                normalized += currentChar;
            }
        }

        return normalized;
    }

    private static String mapOrderProgramToCaseProgram(String orderProgram) {
        if (String.isBlank(orderProgram)) {
            return orderProgram;
        }

        // Map order program values to case program values
        Map<String, String> orderToCaseProgramMapping = new Map<String, String>{ 'DIRECTV(ENGA)' => 'DirecTV' };

        String normalizedProgram = orderProgram.trim();
        if (orderToCaseProgramMapping.containsKey(normalizedProgram)) {
            return orderToCaseProgramMapping.get(normalizedProgram);
        }

        return normalizedProgram; // Return original if no mapping found
    }

    private static CSVRow parseCSVRow(String line) {
        // Enhanced CSV parsing - split by comma and handle quoted fields properly
        List<String> fields = new List<String>();
        Boolean inQuotes = false;
        String currentField = '';

        for (Integer i = 0; i < line.length(); i++) {
            String currentChar = line.substring(i, i + 1);

            if (currentChar == '"') {
                inQuotes = !inQuotes;
            } else if (currentChar == ',' && !inQuotes) {
                fields.add(currentField.trim());
                currentField = '';
            } else {
                currentField += currentChar;
            }
        }

        fields.add(currentField.trim()); // Add last field

        // Create CSVRow with whatever fields we have - let validation handle missing fields
        CSVRow row = new CSVRow();

        // Safely assign fields, using empty string if field doesn't exist
        row.program = fields.size() > 0 ? fields[0] : '';
        row.customerFirstName = fields.size() > 1 ? fields[1] : '';
        row.customerLastName = fields.size() > 2 ? fields[2] : '';
        row.partnerSalesCode = fields.size() > 3 ? fields[3] : '';
        row.accountNumber = fields.size() > 4 ? fields[4] : '';
        row.confirmationNumber = fields.size() > 5 ? fields[5] : '';
        row.workOrderNumber = fields.size() > 6 ? fields[6] : '';

        // Parse dates with error handling
        try {
            row.originalSalesDate = fields.size() > 7 ? fields[7] : '';
            row.originalActivationDate = fields.size() > 8 ? fields[8] : '';
            row.salesDate = fields.size() > 7 ? parseDate(fields[7]) : null;
            row.activationDate = fields.size() > 8 ? parseDate(fields[8]) : null;
        } catch (CSVProcessingException e) {
            // Don't throw here - let the main validation handle it
            row.salesDate = null;
            row.activationDate = null;
        }

        row.product = fields.size() > 9 ? fields[9] : '';
        row.customerMobilityPhone = fields.size() > 10 ? fields[10] : '';
        row.channel = fields.size() > 11 ? fields[11] : '';
        row.customerAddress = fields.size() > 13 ? fields[13] : ''; // PV Dealer Code is at index 12, skip it
        row.customerCity = fields.size() > 14 ? fields[14] : '';
        row.customerState = fields.size() > 15 ? fields[15] : '';
        row.zipCode = fields.size() > 16 ? fields[16] : '';
        row.description = fields.size() > 17 ? fields[17] : '';

        return row;
    }

    private static Date parseDate(String dateStr) {
        if (String.isBlank(dateStr))
            return null;

        try {
            // Parse MM/DD/YYYY format (e.g., "8/2/2025", "08/02/2025")
            if (dateStr.contains('/')) {
                List<String> parts = dateStr.split('/');
                if (parts.size() == 3) {
                    Integer month = Integer.valueOf(parts[0]);
                    Integer day = Integer.valueOf(parts[1]);
                    Integer year = Integer.valueOf(parts[2]);
                    return Date.newInstance(year, month, day);
                } else {
                    // Return null for invalid format instead of throwing exception
                    return null;
                }
            } else {
                // Return null for invalid format instead of throwing exception
                return null;
            }
        } catch (Exception e) {
            // Return null for any parsing errors instead of throwing exception
            return null;
        }
    }

    private static List<String> validateDateFormats(CSVRow row) {
        List<String> errors = new List<String>();

        // Check if sales date is required and valid
        if (String.isNotBlank(row.originalSalesDate) && row.salesDate == null) {
            errors.add('Sales Date format is invalid. Expected MM/DD/YYYY format, got: ' + row.originalSalesDate);
        }

        // Check if activation date is required and valid
        if (String.isNotBlank(row.originalActivationDate) && row.activationDate == null) {
            errors.add(
                'Activation Date format is invalid. Expected MM/DD/YYYY format, got: ' + row.originalActivationDate
            );
        }

        return errors;
    }

    private static Case createCaseFromOrder(
        Order order,
        Id parentCaseId,
        User currentUser,
        Id recordTypeId,
        Id ownerId,
        CSVRow row,
        List<OrderItem> orderItems
    ) {
        // Get order products
        String productNames = '';
        if (orderItems != null && !orderItems.isEmpty()) {
            for (OrderItem item : orderItems) {
                if (productNames != '')
                    productNames += ', ';
                productNames += item.Product2.Name;
            }
        }

        return new Case(
            AccountId = order.AccountId,
            ContactId = currentUser.ContactId,
            POE_ICLRep__c = currentUser.ContactId,
            ParentId = parentCaseId,
            Order_Number__c = order.OrderNumber,
            Description = row.description,
            Order__c = order.Id,
            Origin = 'Chuzo',
            POE_Account_Number__c = order.POE_AccountNumber__c,
            POE_Activation_Date__c = order.ActivatedDate != null ? order.ActivatedDate.date() : null,
            POE_Channel__c = 'Chuzo',
            POE_City__c = order.ShippingCity,
            POE_Confirmation_Number__c = order.POE_OrderNumber__c,
            POE_Customer_FirstName__c = order.Account.FirstName,
            POE_Customer_LastName__c = order.Account.LastName,
            POE_Product_s_Sold__c = productNames,
            POE_Program__c = mapOrderProgramToCaseProgram(order.POE_Program__c),
            POE_Sales_Date__c = order.EffectiveDate,
            POE_State__c = order.ShippingState,
            POE_Street_Address__c = order.ShippingStreet,
            POE_Work_Order_Number__c = order.POE_OrderId__c,
            POE_Zip_Code__c = order.ShippingPostalCode,
            RecordTypeId = recordTypeId,
            OwnerId = ownerId,
            Status = 'New',
            Subject = 'Commission Escalations',
            Type = 'Commissions'
        );
    }

    private static Case createManualCase(CSVRow row, Id parentCaseId, User currentUser, Id recordTypeId, Id ownerId) {
        return new Case(
            AccountId = currentUser.AccountId,
            ContactId = currentUser.ContactId,
            POE_ICLRep__c = currentUser.ContactId,
            ParentId = parentCaseId,
            Description = row.description,
            Origin = 'Chuzo',
            POE_Account_Number__c = row.accountNumber,
            POE_Activation_Date__c = row.activationDate,
            POE_Channel__c = String.isNotBlank(row.channel) ? row.channel : 'Chuzo',
            POE_City__c = row.customerCity,
            POE_Confirmation_Number__c = row.confirmationNumber,
            POE_Customer_FirstName__c = row.customerFirstName,
            POE_Customer_LastName__c = row.customerLastName,
            POE_Partner_ID_PID__c = row.partnerSalesCode,
            POE_Product_s_Sold__c = row.product,
            POE_Program__c = row.program,
            POE_Sales_Date__c = row.salesDate,
            POE_State__c = row.customerState,
            POE_Street_Address__c = row.customerAddress,
            POE_Wireless_Phone_Number__c = row.customerMobilityPhone,
            POE_Work_Order_Number__c = row.workOrderNumber,
            POE_Zip_Code__c = row.zipCode,
            RecordTypeId = recordTypeId,
            OwnerId = ownerId,
            Status = 'New',
            Subject = 'Commission Escalations',
            Type = 'Commissions'
        );
    }
}