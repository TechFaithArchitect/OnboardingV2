public with sharing class CommunicationTemplateRepository {
    
    // MOCK DATA OVERRIDE
    @TestVisible private static Map<String, Communication_Template__c> testMockTemplates;

    public static void setMockTemplates(Map<String, Communication_Template__c> templates) {
        testMockTemplates = templates;
    }

    // FETCH ALL COMM TEMPLATES FROM DB
    public static Map<String, Communication_Template__c> getAllTemplates() {
        if (Test.isRunningTest() && testMockTemplates != null) {
            return testMockTemplates;
        }

        Map<String, Communication_Template__c> result = new Map<String, Communication_Template__c>();

        for (Communication_Template__c rec : [
            SELECT Id, Name, DeveloperName__c, Email_Subject__c, Folder_Name__c,
                   Communication_Type__c, Active__c
            FROM Communication_Template__c
        ]) {
            if (String.isNotBlank(rec.DeveloperName__c)) {
                result.put(rec.DeveloperName__c, rec);
            }
        }

        return result;
    }

    // UPSERT LOGIC
    public static void upsertTemplates(List<Communication_Template__c> incomingRecords) {
        if (incomingRecords == null || incomingRecords.isEmpty()) return;

        Map<String, Communication_Template__c> existing = getAllTemplates();

        List<Communication_Template__c> toInsert = new List<Communication_Template__c>();
        List<Communication_Template__c> toUpdate = new List<Communication_Template__c>();

        for (Communication_Template__c newRec : incomingRecords) {
            String key = newRec.DeveloperName__c;

            if (String.isBlank(key)) continue;

            if (existing.containsKey(key)) {
                Communication_Template__c oldRec = existing.get(key);

                Boolean isUnchanged =
                    oldRec.Folder_Name__c == newRec.Folder_Name__c &&
                    oldRec.Email_Subject__c == newRec.Email_Subject__c &&
                    oldRec.Communication_Type__c == newRec.Communication_Type__c &&
                    oldRec.Active__c == newRec.Active__c;

                if (isUnchanged) {
                    System.debug('Skipped unchanged: ' + key);
                    continue;
                }

                oldRec.Folder_Name__c = newRec.Folder_Name__c;
                oldRec.Email_Subject__c = newRec.Email_Subject__c;
                oldRec.Communication_Type__c = newRec.Communication_Type__c;
                oldRec.Active__c = newRec.Active__c;

                toUpdate.add(oldRec);
            } else {
                toInsert.add(newRec);
            }
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(toInsert, false);
            System.debug('Inserted: ' + insertResults.size());
        }

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(toUpdate, false);
            System.debug('Updated: ' + updateResults.size());
        }

        if (toInsert.isEmpty() && toUpdate.isEmpty()) {
            System.debug('No changes to upsert.');
        }
    }

    /**
     * Safely inserts or updates Communication_Template__c records in batches with retry logic.
     * This method provides robust error handling and retry capability for bulk operations.
     * 
     * @param records - List of Communication_Template__c to process
     * @param isInsert - true for insert, false for update
     */
    public static void saveWithRetry(List<Communication_Template__c> records, Boolean isInsert) {
        if (records == null || records.isEmpty()) {
            System.debug('[DML] ⚪ No records to process.');
            return;
        }

        final Integer MAX_RETRIES = 2;
        final Integer BATCH_SIZE = 200;

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
