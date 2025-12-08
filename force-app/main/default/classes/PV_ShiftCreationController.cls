public without sharing class PV_ShiftCreationController {

    @AuraEnabled
    public static List<ShiftWrapper> getResourceShifts(String resourceId, String browserTimeZone){

        Datetime now = Datetime.now();
        Datetime nextWeekStart = getNextMonday(now);
        Datetime nextWeekEnd = nextWeekStart.addDays(7);
        Map<String, ShiftWrapper> wrappersByDay = new Map<String, ShiftWrapper>();
        
        Map<Id, String> timezonesByTerritoryId = new Map<Id, String>();
        for (ServiceTerritory territory : [SELECT Id, OperatingHoursId, OperatingHours.TimeZone FROM ServiceTerritory]) {
            timezonesByTerritoryId.put(territory.Id, territory.OperatingHours.TimeZone);
        }
        
        List<ShiftWrapper> result = new List<ShiftWrapper>();
        List<Shift> shifts = [SELECT Id, StartTime, EndTime, ServiceTerritoryId, ServiceTerritory.Name, ServiceResourceId FROM Shift WHERE ServiceResourceId = :resourceId];

        Integer rowId = 1;
        for (Shift shift: shifts) {
            if(shift.startTime.date() >= nextWeekStart.date() && shift.endTime.date() < nextWeekEnd.date()) {

                TimeZone userTimeZone = UserInfo.getTimeZone();
                TimeZone targetTimeZone = TimeZone.getTimeZone(timezonesByTerritoryId.get(shift.ServiceTerritoryId));
                TimeZone browserZone = TimeZone.getTimeZone(browserTimeZone);
                
                shift.StartTime = undoHourDifference(shift.StartTime, userTimeZone, targetTimeZone);
                shift.EndTime = undoHourDifference(shift.EndTime, userTimeZone, targetTimeZone);

                String dayName = shift.startTime.format('EEEE');

                String startHour = shift.StartTime.format('HH:mm:ss.SSS');
                String endHour = shift.EndTime.format('HH:mm:ss.SSS');

                ShiftWrapper newRow = new ShiftWrapper();
                newRow.id = rowId + '';
                newRow.day = dayName;
                newRow.startTime = startHour;
                newRow.endTime = endHour;
                newRow.territories = new List<String>();
                newRow.territories.add(shift.ServiceTerritoryId);
                newRow.territoriesLabel = shift.ServiceTerritory.Name;
                newRow.recordId = shift.Id;
                result.add(newRow);

                rowId ++;
            }
        }
        System.debug('WrappersByDay: ' + wrappersByDay);
        return result;
    }

    @AuraEnabled
    public static Boolean createNewResourceShifts (String resourceId, List<Shift> shifts, String browserTimeZone){

        List<Shift> deleteShifts = new List<Shift>();
        List<Shift> shiftsToDelete = [SELECT Id, StartTime, EndTime, ServiceTerritoryId, ServiceTerritory.Name, ServiceResourceId FROM Shift WHERE ServiceResourceId = :resourceId];

        Map<Id, String> timezonesByTerritoryId = new Map<Id, String>();
        for (ServiceTerritory territory : [SELECT Id, OperatingHoursId, OperatingHours.TimeZone FROM ServiceTerritory]) {
            timezonesByTerritoryId.put(territory.Id, territory.OperatingHours.TimeZone);
        }

        Datetime now = Datetime.now();
        Datetime nextWeekStart = getNextMonday(now);
        Datetime nextWeekEnd = nextWeekStart.addDays(7);

        for (Shift shift: shiftsToDelete) {
            if(shift.startTime.date() >= nextWeekStart.date()) {
                deleteShifts.add(shift);
            }
        }

        delete deleteShifts;

        if(shifts.size()>0) {
            for(Shift shiftToUpdate : shifts) {
                if(timezonesByTerritoryId.get(shiftToUpdate.ServiceTerritoryId) != null && browserTimeZone != ''){
                    TimeZone userTimeZone = UserInfo.getTimeZone();
                    TimeZone targetTimeZone = TimeZone.getTimeZone(timezonesByTerritoryId.get(shiftToUpdate.ServiceTerritoryId));
                    TimeZone browserZone = TimeZone.getTimeZone(browserTimeZone);

                    shiftToUpdate.StartTime = PV_ManageServiceResources.calculateHoursDiference(shiftToUpdate.StartTime, browserZone, userTimeZone);
                    shiftToUpdate.EndTime = PV_ManageServiceResources.calculateHoursDiference(shiftToUpdate.EndTime, browserZone, userTimeZone);

                    shiftToUpdate.StartTime = PV_ManageServiceResources.calculateHoursDiference(shiftToUpdate.StartTime, userTimeZone, targetTimeZone);
                    shiftToUpdate.EndTime = PV_ManageServiceResources.calculateHoursDiference(shiftToUpdate.EndTime, userTimeZone, targetTimeZone);

                }
                shiftToUpdate.ServiceResourceId = resourceId;
                shiftToUpdate.Status = 'Confirmed';
            }

            Insert shifts;

            //run createShiftsInAdvance
            FSL_Settings__c settings = FSL_Settings__c.getOrgDefaults();
            Integer weekStart = Integer.valueOf(settings.Shifts_First_Day_of_the_Week__c);
            Integer weeksInAdvance = Integer.valueOf(settings.Shift_Weeks_In_Advance__c);
            List<Shift> futureShiftsToCreate = ShiftsCreationInAdvanceBatch.generateShiftsInAdvance(shifts, weekStart, weeksInAdvance);

            System.debug('futureShiftsToCreate: ' + futureShiftsToCreate);
            insert futureShiftsToCreate;
        }
        return true;
    }


    public static Datetime getNextMonday(Datetime currentDateTime) {
        // Get the day of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        Integer dayOfWeek = Integer.valueOf(currentDateTime.format('u'));
        
        // Calculate the days to add to get to the next Monday
        Integer daysToNextMonday = 8 - dayOfWeek;
        if (daysToNextMonday > 7) {
            daysToNextMonday -= 7;
        }
        
        // Add the calculated days to the current date
        return currentDateTime.addDays(daysToNextMonday);
    }

    public static DateTime undoHourDifference (DateTime startDate, TimeZone timeZone1, TimeZone timeZone2) {
        System.debug('StartDate: ' + startDate);

        Integer offset1 = timeZone1.getOffset(startDate);
        Integer offset2 = timeZone2.getOffset(startDate);
                                    
        Integer offsetDifferenceInSeconds = (offset1 - offset2) / 1000;
        Integer offsetDifferenceInHours = offsetDifferenceInSeconds/3600;
                                    
        System.debug('offsetDifferenceInSeconds: ' + offsetDifferenceInSeconds/3600);

        DateTime returnDate = startDate.addHours(-offsetDifferenceInHours);
        System.debug('newDateTime: ' + returnDate);

        return returnDate;

    }
    
    
    
    
    public class ShiftWrapper {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String day {get; set;}
        @AuraEnabled
        public String startTime {get; set;}
        @AuraEnabled
        public String endTime {get; set;}
        @AuraEnabled
        public List<String> territories {get; set;}
        @AuraEnabled
        public String territoriesLabel {get; set;}
        @AuraEnabled
        public String recordId {get; set;}
    }
}