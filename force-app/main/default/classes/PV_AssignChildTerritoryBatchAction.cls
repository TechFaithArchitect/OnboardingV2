public with sharing class PV_AssignChildTerritoryBatchAction {
    @InvocableMethod(label='Assign Child Territories' description='Starts a batch job to assign child territories for the provided ServiceAppointment Ids.')
    public static void startAssignChildTerritoryBatch(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        Set<Id> aggregatedServiceAppointmentIds = new Set<Id>();

        for (Request request : requests) {
            if (request == null || request.serviceAppointmentId == null) {
                continue;
            }
            aggregatedServiceAppointmentIds.add(request.serviceAppointmentId);
        }

        if (aggregatedServiceAppointmentIds.isEmpty()) {
            return;
        }

        Database.executeBatch(new PV_AssignChildTerritoryBatch(new List<Id>(aggregatedServiceAppointmentIds)));
    }

    public class Request {
        @InvocableVariable(required=true description='ServiceAppointment record Id to process')
        public Id serviceAppointmentId;
    }
}