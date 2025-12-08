public class lwcCSVUploaderController {
    private static final String SOBJECT_NAME = 'Account';
    private static final String GENERIC_ERROR = System.Label.Lwc_Uploader_Invalid_File_Generic_Error;
    private static final String MAX_RECORDS_ERROR = System.Label.Lwc_Uploader_Invalid_File_Maximum_Records_Error;
    private class DealerException extends Exception {
    }
    public class JsonInsertResult {
        List<Database.Error> errors { get; set; }
        String salesforceId { get; set; }
        public Boolean isSuccess { get; set; }
        Account personAccountData { get; set; }
    }

    // Cache for picklist values
    private static Map<String, Map<String, String>> picklistCache = new Map<String, Map<String, String>>();

    // Helper method to load picklist values lazily
    private static Map<String, String> getPicklistValues(String sObjectType, String picklistFieldName) {
        String cacheKey = sObjectType + '.' + picklistFieldName;

        if (picklistCache.containsKey(cacheKey)) {
            return picklistCache.get(cacheKey);
        }

        Schema.SObjectType sObjectSchema = Schema.getGlobalDescribe().get(sObjectType);
        Schema.DescribeFieldResult picklistDescribe = sObjectSchema.getDescribe()
            .fields.getMap()
            .get(picklistFieldName)
            .getDescribe();

        List<Schema.PicklistEntry> picklistPles = picklistDescribe.getPicklistValues();
        Map<String, String> apiValuesByLabels = new Map<String, String>();

        for (Schema.PicklistEntry ple : picklistPles) {
            apiValuesByLabels.put(ple.getLabel().toLowerCase(), ple.getValue());
        }

        picklistCache.put(cacheKey, apiValuesByLabels);
        return apiValuesByLabels;
    }

    @AuraEnabled
    public static string saveFile(String base64Data) {
        List<Account> personAccountsToInsert = new List<Account>();
        List<Database.SaveResult> insertResults = new List<Database.SaveResult>();
        String finalResults;
        try {
            String data = JSON.deserializeUntyped(base64Data).toString();

            List<String> lstCSVLines = data.split('\n');

            if (lstCSVLines.isEmpty() || lstCSVLines.size() <= 1) {
                throw new DealerException(GENERIC_ERROR);
            } else if (lstCSVLines.size() > 201) {
                throw new DealerException(MAX_RECORDS_ERROR);
            }
            for (Integer i = 1; i < lstCSVLines.size(); i++) {
                String csvLine = lstCSVLines[i];

                Integer semicolonCount = csvLine.countMatches(';');
                Integer commaCount = csvLine.countMatches(',');

                String delimiter = semicolonCount > commaCount ? ';' : ',';

                List<String> csvRecordData = parseCSVLine(csvLine, delimiter);

                Account newPersonAccount = new Account();

                if (csvRecordData.size() > 0 && String.isNotBlank(csvRecordData[0])) {
                    newPersonAccount.FirstName = formatCSVTextField(csvRecordData[0]);
                }

                if (csvRecordData.size() > 1 && String.isNotBlank(csvRecordData[1])) {
                    newPersonAccount.LastName = formatCSVTextField(csvRecordData[1]);
                }

                if (csvRecordData.size() > 2 && String.isNotBlank(csvRecordData[2])) {
                    newPersonAccount.Phone = formatCSVPhoneField(csvRecordData[2]);
                }

                if (csvRecordData.size() > 3 && String.isNotBlank(csvRecordData[3])) {
                    newPersonAccount.PersonEmail = formatCSVTextField(csvRecordData[3]);
                }

                if (csvRecordData.size() > 4 && String.isNotBlank(csvRecordData[4])) {
                    newPersonAccount.PersonOtherPhone = formatCSVPhoneField(csvRecordData[4]);
                }

                if (csvRecordData.size() > 5 && String.isNotBlank(csvRecordData[5])) {
                    newPersonAccount.POE_Alternate_Email__pc = formatCSVTextField(csvRecordData[5]);
                }

                if (csvRecordData.size() > 6 && String.isNotBlank(csvRecordData[6])) {
                    newPersonAccount.BillingStreet = formatCSVTextField(csvRecordData[6]);
                    newPersonAccount.ShippingStreet = formatCSVTextField(csvRecordData[6]);
                }

                if (csvRecordData.size() > 7 && String.isNotBlank(csvRecordData[7])) {
                    newPersonAccount.Billing_Address_Line_2__c = formatCSVTextField(csvRecordData[7]);
                    newPersonAccount.Shipping_Address_Line_2__c = formatCSVTextField(csvRecordData[7]);
                }

                if (csvRecordData.size() > 8 && String.isNotBlank(csvRecordData[8])) {
                    newPersonAccount.BillingCity = formatCSVTextField(csvRecordData[8]);
                    newPersonAccount.ShippingCity = formatCSVTextField(csvRecordData[8]);
                }

                if (csvRecordData.size() > 9 && String.isNotBlank(csvRecordData[9])) {
                    newPersonAccount.BillingStateCode = formatCSVTextField(csvRecordData[9]);
                    newPersonAccount.ShippingStateCode = formatCSVTextField(csvRecordData[9]);
                }

                if (csvRecordData.size() > 10 && String.isNotBlank(csvRecordData[10])) {
                    newPersonAccount.BillingPostalCode = formatCSVTextField(csvRecordData[10]);
                    newPersonAccount.ShippingPostalCode = formatCSVTextField(csvRecordData[10]);
                }

                if (csvRecordData.size() > 11 && String.isNotBlank(csvRecordData[11])) {
                    newPersonAccount.Lead_Origin__pc = formatCSVSinglePicklistField(
                        SOBJECT_NAME,
                        'Lead_Origin__pc',
                        csvRecordData[11]
                    );
                }

                if (csvRecordData.size() > 12 && String.isNotBlank(csvRecordData[12])) {
                    newPersonAccount.Lead_Origin_Other__pc = formatCSVTextField(csvRecordData[12]);
                }

                if (csvRecordData.size() > 13 && String.isNotBlank(csvRecordData[13])) {
                    newPersonAccount.Program_Lead_Type__pc = formatCSVMultiPicklistField(
                        SOBJECT_NAME,
                        'Program_Lead_Type__pc',
                        csvRecordData[13],
                        delimiter
                    );
                }

                if (csvRecordData.size() > 14 && String.isNotBlank(csvRecordData[14])) {
                    newPersonAccount.Program_Lead_Type_Other__pc = formatCSVTextField(csvRecordData[14]);
                }

                if (csvRecordData.size() > 15 && String.isNotBlank(csvRecordData[15])) {
                    newPersonAccount.Current_Provider_s__pc = formatCSVTextField(csvRecordData[15]);
                }

                if (csvRecordData.size() > 16 && String.isNotBlank(csvRecordData[16])) {
                    newPersonAccount.Current_Provider_s_Cost__pc = formatCSVCurrencyField(csvRecordData[16]);
                }

                if (csvRecordData.size() > 17 && String.isNotBlank(csvRecordData[17])) {
                    newPersonAccount.Under_Contract__pc = formatCSVBooleanField(csvRecordData[17]);
                }

                if (csvRecordData.size() > 18 && String.isNotBlank(csvRecordData[18])) {
                    newPersonAccount.Contract_Expiration_Date__pc = formatCSVDateField(csvRecordData[18]);
                }

                if (csvRecordData.size() > 19 && String.isNotBlank(csvRecordData[19])) {
                    newPersonAccount.Suggested_Provider_s__pc = formatCSVTextField(csvRecordData[19]);
                }

                if (csvRecordData.size() > 20 && String.isNotBlank(csvRecordData[20])) {
                    newPersonAccount.Suggested_Provider_s_Cost__pc = formatCSVCurrencyField(csvRecordData[20]);
                }

                if (csvRecordData.size() > 21 && String.isNotBlank(csvRecordData[21])) {
                    newPersonAccount.First_Date_Contacted__pc = formatCSVDateField(csvRecordData[21]);
                }

                if (csvRecordData.size() > 22 && String.isNotBlank(csvRecordData[22])) {
                    newPersonAccount.Second_Date_Contacted__pc = formatCSVDateField(csvRecordData[22]);
                }

                if (csvRecordData.size() > 23 && String.isNotBlank(csvRecordData[23])) {
                    newPersonAccount.Third_Date_Contacted__pc = formatCSVDateField(csvRecordData[23]);
                }

                if (csvRecordData.size() > 24 && String.isNotBlank(csvRecordData[24])) {
                    newPersonAccount.Sold_Date__pc = formatCSVDateField(csvRecordData[24]);
                }

                if (csvRecordData.size() > 25 && String.isNotBlank(csvRecordData[25])) {
                    newPersonAccount.Rating__pc = formatCSVSinglePicklistField(
                        SOBJECT_NAME,
                        'Rating__pc',
                        csvRecordData[25]
                    );
                }

                if (csvRecordData.size() > 26 && String.isNotBlank(csvRecordData[26])) {
                    newPersonAccount.Opportunity_Stage__pc = formatCSVSinglePicklistField(
                        SOBJECT_NAME,
                        'Opportunity_Stage__pc',
                        csvRecordData[26]
                    );
                }
                personAccountsToInsert.add(newPersonAccount);
            }

            if (!personAccountsToInsert.isEmpty()) {
                insertResults = Database.insert(personAccountsToInsert, false);
            }

            List<JsonInsertResult> resultResponse = new List<JsonInsertResult>();
            Integer resultSize = insertResults.size();

            for (Integer index = 0; index < resultSize; index++) {
                JsonInsertResult resultRow = new JsonInsertResult();
                resultRow.errors = insertResults[index].getErrors();
                resultRow.isSuccess = insertResults[index].isSuccess();
                resultRow.personAccountData = personAccountsToInsert[index];
                if (insertResults[index].isSuccess()) {
                    resultRow.salesforceId = personAccountsToInsert[index].Id;
                }
                resultResponse.add(resultRow);
            }
            finalResults = JSON.serialize(resultResponse);
        } catch (Exception e) {
            finalResults = e.getMessage();
        }
        return finalResults;
    }

    public static List<String> parseCSVLine(String csvLine, String delimiter) {
        List<String> result = new List<String>();
        Boolean inQuotes = false;
        String currentValue = '';

        for (Integer i = 0; i < csvLine.length(); i++) {
            String currentChar = csvLine.substring(i, i + 1);

            if (currentChar == '"') {
                inQuotes = !inQuotes;
            } else if (currentChar == delimiter && !inQuotes) {
                result.add(currentValue.trim());
                currentValue = '';
            } else {
                currentValue += currentChar;
            }
        }

        result.add(currentValue.trim());

        return result;
    }

    public static string formatCSVTextField(String field) {
        if (field == null) {
            return '';
        }
        field = field.replaceAll('\n', '').replaceAll('\r', '').trim();
        return field;
    }

    public static string formatCSVPhoneField(String field) {
        if (field == null) {
            return '';
        }
        Pattern nonNumeric = Pattern.compile('[^0-9]');
        Matcher matcher = nonNumeric.matcher(field);
        field = matcher.replaceAll('').replaceAll('\n', '').replaceAll('\r', '');
        return field;
    }

    public static String formatCSVMultiPicklistField(
        String sObjectType,
        String picklistFieldName,
        String csvPicklistValues,
        String delimiter
    ) {
        String multiPicklistDelimiter = ';';
        if (delimiter == ';') {
            multiPicklistDelimiter = ',';
        }

        Map<String, String> apiValuesByLabels = getPicklistValues(sObjectType, picklistFieldName);

        String processedPicklistValues = csvPicklistValues.replaceAll('\n', '').replaceAll('\r', '');

        for (String value : processedPicklistValues.split(multiPicklistDelimiter)) {
            if (!apiValuesByLabels.containsKey(value.toLowerCase())) {
                continue;
            }
            processedPicklistValues = processedPicklistValues.replace(
                value,
                apiValuesByLabels.get(value.toLowerCase())
            );
        }

        processedPicklistValues = processedPicklistValues.replace(multiPicklistDelimiter, ';').replace('"', '');
        return processedPicklistValues;
    }

    public static String formatCSVSinglePicklistField(
        String sObjectType,
        String picklistFieldName,
        String csvPicklistValue
    ) {
        Map<String, String> apiValuesByLabels = getPicklistValues(sObjectType, picklistFieldName);

        String cleanedPicklistValue = csvPicklistValue.replaceAll('\n', '').replaceAll('\r', '').trim();

        if (apiValuesByLabels.containsKey(cleanedPicklistValue.toLowerCase())) {
            return apiValuesByLabels.get(cleanedPicklistValue.toLowerCase());
        }

        return null;
    }

    public static Decimal formatCSVCurrencyField(String field) {
        String cleanedCurrencyValue = field.replaceAll('[^0-9.-]', '');

        if (String.isBlank(cleanedCurrencyValue)) {
            return null;
        }

        try {
            return Decimal.valueOf(cleanedCurrencyValue);
        } catch (Exception e) {
            return null;
        }
    }

    public static Boolean formatCSVBooleanField(String field) {
        if (String.isBlank(field)) {
            return false;
        } else {
            String normalizedValue = field.trim().toLowerCase();

            if (normalizedValue == 'true' || normalizedValue == 'yes') {
                return true;
            } else {
                return false;
            }
        }
    }

    public static Date formatCSVDateField(String field) {
        if (String.isBlank(field)) {
            return null;
        }

        String stringDate = field.replaceAll('\n', '').replaceAll('\r', '').trim();

        if (stringDate.contains('/')) {
            stringDate = stringDate.replaceAll('/', '-');
        }

        if (stringDate.indexOf('-') == 2) {
            String monthAndDay = stringDate.substring(0, 5);
            String year = stringDate.substring(6, 10);
            String correctedDate = year + '-' + monthAndDay;
            return Date.valueOf(correctedDate);
        }
        try {
            return Date.valueOf(stringDate);
        } catch (Exception e) {
            return null;
        }
    }
}