public without sharing class poe_ownerOrderDashboardController {
    private static Boolean isPartnerUser;
    private static String accountId;
    private static List<String> reportNames = new List<String>{'TotalOrders', 'POE_OrdersRep_AVG', 'CompletedOrderPerc', 'OrdersByRep', 'DraftPercByRep', 'OrdersByProgram'};

    @AuraEnabled
    public static Map<String, String> getReports(){
        try {
            List<Report> reports = [SELECT Id, Name FROM Report WHERE DeveloperName IN :reportNames];
            Map<string, string> reportByName = new Map<String, String>();
            for(Report re :  reports){
                reportByName.put(re.Name, re.Id);
            }

            return reportByName;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getOrdersInfo(String programFilter, String typeFilter, String dateFilter, String startDate, String endDate){
        try{
            ResponseWrapper response = new ResponseWrapper();

            User currentUser = [SELECT Id, IsPortalEnabled, AccountId FROM User WHERE Id = :System.UserInfo.getUserId()];
            isPartnerUser = currentUser.IsPortalEnabled;
            accountId = currentUser.AccountId;

            response.numberChartData = getNumberData(programFilter, typeFilter, dateFilter, startDate, endDate);
            response.ordersByRep = getOrdersByRep(programFilter, typeFilter, dateFilter, startDate, endDate);
            response.ordersByProgram = getOrdersByProgram(programFilter, typeFilter, dateFilter, startDate, endDate);
            return response;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, List<String>> getFilterValues (){
        try {
            Map<String, List<String>> response = new Map<String, List<String>>();

            List<String> programValues = new List<String>();
            Schema.DescribeFieldResult programFieldResult = Order.POE_Program__c.getDescribe();
            List<Schema.PicklistEntry> programPle = programFieldResult.getPicklistValues();
            for(Schema.PicklistEntry entry : programPle){
                programValues.add(entry.getValue());
            }
            response.put('program', programValues);

            List<String> titleValues = new List<String>();
            Schema.DescribeFieldResult titleFieldResult = Contact.POE_Representative_Type__c.getDescribe();
            List<Schema.PicklistEntry> titlePle = titleFieldResult.getPicklistValues();
            for(Schema.PicklistEntry entry : titlePle){
                titleValues.add(entry.getValue());
            }
            response.put('representativeType', titleValues);

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Map<string, Object> getNumberData(String programFilter, String typeFilter, String dateFilter, String startDate, String endDate){
        Map<String, Object> numberData = new Map<String, Object>{
            'Draft' => 0,
            'Activated' => 0,
            'TotalSubmitted' => 0
        };

        String query = 'SELECT COUNT(Id)totalAmount, COUNT_DISTINCT(OwnerId)ownerAmount, COUNT_DISTINCT(EffectiveDate)daysAmount, status' +
            ' FROM Order' +
            ' WHERE POE_My_Dealer_Flag__c = true';
        
        query += generateQueryFilters(programFilter, typeFilter, dateFilter, startDate, endDate);

        if(isPartnerUser) {
            query += ' AND POE_Dealer__c = \'' + accountId + '\'';
        }

        query += ' GROUP BY Status';

        System.debug(query);
        List<AggregateResult> numberDataGroupedResults = Database.query(query);

        Integer distinctOwners = 0;
        Integer distinctDates = 0;

        if(!numberDataGroupedResults.isEmpty()){
            
            for(AggregateResult result :  numberDataGroupedResults){
                String status = (String) result.get('status');
                numberData.put(status.deleteWhitespace(), result.get('totalAmount'));
                
                if (status != 'Draft'){
                    Object submitted = (Integer) result.get('totalAmount') + (Integer) numberData.get('TotalSubmitted');
                    numberData.put('TotalSubmitted', submitted);

                    if (status == 'Activated' || status == 'Pending Installation'){
                        distinctOwners = distinctOwners + (Integer) result.get('ownerAmount');
                        distinctDates = distinctDates + (Integer) result.get('daysAmount');
                    }
                }
            }

            Decimal activatedOrders = numberData.containsKey('Activated') ? (Decimal) numberData.get('Activated') : 0;
            Decimal pendingOrders = numberData.containsKey('PendingInstallation') ? (Decimal) numberData.get('PendingInstallation') : 0;
            Decimal canceledOrders = numberData.containsKey('Canceled') ? (Decimal) numberData.get('Canceled') : 0;
            Decimal draftOrders = numberData.containsKey('Draft') ? (Decimal) numberData.get('Draft') : 0;
            Decimal totalSubmitted = numberData.containsKey('TotalSubmitted') ? (Decimal) numberData.get('TotalSubmitted') : 0;


            Decimal ownerByDayAVG = distinctOwners != 0 && distinctDates != 0 
                ? (activatedOrders + pendingOrders) / distinctOwners / distinctDates 
                : 0;

            numberData.put('ordersByRepByDayAVG', ownerByDayAVG.setScale(2));

            Decimal activationPercentage = activatedOrders != 0 || canceledOrders != 0 || pendingOrders !=0 
                ? (activatedOrders / (activatedOrders + canceledOrders + pendingOrders)) * 100
                : 0;

            numberData.put('ActivationPercentage', activationPercentage.setScale(2));

            Decimal submittedPercentage = totalSubmitted != 0 || draftOrders != 0 
                ? (totalSubmitted / (totalSubmitted + draftOrders)) * 100
                : 0;

            numberData.put('SubmittedPercentage', submittedPercentage.setScale(2));
        } else {
            numberData.put('error', 'No orders found');
        }

        return numberData;
    }

    private static List<Map<string, Object>> getOrdersByRep(String programFilter, String typeFilter, String dateFilter, String startDate, String endDate){
        Map<String, Map<string, Object>> ordersByRepByStatus = new Map<String, Map<String, Object>>();
        List<Map<String, Object>> response = new List<Map<string, Object>>();

        String query = 'SELECT COUNT(Id)repAmount, Owner.Name, Status' +
            ' FROM Order' +
            ' WHERE POE_My_Dealer_Flag__c = true';
        
        query += generateQueryFilters(programFilter, typeFilter, dateFilter, startDate, endDate);

        query += ' GROUP BY Owner.Name, Status';

        List<AggregateResult> groupedResult = Database.query(query);

        if(!groupedResult.isEmpty()) {
            for(AggregateResult result : groupedResult) {
                system.debug(result);
                if(!ordersByRepByStatus.containsKey((String) result.get('Name'))){
                    ordersByRepByStatus.put((String) result.get('Name'), New Map<String, Object>{
                        'Draft' => 0,
                        'Submitted' => 0
                    });
                }

                Map<String, Object> ordersByStatus = ordersByRepByStatus.get((String) result.get('Name'));
                if(result.get('Status') == 'Draft') {
                    Integer draftSum = (Integer) result.get('repAmount') + (Integer) ordersByStatus.get('Draft');
                    ordersByStatus.put('Draft', draftSum);
                    
                } else {
                    Integer submittedSum = (Integer) result.get('repAmount') + (Integer) ordersByStatus.get('Submitted');
                    ordersByStatus.put('Submitted', submittedSum);
                }
            }

            for(String key : ordersByRepByStatus.keySet()){
                Map<String, Object> repMap = ordersByRepByStatus.get(key);
                Decimal submittedOrders =  (Decimal) repMap.get('Submitted');
                Decimal draftOrders = (Decimal) repMap.get('Draft');
                Decimal submittedPercent = submittedOrders != 0 || draftOrders != 0 
                    ? (submittedOrders / (submittedOrders + draftOrders)) * 100
                    : 0;

                repMap.put('Name', key);
                repMap.put('SubmittedPercentage', submittedPercent.setScale(2));

                response.add(repMap);
            }
        }

        return response;
    }

    private static List<Map<String, Object>> getOrdersByProgram(String programFilter, String typeFilter, String dateFilter, String startDate, String endDate){
        List<Map<String, Object>> response = new List<Map<String, Object>>();

        String query = 'SELECT COUNT(Id)totalAmount, POE_Program__c ' +
            ' FROM Order' +
            ' WHERE POE_My_Dealer_Flag__c = true AND Status != \'Draft\'';
        
        query += generateQueryFilters(programFilter, typeFilter, dateFilter, startDate, endDate);

        query += ' GROUP BY POE_Program__c';

        List<AggregateResult> groupedResult = Database.query(query);

        for(AggregateResult result : groupedResult) {
            Map<String, Object> ordersByProgram = new Map<String, Object>{
                'Program' => result.get('POE_Program__c'),
                'Orders' => result.get('totalAmount')
            };

            response.add(ordersByProgram);
        }

        return response;
    }

    private static String generateQueryFilters(String programFilter, String typeFilter, String dateFilter, String startDate, String endDate){
        String query = '';

        if(programFilter != 'All') {
            query += ' AND POE_Program__c = \'' + programFilter + '\'';
        }

        if(typeFilter != 'All') {
            query += ' AND POE_RepTitle__c = \'' + typeFilter + '\'';
        }

        if(dateFilter != 'All') {
            if (dateFilter == 'Custom') {
                Date startDateParsed = Date.valueOf(startDate);
                String startDatetime = datetime.newInstance(startDateParsed.year(), startDateParsed.month(),startDateParsed.day()).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
                
                Date endDatetimeParsed = Date.valueOf(endDate);
                String endDatetime = datetime.newInstance(endDatetimeParsed.year(), endDatetimeParsed.month(),endDatetimeParsed.day()).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

                query += ' AND CreatedDate > ' + startDatetime + ' AND CreatedDate < ' + endDatetime;
            } else {
                query += ' AND CreatedDate = ' + dateFilter;
            }
        }

        if(isPartnerUser) {
            query += ' AND POE_Dealer__c = \'' + accountId + '\'';
        }

        return query;
    }

    @TestVisible
    class ResponseWrapper {
        @AuraEnabled public Map<String, Object> numberChartData;
        @AuraEnabled public List<Map<string, Object>> ordersByRep;
        @AuraEnabled public List<Map<String, OBject>> ordersByProgram;
        @AuraEnabled public Map<string, String> reportsByName;
    }
}