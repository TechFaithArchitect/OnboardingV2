@isTest
public class POE_NewCaseOverrideControllerTest {
    
    @isTest
    static void getCaseRecordTypesTest() {
        Test.startTest();
        List<POE_NewCaseOverrideController.RecordTypeWrapper> recordTypeWrappers;
        recordTypeWrappers = POE_NewCaseOverrideController.getCaseRecordTypes();
        Test.stopTest();

        Assert.isFalse(recordTypeWrappers.isEmpty(), 'No Case Record Types were returned');

        for (POE_NewCaseOverrideController.RecordTypeWrapper rtWrapper : recordTypeWrappers) {
            Assert.isTrue(String.isNotBlank(rtWrapper.name), 'The name field was left blank.');
            Assert.isTrue(String.isNotBlank(rtWrapper.objectApiName), 'The objectApiName field was left blank.');
            Assert.isTrue(String.isNotBlank(rtWrapper.recordTypeId), 'The recordTypeId field was left blank.');
            Assert.isTrue(rtWrapper.isAvailable, 'One of the Record Types retrieved is not available.');
        }
    }
}