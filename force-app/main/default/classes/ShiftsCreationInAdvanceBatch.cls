public class ShiftsCreationInAdvanceBatch implements Database.Batchable<sObject>, Schedulable {
    public static List<String> daysOfTheWeek = new List<String>{'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Fryday', 'Saturday'};
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        if (!Test.isRunningTest()) {
            query = 'SELECT ID, Name FROM ServiceResource WHERE IsActive = TRUE LIMIT 15000000';
        } else {
            query = 'SELECT ID, Name FROM ServiceResource WHERE IsActive = TRUE LIMIT 15';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<ServiceResource> resourcesToProcess = (List<ServiceResource>) scope;

        Set<Id> resourceIds = new Set<Id>();
        Map<Id, List<Shift>> shiftsPerResource = new Map<Id, List<Shift>>();
        
        for (ServiceResource resource : resourcesToProcess) {
            resourceIds.add(resource.Id);
        }

        for(Shift resourceShift : [SELECT Id, StartTime, EndTime, Status, TimeSlotType, ServiceResourceId, ServiceTerritoryId, IsHolidayShift FROM Shift WHERE ServiceResourceId IN :resourceIds AND StartTime >= TODAY ORDER BY StartTime]) {
            if(shiftsPerResource.get(resourceShift.ServiceResourceId) == null) {
                List<Shift> shiftList = new List<Shift>();
                shiftsPerResource.put(resourceShift.ServiceResourceId, shiftList);
            }
            shiftsPerResource.get(resourceShift.ServiceResourceId).add(resourceShift);
        }

        FSL_Settings__c settings = FSL_Settings__c.getOrgDefaults();
        Integer weekStart = Integer.valueOf(settings.Shifts_First_Day_of_the_Week__c);
        Integer weeksInAdvance = Integer.valueOf(settings.Shift_Weeks_In_Advance__c);

        List<Shift> shiftsToCreate = new List<Shift> ();
        for (Id resourceId : shiftsPerResource.keySet()) {
            if(shiftsPerResource.get(resourceId).size() > 0) {
                List<Shift> result = generateShiftsInAdvance(shiftsPerResource.get(resourceId), weekStart, weeksInAdvance);
                shiftsToCreate.addAll(result);
            }
        }

        insert shiftsToCreate;
    }

    public void finish(Database.BatchableContext bc) {
        FSL_ShiftsDeletionBatch deletionBatch = new FSL_ShiftsDeletionBatch();
        Database.executeBatch(deletionBatch);
    }

    public void execute(SchedulableContext sc) {
        ShiftsCreationInAdvanceBatch batchJob = new ShiftsCreationInAdvanceBatch();
        Database.executeBatch(batchJob);
    }

    public static List<Shift> generateShiftsInAdvance (List<Shift> futureShifts, Integer firstDayOfTheWeek, Integer weeksInAdvance) {

        List<Shift> returnList = new List<Shift>();
        List<Shift> lastScheduledWeekShifts = new List<Shift>();


        Shift lastShift = futureShifts[futureShifts.size()-1];
        date standardWeekStart = Date.valueOf(lastShift.StartTime).toStartofWeek();
        Integer LastWeekEndPosition = standardWeekStart.daysBetween(Date.valueOf(lastShift.StartTime));
        
        if(LastWeekEndPosition < firstDayOfTheWeek) {
            LastWeekEndPosition = LastWeekEndPosition + 7;
        }
        Integer dayDifference = LastWeekEndPosition - firstDayOfTheWeek;

        Date lastWeekStartDate = Date.valueOf(lastShift.StartTime.addDays(-dayDifference));
        Date lastWeekEndDate = lastWeekStartDate.addDays(6);
        System.debug('LastWeekStart: ' + lastWeekStartDate);
        System.debug('LastWeekEnd: ' + lastWeekEndDate);

        for (Shift scheduledShift : futureShifts) { 
            if(Date.valueOf(scheduledShift.StartTime) >= lastWeekStartDate && Date.valueOf(scheduledShift.StartTime) <= lastWeekEndDate) {
                Shift shiftToCopy = scheduledShift;
                Shift copyShift = shiftToCopy.clone();
                lastScheduledWeekShifts.add(copyShift);
            }
        }

        Integer numberOfDays = (system.today()).daysBetween(lastWeekStartDate) - 1;
        Integer numberOfWeeksCreated = Integer.valueOf(numberOfDays/7) + 1;
        Integer weeksToCreate = weeksInAdvance - numberOfWeeksCreated;

        for (Integer i = 1; i<= weeksToCreate;  i++) {
            for (Shift copyShift : lastScheduledWeekShifts) {
                Shift newShift = copyShift.clone();
                newShift.StartTime = copyShift.StartTime.addDays(7*i);
                newShift.EndTime = copyShift.EndTime.addDays(7*i);
                returnList.add(newShift);
            }
        }

        return returnList;
    }
}