global class POE_OwnerRoleUpdateSchedulable implements Schedulable {
    global void execute(SchedulableContext SC) {
        POE_OwnerRoleUpdate role = new POE_OwnerRoleUpdate();
        Id batchInstanceId = Database.executeBatch(role);
    }
}