public class ExceptionUtil {
    public static void publishException(String typeName, Integer lineNumber, String message, String stackTrace) {
        Error_Alert__e pe = new Error_Alert__e();
        pe.Type_Name__c = typeName;
        pe.Line_Number__c = lineNumber;
        pe.Message__c = message;
        pe.Stack_Trace__c = stackTrace;
        EventBus.publish(pe);
    }

    public static void publishFSLException(String type, String provider, String component, String error) {
        FSL_Error_Alert__e event = new FSL_Error_Alert__e();
        event.Type__c = type;
        event.Provider__c = provider;
        event.Component__c = component;
        event.Error__c = error;
        EventBus.publish(event);
    }

    public static Error_Alert__e prepareException(String typeName, Integer lineNumber, String message, String stackTrace) {
        Error_Alert__e pe = new Error_Alert__e();
        pe.Type_Name__c = typeName;
        pe.Line_Number__c = lineNumber;
        pe.Message__c = message;
        pe.Stack_Trace__c = stackTrace;
        return pe;
    }

    public static void publishExceptions(List<Error_Alert__e> errorAlerts) {
        EventBus.publish(errorAlerts);
    }
}