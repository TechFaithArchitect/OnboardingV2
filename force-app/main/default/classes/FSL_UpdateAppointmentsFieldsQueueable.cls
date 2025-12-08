public without sharing class FSL_UpdateAppointmentsFieldsQueueable implements Queueable, Database.AllowsCallouts {
    private List<ServiceAppointment> appointments;
    private Id policyId;
    private DateTime intervalStart;
    private DateTime intervalEnd; 
    private Map<Id, ServiceTerritory> territoryMap;

    public FSL_UpdateAppointmentsFieldsQueueable(List<ServiceAppointment> targetAppointment, Id targetPolicyId, DateTime intervalStart, DateTime intervalEnd, Map<Id, ServiceTerritory> territoryMap) {
        this.appointments = targetAppointment;
        this.policyId = targetPolicyId;
        this.intervalStart = intervalStart;
        this.intervalEnd = intervalEnd;
        this.territoryMap = territoryMap;
    }

    public void execute(QueueableContext context) {
        System.debug('enter execute PV_UpdateAppointmentsFieldsQueable');

        this.appointments[0].ArrivalWindowStartTime = this.intervalStart;
        this.appointments[0].ArrivalWindowEndTime = this.intervalEnd;
        update this.appointments[0];

        System.debug('before PV_RunShedulerCostcoQueable');
        if (!Test.isRunningTest()) {
            System.enqueueJob(new FSL_RunShedulerCostcoQueueable(this.appointments, this.policyId, this.territoryMap));
        }
    }
}