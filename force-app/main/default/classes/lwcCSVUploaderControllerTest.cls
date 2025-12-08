@isTest
public class lwcCSVUploaderControllerTest {
    private static final String VALID_CSV_STRING = 'First Name (Required),Last Name (Required),Phone (Required),Email (Required),Phone 2,Email 2,Street Address,Address Line 2,City,State Code,Zip,Lead Origin,Other Lead Origin,Program Lead Type,Other Program Lead Type,Current Provider(s),Current Provider(s) Cost,Under Contract,Contract Expiration Date,Suggested Provider(s),Suggested Provider(s) Cost,First Date Contacted,Second Date Contacted,Third Date Contacted,Sold Date,Rating,Stage\n Jane,Smith-Jones,(987)-654-3210,jane.smith@example.com,456-456-4567,alt.jane@example.com,456 Oak St,,,CA,90001,Other,Other Origin,Spectrum;DIRECTV;ViaSat;Windstream;Earthlink;Comcast/Xfinity;Other,Other Program Lead Description,Provider B,200.76,no,2024/09/30,Provider Y,,2023-02-01,2023-02-15,2023-02-28,2023-06-15,Warm,Qualified';
    private static final String PARTIAL_CSV_STRING = 'First Name (Required),Last Name (Required),Phone (Required),Email (Required),Phone 2,Email 2,Street Address,Address Line 2,City,State Code,Zip,Lead Origin,Other Lead Origin,Program Lead Type,Other Program Lead Type,Current Provider(s),Current Provider(s) Cost,Under Contract,Contract Expiration Date,Suggested Provider(s),Suggested Provider(s) Cost,First Date Contacted,Second Date Contacted,Third Date Contacted,Sold Date,Rating,Stage\n Jane,Smith-Jones,(987)-654-3210,jane.smith@example.com,456-456-4567,alt.jane@example.com,456 Oak St,Apt 1,Los Angeles,CA,90001,Event,,Spectrum;DIRECTV;ViaSat;Windstream;Earthlink;Comcast/Xfinity;Other,Other Program Lead Description,Provider B,200.76,no,09-30-2024,Provider Y,75.99,2023-02-01,2023-02-15,2023-02-28,2023-06-15,Warm,Qualified\n John,Doe,1234567890,johncom,,,123 Elm St,Apt 1,New York,NY,10001,D2D,,DIRECTV;Optimum,,Provider A,x,yes,2025-09-30,Provider X,50,2023-01-01,2023-01-15,ads,,Hot,Attempted';
    private static final String INVALID_CSV_STRING = 'invalid,data';
    private static final String GENERIC_ERROR = System.Label.Lwc_Uploader_Invalid_File_Generic_Error;

    @isTest
    private static void lwcCSVUploaderControllerInsertValidCSV() {
        String sampleCsv = VALID_CSV_STRING;
        String data = JSON.serialize(sampleCsv);
        Test.startTest();
        String results = lwcCSVUploaderController.saveFile(data);
        Test.stopTest();
        List<Object> response = (List<Object>) JSON.deserializeUntyped(results);

        for (Object res : response) {
            Map<String, Object> resultMap = (Map<String, Object>) res;
            System.assertEquals(true, resultMap.get('isSuccess'), 'Expected success');
        }
    }

    @isTest
    private static void lwcCSVUploaderControllerInsertPartialValidCSV() {
        String sampleCsv = PARTIAL_CSV_STRING;
        String data = JSON.serialize(sampleCsv);
        Test.startTest();
        String result = lwcCSVUploaderController.saveFile(data);
        Test.stopTest();
        List<lwcCSVUploaderController.JsonInsertResult> results = (List<lwcCSVUploaderController.JsonInsertResult>) JSON.deserialize(
            result,
            List<lwcCSVUploaderController.JsonInsertResult>.class
        );

        Boolean hasSuccess = false;
        Boolean hasFailure = false;

        for (lwcCSVUploaderController.JsonInsertResult insertResult : results) {
            if (insertResult.isSuccess) {
                hasSuccess = true;
            }
            if (!insertResult.isSuccess) {
                hasFailure = true;
            }
        }

        System.assert(hasSuccess, 'At least one record should have been successful.');
        System.assert(hasFailure, 'At least one record should have failed.');
    }

    @isTest
    private static void lwcCSVUploaderControllerInsertInvalidCSV() {
        String sampleCsv = INVALID_CSV_STRING;
        String data = JSON.serialize(sampleCsv);
        Test.startTest();
        String results = lwcCSVUploaderController.saveFile(data);
        Test.stopTest();

        String expectedErrorMessage = GENERIC_ERROR;

        System.assertEquals(
            expectedErrorMessage,
            results,
            'The error message should be as expected for invalid CSV files.'
        );
    }
}