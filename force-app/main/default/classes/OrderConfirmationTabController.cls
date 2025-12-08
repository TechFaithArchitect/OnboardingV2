public without sharing class OrderConfirmationTabController {
    @AuraEnabled
    public static ResponseWrapper savePaymentAttempts(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            Decimal attemps = (Decimal) myData.get('attempts');
            Boolean paymentLimit = (Boolean) myData.get('setOpportunityPaymentLimit');

            Opportunity opp = new Opportunity(
                Id = oppId,
                POE_QuantityOfAttempts__c = attemps,
                POE_Payment_Limit_Reached__c = paymentLimit
            );

            update opp;

            Map<string, Object> result = new Map<String, Object>{ 'UpsertSuccess' => true };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveCart(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Decimal fee = (Decimal) myData.get('fee');
            string orderItemId = (String) myData.get('orderItemId');

            OrderItem oi = new OrderItem(UnitPrice = fee, Id = orderItemId);

            update oi;

            response.result = new Map<String, Object>{ 'UpsertSuccess' => true, 'Id' => oi.Id };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveCartSpectrum(List<Map<String, Object>> orderItemsData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            List<OrderItem> orderItemsToUpdate = new List<OrderItem>();

            for (Map<String, Object> orderItemData : orderItemsData) {
                OrderItem oi = new OrderItem();
                oi.Id = (Id) orderItemData.get('Id');
                oi.Quantity = (Decimal) orderItemData.get('Quantity');
                oi.POE_Status__c = (String) orderItemData.get('POE_Status__c');
                oi.UnitPrice = (Decimal) orderItemData.get('UnitPrice');

                orderItemsToUpdate.add(oi);
            }

            if (!orderItemsToUpdate.isEmpty()) {
                update orderItemsToUpdate;
            }

            response.result = new Map<String, Object>{
                'UpsertSuccess' => true,
                'UpdatedCount' => orderItemsToUpdate.size()
            };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveConfigurations(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            String orderId = (String) myData.get('orderId');
            List<Object> configurations = (List<Object>) myData.get('Configurations');

            List<POE_Order_Configurations__c> confsToInsert = new List<POE_Order_Configurations__c>();

            for (Object conf : configurations) {
                Map<Object, Object> mapConf = (Map<Object, Object>) conf;
                String name = (String) mapConf.get('name');
                String fee = (String) mapConf.get('fee');
                String type = (String) mapConf.get('type');

                POE_Order_Configurations__c orderConf = new POE_Order_Configurations__c(
                    Order__c = orderId,
                    Amount__c = Decimal.valueOf(fee),
                    Name = name != null && name.length() > 80 ? name.substring(0, 80) : name,
                    Fee_Type__c = type
                );

                confsToInsert.add(orderConf);
            }

            insert confsToInsert;

            response.result = new Map<String, Object>{ 'UpsertSuccess' => true };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper updateWorkOrderId(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            String orderId = (String) myData.get('orderId');
            String internalWorkOrderId = (String) myData.get('internalWorkOrderId');

            Order orderToUpdate = new Order(Id = orderId, POE_OrderId__c = internalWorkOrderId);

            update orderToUpdate;

            response.result = new Map<String, Object>{ 'UpsertSuccess' => true };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper sendElectronicSummary(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String email = (String) myData.get('email');
            String body = (String) myData.get('body');
            String serviceType = (String) myData.get('serviceType');
            body = body == null ? '' : body;
            serviceType = serviceType == null ? '' : serviceType;

            OrgWideEmailAddress orgWideEmail = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = 'no-reply@chuzo.com'
            ];
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setOrgWideEmailAddressId(orgWideEmail.Id);
            emailMessage.setToAddresses(new List<String>{ email });
            emailMessage.setSubject(
                System.Label.POE_DirecTV_ENGA_Electronic_Summary_Subject.replace('{SERVICE_TYPE}', serviceType)
            );
            emailMessage.setHtmlBody(body);

            Messaging.SendEmailResult emailResult = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ emailMessage }
            )[0];

            response.result = new Map<String, Object>{ 'error' => !emailResult.isSuccess() };
            if (!emailResult.isSuccess()) {
                response.result.put('errorMessage', emailResult.getErrors()[0].getMessage());
            }

            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveReferralData(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            String referralOption = (String) myData.get('referralOption');
            String referralDetail = (String) myData.get('referralDetail');

            Opportunity opp = new Opportunity(
                Id = oppId,
                Referral_Detail__c = referralDetail,
                Referral_Option__c = referralOption
            );

            update opp;

            response.result = new Map<String, Object>{ 'UpsertSuccess' => true };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getDealerAccountName() {
        try {
            ResponseWrapper response = new ResponseWrapper();

            String userId = UserInfo.getUserId();

            User user = [SELECT Id, Account.Name, Username FROM User WHERE Id = :userId LIMIT 1];

            response.result = new Map<String, Object>{
                'dealerName' => user.Account?.Name != null ? user.Account.Name : '',
                'agentId' => user.UserName
            };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper updateOrderItemsComponentAndPhone(
        Id orderId,
        List<Map<String, Object>> items,
        String apiResponse
    ) {
        ResponseWrapper response = new ResponseWrapper();
        try {
            // Build map from productCode to item
            Map<String, Map<String, Object>> codeToItem = new Map<String, Map<String, Object>>();
            for (Map<String, Object> item : items) {
                String code = (String) item.get('productCode');
                if (!String.isBlank(code)) {
                    codeToItem.put(code, item);
                }
            }
            // Query all OrderItems for the order, including Product2.ProductCode
            List<OrderItem> orderItems = [
                SELECT Id, Product2Id, Product2.ProductCode, Component_Code__c, Telephone_Number__c, POE_Status__c
                FROM OrderItem
                WHERE OrderId = :orderId
            ];
            List<OrderItem> toUpdate = new List<OrderItem>();
            Set<Id> toDelete = new Set<Id>();
            for (OrderItem oi : orderItems) {
                String prodCode = oi.Product2 != null ? oi.Product2.ProductCode : null;
                Map<String, Object> item = null;

                if (prodCode != null) {
                    // First try exact match
                    item = codeToItem.get(prodCode);

                    // If no match found and product code starts with 'GOF_', try matching without the prefix
                    if (item == null && prodCode.startsWith('GOF_')) {
                        String prodCodeWithoutPrefix = prodCode.substring(4); // Remove 'GOF_' prefix
                        item = codeToItem.get(prodCodeWithoutPrefix);
                    }
                }

                if (item != null) {
                    String componentCode = (String) item.get('componentCode');
                    oi.Component_Code__c = componentCode;
                    Object phoneObj = item.get('phone');
                    if (phoneObj != null) {
                        // Accept both String and Number
                        String phoneStr = String.valueOf(phoneObj);
                        if (!String.isBlank(phoneStr)) {
                            oi.Telephone_Number__c = phoneStr;
                        }
                    }
                    oi.POE_Status__c = 'Pending Installation';
                    toUpdate.add(oi);
                }
            }
            if (!toUpdate.isEmpty())
                update toUpdate;
            // Delete OrderItems with no Component_Code__c
            List<OrderItem> refreshedOrderItems = [
                SELECT Id, Component_Code__c
                FROM OrderItem
                WHERE OrderId = :orderId
            ];
            List<OrderItem> toDeleteList = new List<OrderItem>();
            for (OrderItem oi : refreshedOrderItems) {
                if (String.isBlank(oi.Component_Code__c)) {
                    toDeleteList.add(oi);
                }
            }
            Integer deletedCount = 0;
            if (!toDeleteList.isEmpty()) {
                delete toDeleteList;
                deletedCount = toDeleteList.size();
            }

            if (String.isNotBlank(apiResponse)) {
                Order orderToUpdate = new Order(Id = orderId, Order_Submission_Log__c = apiResponse);
                update orderToUpdate;
            }

            response.result = new Map<String, Object>{
                'updatedCount' => toUpdate.size(),
                'deletedCount' => deletedCount
            };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper updateE911TermsSent(String recordId) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            Opportunity opp = new Opportunity(Id = recordId, Frontier_911_Terms_Sent__c = true);

            update opp;

            response.result = new Map<String, Object>{ 'UpsertSuccess' => true };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}