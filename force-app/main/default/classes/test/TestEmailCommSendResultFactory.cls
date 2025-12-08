@isTest
public class TestEmailCommSendResultFactory {

    public static EmailCommSendResultDTO createMockSuccessResult() {
        return new EmailCommSendResultDTO(
            'Success',
            TestDataFactoryIdUtil.fakeIdForSObject(Email_Communication_Log__c.SObjectType),
            null
        );
    }

    public static EmailCommSendResultDTO createMockFailureResult(String errorMessage) {
        return new EmailCommSendResultDTO(
            'Failure',
            null,
            errorMessage
        );
    }
}