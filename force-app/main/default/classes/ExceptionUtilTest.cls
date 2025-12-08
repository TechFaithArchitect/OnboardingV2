@isTest
public class ExceptionUtilTest {
    @isTest
    static void publishException_positive() {
        Test.startTest();
        ExceptionUtil.publishException('ExceptionUtil', 15, 'Test message', 'Test stackTrace String');
        Test.getEventBus().deliver();
        Test.stopTest();
        List<PV_Error_Log__c> lst_Exception = [SELECT Id FROM PV_Error_Log__c WHERE Type_Name__c = 'ExceptionUtil'];
        System.assert(!lst_Exception.isEmpty(), 'ErrorLog__c records');
    }

    @isTest
    static void publishExceptionsTest() {
        List<Error_Alert__e> errorAlerts = new List<Error_Alert__e>();
        Error_Alert__e errorAlert = ExceptionUtil.prepareException('ExceptionUtil', 15, 'Test message', 'Test stackTrace String');
        errorAlerts.add(errorAlert);

        Test.startTest();
        ExceptionUtil.publishExceptions(errorAlerts);
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PV_Error_Log__c> lst_Exception = [SELECT Id FROM PV_Error_Log__c WHERE Type_Name__c = 'ExceptionUtil'];
        System.assert(!lst_Exception.isEmpty(), 'ErrorLog__c records');
    }

    @isTest
    static void publishFSLExceptionTest() {
        Test.startTest();
        ExceptionUtil.publishFSLException('Internal Error', 'FSL', ExceptionUtilTest.class.getName(), 'Test error message');
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Component__c = :ExceptionUtilTest.class.getName()];
        Assert.isTrue(!errorLogs.isEmpty(), 'No logs created in Error_Log__c.');
    }
}