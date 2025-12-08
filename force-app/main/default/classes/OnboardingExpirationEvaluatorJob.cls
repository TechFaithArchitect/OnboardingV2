global class OnboardingExpirationEvaluatorJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        OnboardingExpirationEvaluator.runExpirationJob();
    }
}