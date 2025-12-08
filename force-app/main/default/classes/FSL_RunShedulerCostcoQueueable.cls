public without sharing class FSL_RunShedulerCostcoQueueable implements Queueable, Database.AllowsCallouts {
    private static final String UNAVAILABLE_SLOT_ERROR_MESSAGE = 'The time slot or resource is no longer available';

    private List<ServiceAppointment> appointments;
    private Id policyId;
    private Map<Id, ServiceTerritory> territoryMap;
    
    public FSL_RunShedulerCostcoQueueable(List<ServiceAppointment> targetAppointment, Id targetPolicyId, Map<Id, ServiceTerritory> territoryMap) {
        this.appointments = targetAppointment;
        this.policyId = targetPolicyId;
        this.territoryMap = territoryMap;
    }

    public void execute(QueueableContext context) {
        ServiceAppointment appointmetToSchedule = new ServiceAppointment();
        FSL.ScheduleResult result = null;
        Boolean retryScheduling = false;

        try {
            appointmetToSchedule = this.appointments[0];
            result = FSL.ScheduleService.schedule(this.policyId, appointmetToSchedule.Id);
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', FSL_RunShedulerCostcoQueueable.class.getName(), e.getMessage());
            
            if (e.getMessage().contains(UNAVAILABLE_SLOT_ERROR_MESSAGE)) {
                retryScheduling = true;
            }
        }

        if (result == null && retryScheduling == false) {
            appointmetToSchedule.ArrivalWindowStartTime = null;
            appointmetToSchedule.ArrivalWindowEndTime = null;
            update appointmetToSchedule;
        }

        if (retryScheduling == false) {
            this.appointments.remove(0);
        }

        if (this.appointments.size() > 0) {
            List<Id> appointmentIds = new List<Id>();
            
            for (ServiceAppointment app : this.appointments) {
                appointmentIds.add(app.Id);
            }
            if (!Test.isRunningTest()) {
                System.enqueueJob(new FSL_ScheduleCostcoAppointmentsQueueable(appointmentIds, this.territoryMap));
            }
        }
    }
}