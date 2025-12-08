public class PV_ServiceAppointmentHandler {
    // Boolean to control recursion as this is after update
    public static Boolean boolStopRun = false;
    
    public static void handleAfterInsertUpdate(List<ServiceAppointment> triggerNew) {
        // Stop the run if this code was already run
        if (boolStopRun) return;
        
        // Make boolStopRun true in order to stop the run and prevent recursion - should be here not at the end
        boolStopRun = true;
        
        Set<Id> setSAId = new Set<Id>();
        for (ServiceAppointment sa : triggerNew) {
            if (sa.SchedStartTime != Null || sa.ArrivalWindowStartTime != null ) {
                setSAId.add(sa.Id);
            }
        }

        List<ServiceAppointment> lstSA = [
            SELECT  Id, AppointmentNumber, SchedStartTime, SchedEndTime, ArrivalWindowStartTime, ArrivalWindowEndTime, ServiceTerritory.OperatingHours.TimeZone
            FROM    ServiceAppointment 
            WHERE   Id IN : setSAId
        ];
        
        List<ServiceAppointment> lstSaToUpdate = new List<ServiceAppointment>();

        for (ServiceAppointment sa : lstSA) {
            String strLocalSchedStartTime;
            String strLocalSchedEndTime;
            String strLocalSchedStartDateTime;
            String strLocalSchedEndDateTime;
            
            if (sa.ServiceTerritory.OperatingHours.TimeZone != null) {
                String strSTTZ = sa.ServiceTerritory.OperatingHours.TimeZone;
                if (sa.ArrivalWindowStartTime != null) {
                    strLocalSchedStartTime = sa.ArrivalWindowStartTime.format('hh:mm aaa z', strSTTZ);
                    strLocalSchedStartDateTime = sa.ArrivalWindowStartTime.format('MMMMM dd, YYYY hh:mm aaa z', strSTTZ);
                } else {
                    strLocalSchedStartTime = sa.SchedStartTime.format('hh:mm aaa z', strSTTZ);
                    strLocalSchedStartDateTime = sa.SchedStartTime.format('MMMMM dd, YYYY hh:mm aaa z', strSTTZ);
                }
                
                if (sa.ArrivalWindowEndTime != null) {
                    strLocalSchedEndTime = sa.ArrivalWindowEndTime.format('hh:mm aaa z', strSTTZ);
                    strLocalSchedEndDateTime = sa.ArrivalWindowEndTime.format('MMMMM dd, YYYY hh:mm aaa z', strSTTZ);
                } else {
                    strLocalSchedEndTime = sa.SchedEndTime.format('hh:mm aaa z', strSTTZ);
                    strLocalSchedEndDateTime = sa.SchedEndTime.format('MMMMM dd, YYYY hh:mm aaa z', strSTTZ);
                }
                
                ServiceAppointment saUpdated = new ServiceAppointment();
                saUpdated.Id = sa.Id;
                saUpdated.Arrival_Start__c = strLocalSchedStartTime;
                saUpdated.Arrival_Start_Date__c = strLocalSchedStartDateTime;
                saUpdated.Arrival_End__c = strLocalSchedEndTime;
                saUpdated.Arrival_End_Date__c = strLocalSchedEndDateTime;
                lstSaToUpdate.add(saUpdated);
            }
        }
        update lstSaToUpdate;
    }
}