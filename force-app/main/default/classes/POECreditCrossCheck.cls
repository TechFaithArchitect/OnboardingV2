public class POECreditCrossCheck {
    @InvocableMethod(
        label='Cross Credit Scoring Check'
        description='Checks if another Order was created that day with same Customer Name and Address'
    )
    public static void creditCrossCheck(List<String> orderId) {
        Integer timelapse;
        try {
            Fraud_Validation_Rules__c valRule = [
                SELECT Time_Lapse__c
                FROM Fraud_Validation_Rules__c
                WHERE Name = 'CrossCredit'
                LIMIT 1
            ];
            timelapse = Integer.valueOf(valRule.Time_Lapse__c);
        } catch (Exception e) {
            timelapse = 24;
        }
        Order createdOrder = [
            SELECT Account.Name, Account.ShippingStreet, OpportunityId, Id, OwnerId
            FROM Order
            WHERE Id = :String.valueOf(orderId[0])
            LIMIT 1
        ];
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        List<Order> otherOrders = new List<Order>();
        List<String> orderOppIds = new List<String>();
        orderOppIds.add(createdOrder.OpportunityId);
        if (timelapse == 24) {
            otherOrders = [
                SELECT OpportunityId
                FROM Order
                WHERE
                    CreatedDate = TODAY
                    AND Account.Name = :createdOrder.Account.Name
                    AND Account.ShippingStreet = :createdOrder.Account.ShippingStreet
                    AND OwnerId != :createdOrder.OwnerId
            ];
        } else if (timelapse == 48) {
            otherOrders = [
                SELECT OpportunityId
                FROM Order
                WHERE
                    (CreatedDate = TODAY
                    OR CreatedDate = YESTERDAY)
                    AND Account.Name = :createdOrder.Account.Name
                    AND Account.ShippingStreet = :createdOrder.Account.ShippingStreet
                    AND OwnerId != :createdOrder.OwnerId
            ];
        }

        if (!otherOrders.isEmpty()) {
            for (Order ord : otherOrders) {
                orderOppIds.add(ord.OpportunityId);
            }
            List<Opportunity> opps = [SELECT Id, POE_CC_Flag__c FROM Opportunity WHERE Id IN :orderOppIds];
            for (Opportunity opp : opps) {
                if (!opp.POE_CC_Flag__c) {
                    opp.POE_CC_Flag__c = true;
                    oppToUpdate.add(opp);
                }
            }
            update oppToUpdate;
        }
    }
}