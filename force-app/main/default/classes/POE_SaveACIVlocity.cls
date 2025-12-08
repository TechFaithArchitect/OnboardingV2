global without sharing class POE_SaveACIVlocity implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;

        try {
            List<POE_ACI_Statistic__c> aciList = new List<POE_ACI_Statistic__c>();
            POE_ACI_Statistic__c newACI = new POE_ACI_Statistic__c();

            String oppId = (String) inputMap.get('ContextId');
            Decimal latitude = (Decimal) inputMap.get('latitude');
            Decimal longitude = (Decimal) inputMap.get('longitude');
            String origin = (String) inputMap.get('origin');

            aciList = [
                SELECT Id, Point_of_Disposition__latitude__s, Point_of_Disposition__longitude__s
                FROM POE_ACI_Statistic__c
                WHERE Opportunity__c = :oppId
            ];

            if (aciList.isEmpty()) {
                newACI.Statistics_Date__c = System.now();
                newACI.Opportunity__c = oppId;
                newACI.Point_of_Disposition__latitude__s = latitude;
                newACI.Point_of_Disposition__longitude__s = longitude;
                newACI.Contact__c = 1;
                if (origin == 'retail') {
                    List<POE_Clicker_Retail_Track__c> retail = [
                        SELECT POE_Store__c
                        FROM POE_Clicker_Retail_Track__c
                        WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND POE_Store__c != NULL
                    ];
                    if (!retail.isEmpty()) {
                        POE_Retail_Store__c store = [
                            SELECT Name, Location__latitude__s, Location__longitude__s
                            FROM POE_Retail_Store__c
                            WHERE Id = :retail[0].POE_Store__c
                            LIMIT 1
                        ];
                        newACI.Store__c = store.Id;
                        newACI.StoreName__c = store.Name;
                        newACI.Point_of_Interest__latitude__s = store.Location__latitude__s;
                        newACI.Point_of_Interest__longitude__s = store.Location__longitude__s;
                    }
                } else if (origin == 'mdu') {
                    List<MDU_Tracker__c> tracker = [
                        SELECT MDU_Chuzo__c
                        FROM MDU_Tracker__c
                        WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND MDU_Chuzo__c != NULL
                    ];
                    if (!tracker.isEmpty()) {
                        MDU_Chuzo__c mdu = [
                            SELECT Name, Location__latitude__s, Location__longitude__s
                            FROM MDU_Chuzo__c
                            WHERE Id = :tracker[0].MDU_Chuzo__c
                            LIMIT 1
                        ];
                        newACI.MDU_Chuzo__c = mdu.Id;
                        newACI.Name_MDU__c = mdu.Name;
                        newACI.Point_of_Interest__latitude__s = mdu.Location__latitude__s;
                        newACI.Point_of_Interest__longitude__s = mdu.Location__longitude__s;
                    }
                } else if (origin == 'event') {
                    List<POE_Clicker_Event_Track__c> event = [
                        SELECT POE_Event__c
                        FROM POE_Clicker_Event_Track__c
                        WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND POE_Event__c != NULL
                    ];
                    if (!event.isEmpty()) {
                        POE_Event__c eve = [
                            SELECT Name, Location__latitude__s, Location__longitude__s
                            FROM POE_Event__c
                            WHERE Id = :event[0].POE_Event__c
                            LIMIT 1
                        ];
                        newACI.StoreName__c = eve.Name;
                        newACI.Point_of_Interest__latitude__s = eve.Location__latitude__s;
                        newACI.Point_of_Interest__longitude__s = eve.Location__longitude__s;
                    }
                } else if (origin == 'maps') {
                    Opportunity opp = [
                        SELECT Maps_Latitude__c, Maps_Longitude__c, Name
                        FROM Opportunity
                        WHERE Id = :oppId
                        LIMIT 1
                    ];
                    newACI.StoreName__c = opp.Name;
                    newACI.Point_of_Interest__latitude__s = opp.Maps_Latitude__c;
                    newACI.Point_of_Interest__longitude__s = opp.Maps_Longitude__c;
                } else if (origin == 'phonesales') {
                    Opportunity opp = [
                        SELECT Maps_Latitude__c, Maps_Longitude__c, Name
                        FROM Opportunity
                        WHERE Id = :oppId
                        LIMIT 1
                    ];
                    newACI.StoreName__c = opp.Name;
                    newACI.Point_of_Interest__latitude__s = opp.Maps_Latitude__c;
                    newACI.Point_of_Interest__longitude__s = opp.Maps_Longitude__c;
                }
                insert newACI;
            } else {
                aciList[0].Contact__c = 1;
                if (origin == 'retail') {
                    List<POE_Clicker_Retail_Track__c> retail = [
                        SELECT POE_Store__c
                        FROM POE_Clicker_Retail_Track__c
                        WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND POE_Store__c != NULL
                    ];
                    if (!retail.isEmpty()) {
                        POE_Retail_Store__c store = [
                            SELECT Name, Location__latitude__s, Location__longitude__s
                            FROM POE_Retail_Store__c
                            WHERE Id = :retail[0].POE_Store__c
                            LIMIT 1
                        ];
                        aciList[0].Store__c = store.Id;
                        aciList[0].StoreName__c = store.Name;
                        aciList[0].Point_of_Interest__latitude__s = store.Location__latitude__s;
                        aciList[0].Point_of_Interest__longitude__s = store.Location__longitude__s;
                    }
                } else if (origin == 'mdu') {
                    List<MDU_Tracker__c> tracker = [
                        SELECT MDU_Chuzo__c
                        FROM MDU_Tracker__c
                        WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND MDU_Chuzo__c != NULL
                    ];
                    if (!tracker.isEmpty()) {
                        MDU_Chuzo__c mdu = [
                            SELECT Name, Location__latitude__s, Location__longitude__s
                            FROM MDU_Chuzo__c
                            WHERE Id = :tracker[0].MDU_Chuzo__c
                            LIMIT 1
                        ];
                        aciList[0].MDU_Chuzo__c = mdu.Id;
                        aciList[0].Name_MDU__c = mdu.Name;
                        aciList[0].Point_of_Interest__latitude__s = mdu.Location__latitude__s;
                        aciList[0].Point_of_Interest__longitude__s = mdu.Location__longitude__s;
                    }
                } else if (origin == 'event') {
                    List<POE_Clicker_Event_Track__c> event = [
                        SELECT POE_Event__c
                        FROM POE_Clicker_Event_Track__c
                        WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND POE_Event__c != NULL
                    ];
                    if (!event.isEmpty()) {
                        POE_Event__c eve = [
                            SELECT Name, Location__latitude__s, Location__longitude__s
                            FROM POE_Event__c
                            WHERE Id = :event[0].POE_Event__c
                            LIMIT 1
                        ];
                        aciList[0].StoreName__c = eve.Name;
                        aciList[0].Point_of_Interest__latitude__s = eve.Location__latitude__s;
                        aciList[0].Point_of_Interest__longitude__s = eve.Location__longitude__s;
                    }
                } else if (origin == 'maps') {
                    Opportunity opp = [
                        SELECT Maps_Latitude__c, Maps_Longitude__c, Name
                        FROM Opportunity
                        WHERE Id = :oppId
                        LIMIT 1
                    ];
                    aciList[0].StoreName__c = opp.Name;
                    aciList[0].Point_of_Interest__latitude__s = opp.Maps_Latitude__c;
                    aciList[0].Point_of_Interest__longitude__s = opp.Maps_Longitude__c;
                } else if (origin == 'phonesales') {
                    Opportunity opp = [
                        SELECT Maps_Latitude__c, Maps_Longitude__c, Name
                        FROM Opportunity
                        WHERE Id = :oppId
                        LIMIT 1
                    ];
                    aciList[0].StoreName__c = opp.Name;
                    aciList[0].Point_of_Interest__latitude__s = opp.Maps_Latitude__c;
                    aciList[0].Point_of_Interest__longitude__s = opp.Maps_Longitude__c;
                }
                update aciList[0];
            }
        } catch (Exception e) {
            result = false;
        }
        return result;
    }
}