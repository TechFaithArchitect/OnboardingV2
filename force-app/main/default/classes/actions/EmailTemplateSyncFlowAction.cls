public with sharing class EmailTemplateSyncFlowAction {
    public class Request {
        @InvocableVariable public Boolean runAsManual;
    }

    public class Result {
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Run Full Email Template Sync')
    public static List<Result> run(List<Request> requests) {
        List<Result> results = new List<Result>();
        Boolean isManual = !requests.isEmpty() && requests[0].runAsManual;

        EmailTemplateSyncOrchestrator.run(isManual);

        Result result = new Result();
        result.message = 'Sync completed manually.';
        results.add(result);
        return results;
    }
}
