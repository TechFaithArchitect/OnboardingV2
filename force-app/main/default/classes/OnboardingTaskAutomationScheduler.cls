global class OnboardingTaskAutomationScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        OnboardingTaskAutomationJob.run();
    }
}