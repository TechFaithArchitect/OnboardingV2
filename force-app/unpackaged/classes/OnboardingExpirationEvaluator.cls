public class OnboardingExpirationEvaluator {
    public static Boolean bypassTracking = false;

    public static void runExpirationJob() {
        List<Onboarding_Status_Tracking_Config__mdt> configs = [
            SELECT Object__c, Field__c, Expire_Threshold_Days__c
            FROM Onboarding_Status_Tracking_Config__mdt
            WHERE IsActive__c = TRUE
              AND Expire_On_Inactivity__c = TRUE
        ];
        runExpirationJobWithConfigs(configs);
    }

    public static void runExpirationJobWithConfigs(List<Onboarding_Status_Tracking_Config__mdt> cmdtConfigs) {
        System.debug('🟦 START runExpirationJobWithConfigs');

        // 1) Build config maps
        Map<String, Integer> thresholdByKey = new Map<String, Integer>();
        Set<String> validObjects = new Set<String>();

        for (Onboarding_Status_Tracking_Config__mdt cfg : cmdtConfigs) {
            String key = cfg.Object__c + '.' + cfg.Field__c;
            thresholdByKey.put(key, cfg.Expire_Threshold_Days__c.intValue());
            validObjects.add(cfg.Object__c);
        }

        // 2) Query latest change per object+field+onboarding
        List<AggregateResult> latestChanges = [
            SELECT Onboarding__c, Source_Object__c, Field_Name__c, MAX(Change_Date__c) latestDate
            FROM Onboarding_Status_Change__c
            WHERE Source_Object__c IN :validObjects
              AND Change_Date__c != NULL
            GROUP BY Onboarding__c, Source_Object__c, Field_Name__c
        ];

        // 3) Map: OnboardingId → Set of field keys that are still "fresh"
        Map<Id, Set<String>> onboardingToFreshKeys = new Map<Id, Set<String>>();

        for (AggregateResult ar : latestChanges) {
            Id onboardingId = (Id) ar.get('Onboarding__c');
            String sourceObj = (String) ar.get('Source_Object__c');
            String fieldName = (String) ar.get('Field_Name__c');
            DateTime changeDate = (DateTime) ar.get('latestDate');

            String key = sourceObj + '.' + fieldName;
            Integer threshold = thresholdByKey.get(key);
            if (threshold == null) continue; // skip if not in CMDT
            DateTime cutoff = System.now().addDays(-threshold);

            if (changeDate >= cutoff) {
                if (!onboardingToFreshKeys.containsKey(onboardingId)) {
                    onboardingToFreshKeys.put(onboardingId, new Set<String>());
                }
                onboardingToFreshKeys.get(onboardingId).add(key);
            }
        }

        // 4) Get active Onboardings
        List<Onboarding__c> activeList = [
            SELECT Id, Onboarding_Status__c
            FROM Onboarding__c
            WHERE Onboarding_Status__c NOT IN ('Cancelled', 'Setup Complete', 'Expired', 'Denied')
        ];

        List<Onboarding__c> toExpire = new List<Onboarding__c>();
        Set<String> requiredKeys = thresholdByKey.keySet();

        for (Onboarding__c o : activeList) {
            Set<String> freshKeys = onboardingToFreshKeys.get(o.Id);

            // If any required key is missing, expire the onboarding
            if (freshKeys == null || !freshKeys.containsAll(requiredKeys)) {
                o.Onboarding_Status__c = 'Expired';
                toExpire.add(o);
                System.debug('💡 Expiring onboarding ' + o.Id);
            } else {
                System.debug('✅ Onboarding ' + o.Id + ' is up to date');
            }
        }

        // 5) Perform update
        if (!toExpire.isEmpty()) {
            update toExpire;
            System.debug('✅ Expired onboardings: ' + toExpire.size());
        } else {
            System.debug('🔷 No onboardings expired.');
        }

        System.debug('🟦 END runExpirationJobWithConfigs');
    }
}