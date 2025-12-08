public without sharing class FSL_ScheduleCostcoAppointmentsQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> appointmentIds;
    private Map<Id, ServiceTerritory> serviceTerritoryMap;
    
    public FSL_ScheduleCostcoAppointmentsQueueable(List<Id> appointmentList, Map<Id, ServiceTerritory> TerritoryMap) {
        this.appointmentIds = appointmentList;
        this.serviceTerritoryMap = TerritoryMap;
    }

    public void execute(QueueableContext context) {
        List<ServiceAppointment> appointmentList = [
            SELECT  Id, EarliestStartTime, ServiceTerritoryId, WorkTypeId, WorkType.Afternoon_Installation__c
            FROM    ServiceAppointment
            WHERE   Id IN :this.appointmentIds
        ];

        if (appointmentList.size() > 0) {
            ServiceAppointment appointment = appointmentList[0];
            Id schedulingPolicyId = FSL_OrdersServiceHandler.getDefaultPolicy();
            ServiceTerritory targetTerritory = this.serviceTerritoryMap.get(appointment.ServiceTerritoryId);

            if (targetTerritory.OperatingHoursId != null) {
                Timezone timeZone = TimeZone.getTimeZone(targetTerritory.OperatingHours.TimeZone);
                Date appointmentEarliestStartDate = appointment.EarliestStartTime.date();
                DateTime intervalStart;
                DateTime intervalEnd;

                if (appointment.WorkType.Afternoon_Installation__c == false) {
                    intervalStart = DateTime.newInstance(appointmentEarliestStartDate, Time.newInstance(8, 0, 0, 0));
                    intervalEnd = DateTime.newInstance(appointmentEarliestStartDate, Time.newInstance(18, 0, 0, 0));
                } else {
                    intervalStart = DateTime.newInstance(appointmentEarliestStartDate, Time.newInstance(11, 0, 0, 0));
                    intervalEnd = DateTime.newInstance(appointmentEarliestStartDate, Time.newInstance(18, 0, 0, 0));
                }

                if (!Test.isRunningTest()) {
                    System.enqueueJob(new FSL_UpdateAppointmentsFieldsQueueable(
                        appointmentList, schedulingPolicyId, intervalStart, intervalEnd, this.serviceTerritoryMap
                    ));
                }
            }
        }
    }
}