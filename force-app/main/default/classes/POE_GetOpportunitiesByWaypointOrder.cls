public without sharing class POE_GetOpportunitiesByWaypointOrder {
    @AuraEnabled(cacheable=false)
    public static Map<Integer, Opportunity> getOpportunitiesByWaypointOrder(String opportunityId) {
        List<maps__Waypoint__c> routeWaypoints = new List<maps__Waypoint__c>();
        List<Opportunity> waypointOpportunities = new List<Opportunity>();
        List<Id> opportunitiesIds = new List<Id>();
        Map<Integer, Opportunity> opportunitiesObjBySortOrder = new Map<Integer, Opportunity>();
        List<maps__Waypoint__c> latestWaypoint = new List<maps__Waypoint__c>();
        Id userId = [SELECT OwnerId FROM Opportunity WHERE Id = :opportunityId].OwnerId;
        try {
            List<maps__Waypoint__c> auxList = [
                SELECT
                    maps__BaseObject__c,
                    maps__Route__c,
                    maps__SortOrder__c,
                    maps__Route__r.maps__User__r.Name,
                    maps__Route__r.maps__Date__c,
                    maps__Opportunity__c,
                    maps__Route__r.maps__User__c
                FROM maps__Waypoint__c
                WHERE
                    maps__Opportunity__c = :opportunityId
                    AND maps__Route__r.maps__User__c = :userId
                    AND maps__BaseObject__c = 'Opportunity'
                ORDER BY maps__Route__r.maps__Date__c DESC
                LIMIT 1
            ];
            latestWaypoint.addAll(auxList);
        } catch (ListException e) {
            latestWaypoint.clear();
        } finally {
            if (latestWaypoint.size() > 0) {
                String routeId = latestWaypoint[0].maps__Route__c;
                routeWaypoints = [
                    SELECT maps__BaseObject__c, maps__SortOrder__c, maps__Opportunity__c, maps__Route__c
                    FROM maps__Waypoint__c
                    WHERE maps__Route__c = :routeId AND maps__BaseObject__c = 'Opportunity'
                ];

                for (maps__Waypoint__c wp : routeWaypoints) {
                    opportunitiesIds.add(Id.valueOf(wp.maps__Opportunity__c));
                }
                waypointOpportunities = [
                    SELECT Id, Maps_Street__c, Maps_City__c, Maps_State__c, Maps_PostalCode__c
                    FROM Opportunity
                    WHERE Id IN :opportunitiesIds
                ];

                for (maps__Waypoint__c wp : routeWaypoints) {
                    Opportunity matchingOpportunity = new Opportunity();
                    for (Opportunity opp : waypointOpportunities) {
                        if (opp.Id == wp.maps__Opportunity__c) {
                            matchingOpportunity = opp;
                        }
                    }

                    opportunitiesObjBySortOrder.put(Integer.valueOf(wp.maps__SortOrder__c), matchingOpportunity);
                }
            } else {
                Opportunity singleOpp = [
                    SELECT Id, Maps_Street__c, Maps_City__c, Maps_State__c, Maps_PostalCode__c
                    FROM Opportunity
                    WHERE Id = :opportunityId
                ];
                opportunitiesObjBySortOrder.put(1, singleOpp);
            }
        }

        return opportunitiesObjBySortOrder;
    }
}