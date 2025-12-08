public with sharing class EmailTemplateSyncDMLService {
    private static final Integer MAX_RETRIES = 2;
    private static final Integer BATCH_SIZE = 200;

    /**
     * Safely inserts or updates Communication_Template__c records in batches with retry logic.
     * @param records - List of Communication_Template__c to process
     * @param isInsert - true for insert, false for update
     */
    public static void saveWithRetry(List<Communication_Template__c> records, Boolean isInsert) {
        if (records == null || records.isEmpty()) {
            System.debug('[DML] ⚪ No records to process.');
            return;
        }

        Integer total = records.size();
        System.debug('[DML] ' + (isInsert ? '🟢 Inserting ' : '🟠 Updating ') + total + ' Communication Templates...');

        for (Integer i = 0; i < total; i += BATCH_SIZE) {
            Integer endIndex = Math.min(i + BATCH_SIZE, total);

            // ⚙️ Build batch manually to avoid subList() issues with SObjects
            List<Communication_Template__c> batch = new List<Communication_Template__c>();
            for (Integer j = i; j < endIndex; j++) {
                batch.add(records[j]);
            }

            Integer attempt = 0;
            Boolean success = false;

            while (!success && attempt < MAX_RETRIES) {
                attempt++;
                try {
                    List<Database.SaveResult> results = isInsert
                        ? Database.insert(batch, false)
                        : Database.update(batch, false);

                    List<Communication_Template__c> failed = new List<Communication_Template__c>();

                    for (Integer k = 0; k < results.size(); k++) {
                        if (!results[k].isSuccess()) {
                            failed.add(batch[k]);
                            Database.Error error = results[k].getErrors()[0];
                            System.debug('❌ [DML] ' + (isInsert ? 'Insert' : 'Update') + 
                                ' failed for ' + batch[k].DeveloperName__c + 
                                ' — ' + error.getStatusCode() + ': ' + error.getMessage());
                        }
                    }

                    if (failed.isEmpty()) {
                        success = true;
                        System.debug('✅ [DML] Batch succeeded on attempt ' + attempt + ' (' + batch.size() + ' records)');
                    } else if (attempt < MAX_RETRIES) {
                        batch = failed;
                        System.debug('🔁 [DML] Retrying ' + failed.size() + ' failed records...');
                    } else {
                        success = true;
                        System.debug('🚨 [DML] Permanent failures after ' + MAX_RETRIES + ' attempts.');
                    }

                } catch (Exception dmlException) {
                    System.debug('💥 [DML Exception] Attempt ' + attempt + ': ' + dmlException.getMessage());
                    if (attempt >= MAX_RETRIES) throw dmlException;
                }
            }
        }

        System.debug('[DML] ✅ Completed processing ' + total + ' records.');
    }
}