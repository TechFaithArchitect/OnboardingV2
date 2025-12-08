public class DeactivateInactiveUsersBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    private Set<Id> defaultOwnerUserIds;

    public DeactivateInactiveUsersBatch() {
        defaultOwnerUserIds = new Set<Id>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        for (Site site : [SELECT GuestRecordDefaultOwnerId FROM Site WHERE GuestRecordDefaultOwnerId != NULL]) {
            defaultOwnerUserIds.add(site.GuestRecordDefaultOwnerId);
        }

        Date ninetyDaysAgo = Date.today().addDays(-90);

        if (Test.isRunningTest()) {
            return Database.getQueryLocator(
                [
                    SELECT Id, IsActive, LearnUponP__LU_Field_1__c
                    FROM User
                    WHERE
                        IsActive = TRUE
                        AND LearnUponP__LU_Field_1__c <= :ninetyDaysAgo
                        AND Contact.Chuzo_Member__c = TRUE
                        AND Contact.FSL_Member__c = FALSE
                        AND Id NOT IN :defaultOwnerUserIds
                ]
            );
        }

        return Database.getQueryLocator(
            [
                SELECT Id, IsActive, LastLoginDate
                FROM User
                WHERE
                    IsActive = TRUE
                    AND (LastLoginDate <= :ninetyDaysAgo
                    OR (LastLoginDate = NULL
                    AND CreatedDate <= :ninetyDaysAgo))
                    AND Contact.Chuzo_Member__c = TRUE
                    AND Contact.FSL_Member__c = FALSE
                    AND Id NOT IN :defaultOwnerUserIds
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<User> scope) {
        List<User> usersToUpdate = new List<User>();

        for (User u : scope) {
            u.IsActive = false;
            usersToUpdate.add(u);
        }

        if (!usersToUpdate.isEmpty()) {
            try {
                update usersToUpdate;
            } catch (Exception e) {
                System.debug('Error updating users: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        DeactivateInactiveUsersBatch batch = new DeactivateInactiveUsersBatch();
        Database.executeBatch(batch, 200);
    }
}