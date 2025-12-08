public with sharing class BrightspeedOrderStatusAction {
    public class OrderStatusRequest {
        public String partnerId;
        public String status;
        public String salesCode;
        public String orderNumber;
        public String startDate;
        public String endDate;
        public Integer page;
        public Integer size;
    }

    public class OrderStatusResponse {
        public String orderCount;
        public List<OrderAndCustomerInformationContainer> partnerOrderStatus;
    }

    public class OrderAndCustomerInformationContainer {
        public List<OrderAndCustomerInformation> orderDetailAndCustomerInfo;
    }

    public class OrderAndCustomerInformation {
        public String partnerOrderId;
        public String partnerReferenceId;
        public String partnerId;
        public String salesCode;
        public String agentId;
        public String ACSID;
        public String TFN;
        public CustomerInfo customerInfo;
        public OrderStatusInformation order;
    }

    public class CustomerInfo {
        public String customerName;
        public String contactNumber;
        public String emailAddress;
        public ServiceAddress serviceAddress;
    }

    public class ServiceAddress {
        public String streetAddress;
        public String unit;
        public String city;
        public String stateCode;
        public String zipCode;
    }

    public class OrderItemInformation {
        public String productName;
        public String productFamilyName;
        public String compCode;
        public String status;
    }

    public class OrderStatusInformation {
        public String orderStatus;
        public String orderNumber;
        public String actualInstallationDate;
        public String orderStatusDate;
        public List<OrderItemInformation> orderLineItems;
    }

    public static OrderStatusResponse callPartnerOrderDetails(OrderStatusRequest request) {
        Map<String, Object> inputMap = new Map<String, Object>{
            'path' => 'orderStatus',
            'partnerName' => 'brightspeed',
            'orderDetailRequest' => request
        };
        System.debug('Input Map for callout: ' + JSON.serialize(inputMap));
        String responseBody = POE_ProvidersApexCallout.callEndpoint(inputMap);
        System.debug('Raw API Response: ' + responseBody);
        OrderStatusResponse resp;
        if (String.isNotBlank(responseBody)) {
            try {
                resp = (OrderStatusResponse) JSON.deserialize(responseBody, OrderStatusResponse.class);
                if (resp == null || resp.orderCount == null) {
                    List<OrderStatusResponse> respList = (List<OrderStatusResponse>) JSON.deserialize(
                        responseBody,
                        List<OrderStatusResponse>.class
                    );
                    System.debug('Deserialized as list: ' + JSON.serialize(respList));
                    if (!respList.isEmpty()) {
                        resp = respList[0];
                        System.debug('Using first element from list: ' + JSON.serialize(resp));
                    }
                }
                System.debug('Final orderCount: ' + (resp != null ? resp.orderCount : 'null'));
            } catch (Exception e) {
                System.debug('ERROR deserializing response: ' + e.getMessage());
            }
        } else {
            System.debug('WARNING: Empty response body from API');
        }
        System.debug('=== BrightspeedOrderStatusAction.callPartnerOrderDetails END ===');
        return resp;
    }

    @InvocableMethod
    public static void startOrderStatusSync(List<Integer> daysAgoList) {
        try {
            Integer daysAgo = daysAgoList[0]; // Get the first value from the list
            Date today = Date.today();
            Date startDate = today.addDays(-daysAgo);

            OrderStatusRequest req = new OrderStatusRequest();
            req.partnerId = Chuzo_Settings__c.getOrgDefaults().Brightspeed_Partner_ID__c;
            req.startDate = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)).format('MM-dd-yyyy'); //SETEAR CRITERIO
            req.endDate = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0)).format('MM-dd-yyyy'); //SETEAR CRITERIO
            req.page = 0;
            req.size = 50;
            req.status = '';
            req.salesCode = '';
            req.orderNumber = '';
            System.enqueueJob(new BrightspeedOrderStatusQueueable(req));
        } catch (Exception e) {
            System.debug('ERROR in startOrderStatusSync: ' + e.getMessage());
        }
    }
}