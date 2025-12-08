public without sharing class FSL_ShiftsViewer_Mobile_Controller {
    public class ShiftDisplayWrapper {
        @AuraEnabled public String key {get; set;}
        @AuraEnabled public String day {get; set;}
        @AuraEnabled public String startTime {get; set;}
        @AuraEnabled public String endTime {get; set;}
        @AuraEnabled public List<String> territories {get; set;}
    }

    @AuraEnabled
    public static List<ShiftDisplayWrapper> getMyShifts(Boolean isCurrentWeek) {
        List<ServiceResource> serviceResourceList = [
            SELECT Id FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId() LIMIT 1
        ];
        if (serviceResourceList.isEmpty()) {
            return new List<ShiftDisplayWrapper>();
        }
        ServiceResource serviceResource = serviceResourceList[0];

        TimeZone userTimeZone = UserInfo.getTimeZone();

        FSL_Settings__c settings = FSL_Settings__c.getOrgDefaults();
        Integer weekStartDay = Integer.valueOf(settings.Shifts_First_Day_of_the_Week__c);
        Date today = Date.today();
        Integer dayOfWeek = Integer.valueOf(Datetime.now().format('u'));
        Date weekStart;
        if (isCurrentWeek) {
            weekStart = today.addDays(weekStartDay - dayOfWeek);
        } else {
            weekStart = today.addDays(weekStartDay + 7 - dayOfWeek);
        }
        Date weekEnd = weekStart.addDays(7);

        List<Shift> shifts = [
            SELECT Id, StartTime, EndTime, ServiceTerritoryId, ServiceTerritory.OperatingHours.TimeZone, ServiceTerritory.ParentTerritory.Name
            FROM Shift
            WHERE ServiceResourceId = :serviceResource.Id
            AND StartTime >= :weekStart
            AND StartTime < :weekEnd
            AND ServiceTerritory.IsActive = TRUE
            ORDER BY StartTime, EndTime
        ];

        Map<String, ShiftDisplayWrapper> groupedShifts = new Map<String, ShiftDisplayWrapper>();
        for (Shift shift : shifts) {
            TimeZone targetTimeZone = TimeZone.getTimeZone(shift.ServiceTerritory.OperatingHours.TimeZone);
            shift.StartTime = PV_ShiftCreationController.undoHourDifference(shift.StartTime, userTimeZone, targetTimeZone);
            shift.EndTime = PV_ShiftCreationController.undoHourDifference(shift.EndTime, userTimeZone, targetTimeZone);

            String day = shift.StartTime.format('EEEE');
            String startTime = shift.StartTime.format('hh:mma');
            String endTime = shift.EndTime.format('hh:mma');
            String key = day + '-' + startTime + '-' + endTime;
            if (!groupedShifts.containsKey(key)) {
                groupedShifts.put(key, new ShiftDisplayWrapper());
                groupedShifts.get(key).key = key;
                groupedShifts.get(key).day = day;
                groupedShifts.get(key).startTime = startTime;
                groupedShifts.get(key).endTime = endTime;
                groupedShifts.get(key).territories = new List<String>();
            }
            groupedShifts.get(key).territories.add(shift.ServiceTerritory.ParentTerritory.Name);
            groupedShifts.get(key).territories.sort();
        }

        return groupedShifts.values();
    }
}