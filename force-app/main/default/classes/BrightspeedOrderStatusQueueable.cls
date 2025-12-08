// Updated version - Force recompilation
public with sharing class BrightspeedOrderStatusQueueable implements Queueable, Database.AllowsCallouts {
    private BrightspeedOrderStatusAction.OrderStatusRequest orderStatusRequest;

    public BrightspeedOrderStatusQueueable(BrightspeedOrderStatusAction.OrderStatusRequest orderStatusRequest) {
        this.orderStatusRequest = orderStatusRequest;
    }

    public void execute(QueueableContext context) {
        try {
            // Call API
            BrightspeedOrderStatusAction.OrderStatusResponse resp = BrightspeedOrderStatusAction.callPartnerOrderDetails(
                orderStatusRequest
            );
            if (resp == null || resp.partnerOrderStatus == null || resp.partnerOrderStatus.isEmpty()) {
                return;
            }

            // Status mappings
            Map<String, String> orderStatusMap = new Map<String, String>{
                'Completed' => 'Activated',
                'Active' => 'Activated',
                'Inactive' => 'Canceled',
                'Canceled' => 'Canceled',
                'Fallout' => 'Canceled',
                'In Progress' => 'Pending Installation',
                'Installation pending' => 'Pending Installation',
                'On Hold' => 'Pending/Held',
                'OnHold' => 'Pending/Held'
            };
            // Process API data
            Set<String> orderNumbersToUpdate = new Set<String>();
            Map<String, Map<String, String>> orderNumberToFields = new Map<String, Map<String, String>>();
            Map<String, List<BrightspeedOrderStatusAction.OrderItemInformation>> orderNumberToLineItems = new Map<String, List<BrightspeedOrderStatusAction.OrderItemInformation>>();
            Map<String, BrightspeedOrderStatusAction.OrderAndCustomerInformation> orderNumberToApiObject = new Map<String, BrightspeedOrderStatusAction.OrderAndCustomerInformation>();

            for (
                BrightspeedOrderStatusAction.OrderAndCustomerInformationContainer container : resp.partnerOrderStatus
            ) {
                if (container.orderDetailAndCustomerInfo != null) {
                    for (
                        BrightspeedOrderStatusAction.OrderAndCustomerInformation info : container.orderDetailAndCustomerInfo
                    ) {
                        if (info.order != null && info.order.orderNumber != null) {
                            orderNumbersToUpdate.add(info.order.orderNumber);
                            orderNumberToApiObject.put(info.order.orderNumber, info);

                            String mappedStatus = orderStatusMap.get(info.order.orderStatus);
                            Map<String, String> fields = new Map<String, String>();
                            fields.put('Status', mappedStatus);
                            fields.put('InstallDate', info.order.actualInstallationDate);
                            if (mappedStatus == 'Canceled') {
                                fields.put('DisconnectDate', info.order.orderStatusDate);
                            }
                            orderNumberToFields.put(info.order.orderNumber, fields);

                            // Process line items
                            if (info.order.orderLineItems != null) {
                                List<BrightspeedOrderStatusAction.OrderItemInformation> validLineItems = new List<BrightspeedOrderStatusAction.OrderItemInformation>();
                                for (
                                    BrightspeedOrderStatusAction.OrderItemInformation oli : info.order.orderLineItems
                                ) {
                                    if (String.isNotBlank(oli.compCode)) {
                                        validLineItems.add(oli);
                                        System.debug(
                                            'Added line item with compCode: ' +
                                            oli.compCode +
                                            ' for order: ' +
                                            info.order.orderNumber
                                        );
                                    }
                                }
                                if (!validLineItems.isEmpty()) {
                                    orderNumberToLineItems.put(info.order.orderNumber, validLineItems);
                                }
                            }
                        }
                    }
                }
            }

            // Update orders and order items
            if (!orderNumbersToUpdate.isEmpty()) {
                updateOrdersAndItems(
                    orderNumbersToUpdate,
                    orderNumberToFields,
                    orderNumberToLineItems,
                    orderStatusMap,
                    orderNumberToApiObject
                );
            }

            // Pagination logic
            handlePagination(resp);
        } catch (Exception e) {
            System.debug('ERROR in BrightspeedOrderStatusQueueable.execute: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }

    private void updateOrdersAndItems(
        Set<String> orderNumbersToUpdate,
        Map<String, Map<String, String>> orderNumberToFields,
        Map<String, List<BrightspeedOrderStatusAction.OrderItemInformation>> orderNumberToLineItems,
        Map<String, String> orderStatusMap,
        Map<String, BrightspeedOrderStatusAction.OrderAndCustomerInformation> orderNumberToApiObject
    ) {
        // Query orders with their order items
        List<Order> ordersWithItems = [
            SELECT
                Id,
                OrderNumber,
                Status,
                POE_InstallationDate__c,
                POE_OrderNumber__c,
                Cancel_Date__c,
                (SELECT Id, POE_Status__c, component_code__c FROM OrderItems)
            FROM Order
            WHERE POE_OrderNumber__c IN :orderNumbersToUpdate
        ];

        List<Order> ordersToUpdate = new List<Order>();
        List<OrderItem> itemsToUpdate = new List<OrderItem>();
        Set<Id> itemsToUpdateIds = new Set<Id>();
        Set<String> foundOrderNumbers = new Set<String>();

        for (Order o : ordersWithItems) {
            foundOrderNumbers.add(o.POE_OrderNumber__c);
            Map<String, String> fields = orderNumberToFields.get(o.POE_OrderNumber__c);

            if (fields != null) {
                Boolean updated = updateOrderFields(o, fields);
                if (updated) {
                    ordersToUpdate.add(o);
                }
                List<BrightspeedOrderStatusAction.OrderItemInformation> apiLineItems = orderNumberToLineItems.get(
                    o.POE_OrderNumber__c
                );
                if (apiLineItems != null) {
                    updateOrderItems(o, apiLineItems, itemsToUpdate, itemsToUpdateIds, orderStatusMap);
                }
            }
        }

        // Perform updates
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }

        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
    }

    private Boolean updateOrderFields(Order o, Map<String, String> fields) {
        Boolean updated = false;
        String newStatus = fields.get('Status');
        if (String.isNotBlank(newStatus) && o.Status != newStatus) {
            o.Status = newStatus;
            updated = true;
        }

        String newInstallDate = fields.get('InstallDate');
        if (String.isNotBlank(newInstallDate) && o.POE_InstallationDate__c != parseDate(newInstallDate)) {
            o.POE_InstallationDate__c = parseDate(newInstallDate);
            updated = true;
        }

        String newDisconnectDate = fields.get('DisconnectDate');
        if (String.isNotBlank(newDisconnectDate) && o.Cancel_Date__c != parseDate(newDisconnectDate)) {
            o.Cancel_Date__c = parseDate(newDisconnectDate);
            updated = true;
        }
        return updated;
    }

    private void updateOrderItems(
        Order o,
        List<BrightspeedOrderStatusAction.OrderItemInformation> apiLineItems,
        List<OrderItem> itemsToUpdate,
        Set<Id> itemsToUpdateIds,
        Map<String, String> orderStatusMap
    ) {
        for (BrightspeedOrderStatusAction.OrderItemInformation apiItem : apiLineItems) {
            String apiCompCode = apiItem.compCode;
            String apiStatus = apiItem.status;

            for (OrderItem sfItem : o.OrderItems) {
                if (sfItem.component_code__c == apiCompCode && !itemsToUpdateIds.contains(sfItem.Id)) {
                    String mappedItemStatus = orderStatusMap.get(apiStatus);
                    if (String.isNotBlank(mappedItemStatus) && mappedItemStatus != sfItem.POE_Status__c) {
                        sfItem.POE_Status__c = mappedItemStatus;
                        itemsToUpdate.add(sfItem);
                        itemsToUpdateIds.add(sfItem.Id);
                    }
                }
            }
        }
    }

    private Date parseDate(String dateStr) {
        if (String.isNotBlank(dateStr)) {
            List<String> dateParts = dateStr.split('/');
            if (dateParts.size() == 3) {
                Integer month = Integer.valueOf(dateParts[0]);
                Integer day = Integer.valueOf(dateParts[1]);
                Integer year = Integer.valueOf(dateParts[2]);
                return Date.newInstance(year, month, day);
            }
        }
        return null;
    }

    private void handlePagination(BrightspeedOrderStatusAction.OrderStatusResponse resp) {
        Integer pageSize = orderStatusRequest.size != null ? orderStatusRequest.size : 10;
        if (resp.orderCount != null && String.isNotBlank(resp.orderCount)) {
            Integer totalCount = Integer.valueOf(resp.orderCount);

            if (totalCount >= pageSize) {
                BrightspeedOrderStatusAction.OrderStatusRequest nextReq = orderStatusRequest;
                nextReq.page = (orderStatusRequest.page != null ? orderStatusRequest.page : 0) + 1;
                System.enqueueJob(new BrightspeedOrderStatusQueueable(nextReq));
            }
        }
    }
}