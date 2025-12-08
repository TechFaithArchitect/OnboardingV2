public without sharing class FSL_ServiceAppointmentHelper {

    @InvocableMethod(label='Convert Timezone for Service Appointments' description='Converts Service Appointment times to the specified timezone')
    public static List<ServiceAppointmentWrapper> convertToTimeZone(List<String> serviceAppointmentIds) {
        List<ServiceAppointmentWrapper> results = new List<ServiceAppointmentWrapper>();

        List<ServiceAppointment> serviceAppointments = [
            SELECT  Id, ServiceTerritory.OperatingHours.TimeZone, SchedStartTime, ArrivalWindowStartTime, ArrivalWindowEndTime
            FROM    ServiceAppointment
            WHERE   Id IN :serviceAppointmentIds
        ];

        for (ServiceAppointment sa : serviceAppointments) {
            ServiceAppointmentWrapper wrapper = new ServiceAppointmentWrapper();
            wrapper.serviceAppointmentId = sa.Id;

            if (sa.ServiceTerritory.OperatingHours.TimeZone != null) {
                String strSTTZ = sa.ServiceTerritory.OperatingHours.TimeZone;
                wrapper.formattedSchedStartTime = sa.SchedStartTime.format('MM/dd/yyyy', strSTTZ);
            }

            results.add(wrapper);
        }

        return results;
    }

    public class ServiceAppointmentWrapper {
        @InvocableVariable(label='Service Appointment Id' required=true)
        public Id serviceAppointmentId;

        @InvocableVariable(label='Formatted Sched Start Time' required=false)
        public String formattedSchedStartTime;
    }
}