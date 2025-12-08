public without sharing class LimitMonitorScheduler implements Schedulable {
    
    public void execute(SchedulableContext SC) {
        LimitMonitoringService.checkAndNotifyLimits();
    }
}