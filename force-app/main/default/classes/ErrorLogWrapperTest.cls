@isTest
public class ErrorLogWrapperTest {
    final static String SENSITIVE_TEST_DATA = '0000000000000000';

    @isTest
    static void removeSensitiveInfoTestPositive() {
        Map<String, Object> testJsonRequest = new Map<String, Object>();
        String testSensitiveFieldName = ErrorLogWrapper.SENSITIVE_INFO_FIELD_SET[0];
        testJsonRequest.put(testSensitiveFieldName, SENSITIVE_TEST_DATA);
        String testString = JSON.serialize(testJsonRequest);

        Test.startTest();
        String resultString = ErrorLogWrapper.removeSensitiveInfo(testString);
        Test.stopTest();

        Map<String, Object> resultJson = (Map<String, Object>) JSON.deserializeUntyped(resultString);

        Assert.areNotEqual(
            SENSITIVE_TEST_DATA,
            resultJson.get(testSensitiveFieldName),
            'Result should not contain any user sensitive data'
        );
        Assert.areEqual(
            ErrorLogWrapper.SENSITIVE_INFO_PLACEHOLDER,
            resultJson.get(testSensitiveFieldName),
            'Sensitive data should be replaced by ***** placeholder'
        );
    }

    @isTest
    static void removeSensitiveInfoTestNegative() {
        Map<String, Object> testJsonRequest = new Map<String, Object>();
        String testNonSensitiveFieldName = 'name';
        String testNonSensitiveFieldValue = 'Jane Johnson';
        testJsonRequest.put(testNonSensitiveFieldName, testNonSensitiveFieldValue);
        String testString = JSON.serialize(testJsonRequest);

        Test.startTest();
        String resultString = ErrorLogWrapper.removeSensitiveInfo(testString);
        Test.stopTest();

        Map<String, Object> resultJson = (Map<String, Object>) JSON.deserializeUntyped(resultString);

        Assert.areEqual(
            testNonSensitiveFieldValue,
            resultJson.get(testNonSensitiveFieldName),
            'Non sensitive data should not be replaced'
        );
    }

    @isTest
    static void removeSensitiveInfoSetterTest() {
        Map<String, Object> testJsonRequest = new Map<String, Object>();
        String testSensitiveFieldName = ErrorLogWrapper.SENSITIVE_INFO_FIELD_SET[0];
        testJsonRequest.put(testSensitiveFieldName, SENSITIVE_TEST_DATA);
        String testString = JSON.serialize(testJsonRequest);

        ErrorLogWrapper wrapper = new ErrorLogWrapper();

        Test.startTest();
        wrapper.request = testString;
        Test.stopTest();

        Map<String, Object> resultJson = (Map<String, Object>) JSON.deserializeUntyped(wrapper.request);

        Assert.areNotEqual(
            SENSITIVE_TEST_DATA,
            resultJson.get(testSensitiveFieldName),
            'Result should not contain any user sensitive data'
        );
        Assert.areEqual(
            ErrorLogWrapper.SENSITIVE_INFO_PLACEHOLDER,
            resultJson.get(testSensitiveFieldName),
            'Sensitive data should be replaced by ***** placeholder'
        );
    }
}