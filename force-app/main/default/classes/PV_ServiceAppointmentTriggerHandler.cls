public class PV_ServiceAppointmentTriggerHandler {
    static String PvStandardTimeZone = Label.PVStandardTimeZone;
    public static final String BUSINESS_UNIT_DCC = 'Direct Connect Connections';

    public static void handleBeforeUpdate(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, ServiceAppointment> oldServiceAppointments
    ) {
        try {
            assignTerritoryBasedOnTechnician(serviceAppointments, oldServiceAppointments);
            serviceAppointments = assignDealerToAppointments(serviceAppointments, oldServiceAppointments);

            Set<String> territoryIds = new Set<String>();
            Map<String, String> territoryByAppointment = new Map<String, String>();

            for (ServiceAppointment sa : serviceAppointments) {
                territoryIds.add(sa.ServiceTerritoryId);
            }

            for (ServiceTerritory st : [
                SELECT  Id, OperatingHoursId, OperatingHours.TimeZone 
                FROM    ServiceTerritory 
                WHERE   Id IN :territoryIds]) {

                for (ServiceAppointment sa : serviceAppointments) {
                    if(sa.ServiceTerritoryId == st.Id) {
                        territoryByAppointment.put(sa.Id, st.OperatingHours.TimeZone);
                    }
                }
            }

            for (ServiceAppointment sa : serviceAppointments) {
                if (sa.Status == 'Scheduled' && sa.SchedStartTime != null) {
                    sa.DueDate = sa.SchedStartTime.Date().addYears(1);
                }

                if (sa.SchedStartTime != oldServiceAppointments.get(sa.Id).SchedStartTime) {
                    sa.Scheduled_Time__c = DateTime.now();
                    String strSTTZ = territoryByAppointment.get(sa.Id);
                    sa.ScheduledStartOnTimezone__c = String.valueOf(sa.SchedStartTime.format('yyyy-MM-dd HH:mm:ss', strSTTZ));
                }

                if (sa.ServiceTerritoryId != oldServiceAppointments.get(sa.Id).ServiceTerritoryId) {
                    String strSTTZ = territoryByAppointment.get(sa.Id);
                    sa.ScheduledStartOnTimezone__c = String.valueOf(sa.SchedStartTime.format('yyyy-MM-dd HH:mm:ss', strSTTZ));
                }
            }
        } catch (Exception ex) {
            ExceptionUtil.publishException(
                'PV_ServiceAppointmentTriggerHandler.handleBeforeUpdate',
                ex.getLineNumber(),
                ex.getMessage(),
                ex.getStackTraceString()
            );
        }
    }

    public static void assignTerritoryBasedOnTechnician(List<ServiceAppointment> newAppointments, Map<Id, ServiceAppointment> oldServiceAppointments) {
        Map<String, String> resourcePerAppointment = new Map<String, String>();
        Map<String, String> appointmentToParentTerritory = new Map<String, String>();

        for (ServiceAppointment sa : newAppointments) {
            if (oldServiceAppointments.get(sa.Id).FSSK__FSK_Assigned_Service_Resource__c == null
                    && sa.FSSK__FSK_Assigned_Service_Resource__c != null
                    && sa.ServiceTerritory.ParentTerritoryId == null) {
                resourcePerAppointment.put(sa.Id, sa.FSSK__FSK_Assigned_Service_Resource__c);
                appointmentToParentTerritory.put(sa.Id, sa.ServiceTerritoryId);
            }
        }
        
        if (!resourcePerAppointment.isEmpty()) {
            Map<String, String> matchingTerritoryMap = new Map<String, String>();
            for (ServiceTerritoryMember stm : [
                SELECT ServiceResourceId, Parent_Service_Territory__c, ServiceTerritoryId
                FROM ServiceTerritoryMember
                WHERE ServiceResourceId IN :resourcePerAppointment.values()
            ]) {
                String key = stm.ServiceResourceId + '-' + stm.Parent_Service_Territory__c;
                matchingTerritoryMap.put(key, stm.ServiceTerritoryId);
            }
            
            for (ServiceAppointment sa : newAppointments) {
                String resourceId = resourcePerAppointment.get(sa.Id);
                String parentTerritoryId = appointmentToParentTerritory.get(sa.Id);
                if (resourceId != null && parentTerritoryId != null) {
                    String key = resourceId + '-' + parentTerritoryId;
                    if (matchingTerritoryMap.containsKey(key)) {
                        sa.ServiceTerritoryId = matchingTerritoryMap.get(key);
                    }
                }
            }
        }
    }

    public static List<ServiceAppointment> assignDealerToAppointments(
        List<ServiceAppointment> appointments,
        Map<Id, ServiceAppointment> oldAppointments
    ) {
        Set<Id> serviceTerritoryIds = new Set<Id>();
        Set<Id> workOrderIds = new Set<Id>();
        for (ServiceAppointment sa : appointments) {
            if (sa.ServiceTerritoryId != null) {
                serviceTerritoryIds.add(sa.ServiceTerritoryId);
            }
            workOrderIds.add(sa.parentRecordId);
        }


        //PVFSL-472
        Map<Id, WorkOrder> workOrdersMap = new Map<Id, WorkOrder>([SELECT Id,
                                                                          WorkTypeId,
                                                                          WorkType.Vendor__c
                                                                   FROM WorkOrder
                                                                   WHERE Id IN :workOrderIds]);


        Map<Id, ServiceTerritory> serviceTerritoryMap = new Map<Id, ServiceTerritory>(
            [SELECT Id, Account__c, Account__r.Available_FSL_Vendors__c, Account__r.Name, OperatingHoursId, OperatingHours.TimeZone FROM ServiceTerritory WHERE Id IN :serviceTerritoryIds]
        );

        for (ServiceAppointment sa : appointments) {
            Boolean newTerritory =
                oldAppointments == null || (sa.ServiceTerritoryId != oldAppointments.get(sa.Id).ServiceTerritoryId);

            if (
                sa.ServiceTerritoryId != null &&
                newTerritory &&
                serviceTerritoryMap.containsKey(sa.ServiceTerritoryId)
            ) {
                if(serviceTerritoryMap.get(sa.ServiceTerritoryId).Account__c != null
                        && String.isNotBlank(serviceTerritoryMap.get(sa.ServiceTerritoryId).Account__r.Available_FSL_Vendors__c)
                        && String.isNotBlank(workOrdersMap.get(sa.parentRecordId).WorkType?.Vendor__c)) {
                    System.debug(serviceTerritoryMap.get(sa.ServiceTerritoryId).Account__r.Available_FSL_Vendors__c);
                    Boolean correctVendor = serviceTerritoryMap.get(sa.ServiceTerritoryId).Account__r.Available_FSL_Vendors__c.contains(workOrdersMap.get(sa.parentRecordId).WorkType.Vendor__c);
                    System.debug('correctVendor: ' + correctVendor);
                    if(correctVendor) {
                        sa.Dealer__c = serviceTerritoryMap.get(sa.ServiceTerritoryId).Account__c;
                    }
                }
            }
        }

        return appointments;
    }

    // Method To Update Address, Due date, Earlier Start Date Of Service Appointment
    public static void updateServiceApptFields(List<ServiceAppointment> serviceAppointmentList) {

        try {
            set<Id> saIds = new Set<Id>();
            set<Id> workTypesIds = new Set<Id>();
            List<String> emergencySchedulingWorkTypes = Label.PV_EmergencySchedulingWorkTypes.Split(',');

            Map<Id, ServiceAppointment> serviceAppointmentMap = new Map<Id, ServiceAppointment>([
                SELECT  Id, Dealer__r.Business_Unit__c
                FROM    ServiceAppointment
                WHERE   Id IN :serviceAppointmentList
            ]);

            for (ServiceAppointment sas : serviceAppointmentList) {
                saIds.add(sas.Id);
            }

            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> woIdSet = new Set<Id>();
            for (ServiceAppointment sa : serviceAppointmentList) {
                woIdSet.add(sa.parentRecordId);
            }

            List<WorkOrder> paWoList = [
                SELECT Id, AccountId, WorkType.Name, WorkType.Extended_Earliest_Date_in_days__c, Vendor__c, StartDate
                FROM WorkOrder
                WHERE Id IN :woIdSet
            ];
            Map<Id, WorkOrder> paWoMap = new Map<Id, WorkOrder>();

            for (WorkOrder wo : paWoList) {
                paWoMap.put(wo.Id, wo);
            }

            Map<Id, Id> serviceTerritoriesIdsWithWorkOrders = new Map<Id, Id>();
            Map<Id, ServiceTerritory> workOrdersWithServiceTerritories = new Map<Id, ServiceTerritory>();

            List<WorkOrder> woList = [
                SELECT
                    Id,
                    AccountId,
                    WorkTypeId,
                    ServiceTerritoryId,
                    Account.BillingStreet,
                    Account.BillingCity,
                    Account.BillingStateCode,
                    Account.BillingPostalCode,
                    Account.BillingCountryCode
                FROM WorkOrder
                WHERE Id IN :woIdSet AND Vendor__c != :Label.PV_TMobile
            ];
            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>();
            for (WorkOrder wo : woList) {
                woMap.put(wo.Id, wo);
                workTypesIds.add(wo.WorkTypeId);
                serviceTerritoriesIdsWithWorkOrders.put(wo.ServiceTerritoryId, wo.Id);
            }

            for(ServiceTerritory territory : [SELECT Id, OperatingHoursId, OperatingHours.TimeZone FROM ServiceTerritory WHERE Id IN: serviceTerritoriesIdsWithWorkOrders.keySet()]) {
                workOrdersWithServiceTerritories.put(serviceTerritoriesIdsWithWorkOrders.get(territory.Id), territory);
            }

            Map<Id, WorkType> saWorkTypeMap = new Map<Id, WorkType>([
                SELECT
                    Id,
                    Afternoon_Installation__c
                FROM WorkType
                WHERE Id IN :workTypesIds
            ]);

            for (ServiceAppointment sa : serviceAppointmentList) {
                for (Id woId : paWoMap.keySet()) {
                    sa.Vendor__c = paWoMap.get(woId).Vendor__c;
                    if (
                        sa.parentRecordId == woId &&
                        !emergencySchedulingWorkTypes.contains(paWoMap.get(woId).WorkType.Name)
                    ) {
                        earliestStartTimeAddDays(sa, paWoMap);
                    }
                }

                for (Id woId : woMap.keySet()) {
                    if (sa.parentRecordId == woId) {
                        sa.Street = woMap.get(woId).Account.BillingStreet;
                        sa.City = woMap.get(woId).Account.BillingCity;
                        sa.PostalCode = woMap.get(woId).Account.BillingPostalCode;
                        sa.CountryCode = woMap.get(woId).Account.BillingCountryCode;
                        sa.StateCode = woMap.get(woId).Account.BillingStateCode;
                    }
                }

                if (serviceAppointmentMap.containsKey(sa.Id) &&
                    serviceAppointmentMap.get(sa.Id).Dealer__r.Business_Unit__c == BUSINESS_UNIT_DCC &&
                    saWorkTypeMap.get(woMap.get(sa.parentRecordId).WorkTypeId).Afternoon_Installation__c) {
                        
                    TimeZone saTimezone = TimeZone.getTimeZone(workOrdersWithServiceTerritories.get(sa.parentRecordId).OperatingHours.TimeZone);
                    //get SA date
                    Date saEarliestStartDate = sa.EarliestStartTime.date();
                    //modify date with territory timezone for 1PM
                    DateTime newSaEarliestStart = Datetime.newInstanceGMT(saEarliestStartDate.year(), saEarliestStartDate.month(), saEarliestStartDate.day(), 11, 0, 0);
                    newSaEarliestStart = convertToTimeZone(newSaEarliestStart, saTimezone);
                    //update value
                    sa.EarliestStartTime = newSaEarliestStart;
                }
                else if (serviceAppointmentMap.containsKey(sa.Id) &&
                    serviceAppointmentMap.get(sa.Id).Dealer__r.Business_Unit__c == BUSINESS_UNIT_DCC &&
                    !saWorkTypeMap.get(woMap.get(sa.parentRecordId).WorkTypeId).Afternoon_Installation__c) {
                    
                    TimeZone saTimezone = TimeZone.getTimeZone(workOrdersWithServiceTerritories.get(sa.parentRecordId).OperatingHours.TimeZone);
                    //get SA date
                    Date saEarliestStartDate = sa.EarliestStartTime.date();
                    //modify date with territory timezone for 8AM
                    DateTime newSaEarliestStart = Datetime.newInstanceGMT(saEarliestStartDate.year(), saEarliestStartDate.month(), saEarliestStartDate.day(), 8, 0, 0);
                    newSaEarliestStart = convertToTimeZone(newSaEarliestStart, saTimezone);
                    //update value
                    sa.EarliestStartTime = newSaEarliestStart;
                }
            }
        } catch (Exception ex) {
            ExceptionUtil.publishException(
                'PV_ServiceAppointmentTriggerHandler.updateServiceApptFields',
                ex.getLineNumber(),
                ex.getMessage(),
                ex.getStackTraceString()
            );
        }
    }

    public static void inmediateScheduleAppointment(Map<Id, ServiceAppointment> newMap) {
        Set<Id> serviceTerritoryIds = new Set<Id>();
        List<Id> costcoAppointments = new List<Id>();
        
        for (ServiceAppointment sa : newMap.values()) {
            if (sa.ServiceTerritoryId != null) {
                serviceTerritoryIds.add(sa.ServiceTerritoryId);
            }
        }

        Map<Id, ServiceTerritory> serviceTerritoryMap = new Map<Id, ServiceTerritory>(
            [SELECT Id, Account__c, Account__r.Business_Unit__c, Account__r.Name, OperatingHoursId, OperatingHours.TimeZone FROM ServiceTerritory WHERE Id IN :serviceTerritoryIds]
        );

        for (ServiceAppointment sa : newMap.values()) {
            if(
                sa.ServiceTerritoryId != null &&
                serviceTerritoryMap.containsKey(sa.ServiceTerritoryId) && 
                sa.Dealer__c != null && 
                serviceTerritoryMap.get(sa.ServiceTerritoryId).Account__r.Business_Unit__c == BUSINESS_UNIT_DCC
            ) {
                costcoAppointments.add(sa.Id);
            }
        }

        if (costcoAppointments.size() > 0) {
            System.enqueueJob(new FSL_ScheduleCostcoAppointmentsQueueable(costcoAppointments, serviceTerritoryMap));
        }
    }

    // Method to add extended days to earliest start time based on Work Type
    public static void earliestStartTimeAddDays(ServiceAppointment sa, Map<Id, WorkOrder> extendedEarliestMap) {
        if (
            extendedEarliestMap.containsKey(sa.parentRecordId) &&
            extendedEarliestMap.get(sa.parentRecordId).WorkType != null &&
            extendedEarliestMap.get(sa.parentRecordId).WorkType.Extended_Earliest_Date_in_days__c != null
        ) {
            DateTime earliestStartTime = convertTimeZone(
                System.now()
                    .addDays(
                        Integer.valueOf(
                            extendedEarliestMap.get(sa.parentRecordId).WorkType.Extended_Earliest_Date_in_days__c
                        )
                    ),
                UserInfo.getTimeZone().getID(),
                PvStandardTimeZone
            );

            earliestStartTime = DateTime.newInstance(earliestStartTime.date(), Time.newInstance(0, 0, 0, 0));
            DateTime orderStartTime = extendedEarliestMap.get(sa.parentRecordId).StartDate;
            sa.EarliestStartTime = orderStartTime > earliestStartTime ? orderStartTime : earliestStartTime;
            DateTime dueDate = convertTimeZone(
                System.now()
                    .addDays(
                        Integer.valueOf(
                            extendedEarliestMap.get(sa.parentRecordId).WorkType.Extended_Earliest_Date_in_days__c
                        )
                    ),
                UserInfo.getTimeZone().getID(),
                PvStandardTimeZone
            ).addYears(1);

            dueDate = DateTime.newInstance(dueDate.date(), Time.newInstance(0, 0, 0, 0));
            DateTime orderDueDate = extendedEarliestMap.get(sa.parentRecordId).StartDate.addYears(1);
            sa.DueDate = orderDueDate > dueDate ? orderDueDate : dueDate;
        } else if(extendedEarliestMap.containsKey(sa.parentRecordId)) {
            DateTime earliestStartTime = convertTimeZone(
                System.now().addDays(1),
                UserInfo.getTimeZone().getID(),
                PvStandardTimeZone
            );

            earliestStartTime = DateTime.newInstance(earliestStartTime.date(), Time.newInstance(0, 0, 0, 0));
            DateTime orderStartTime = extendedEarliestMap.get(sa.parentRecordId).StartDate;
            sa.EarliestStartTime = orderStartTime > earliestStartTime ? orderStartTime : earliestStartTime;

            DateTime dueDate = convertTimeZone(
                System.now().addDays(1),
                    UserInfo.getTimeZone().getID(),
                    PvStandardTimeZone
                )
                .addYears(1);
            
            dueDate = DateTime.newInstance(dueDate.date(), Time.newInstance(0, 0, 0, 0));
            DateTime orderDueDate = extendedEarliestMap.get(sa.parentRecordId).StartDate.addYears(1);
            sa.DueDate = orderDueDate > dueDate ? orderDueDate : dueDate;
        }
        else {
            DateTime earliestStartTime = convertTimeZone(
                System.now().addDays(1),
                UserInfo.getTimeZone().getID(),
                PvStandardTimeZone
            );
            sa.EarliestStartTime = DateTime.newInstance(earliestStartTime.date(), Time.newInstance(0, 0, 0, 0));

            DateTime dueDate = convertTimeZone(
                    System.now().addDays(1),
                    UserInfo.getTimeZone().getID(),
                    PvStandardTimeZone
                )
                .addYears(1);
            sa.DueDate = DateTime.newInstance(dueDate.date(), Time.newInstance(0, 0, 0, 0));
        }
    }

    // Used to convert time zone into PDT
    public static DateTime convertTimeZone(DateTime dt, String fromTimeZone, String toTimeZone) {
        return dt.addSeconds(
            (TimeZone.getTimeZone(toTimeZone).getOffset(dt) - TimeZone.getTimeZone(fromTimeZone).getOffset(dt)) / 1000
        );
    }

    // Method to Update Work Order status and dealer in WO corresponding to ServiceAppointment whenever record is updated or created
    public static void updateRelatedWorkOrder(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {
        Set<Id> workOrderIds = new Set<Id>();
        Map<String, ServiceAppointment> objMap = new Map<String, ServiceAppointment>();
        try {
            for (ServiceAppointment serviceApptId : newMap.values()) {
                if (
                    oldMap == null ||
                    (oldMap.get(serviceApptId.Id).Status != newMap.get(serviceApptId.Id).Status) ||
                    (oldMap.get(serviceApptId.Id).Dealer__c != newMap.get(serviceApptId.Id).Dealer__c)
                ) {
                    workOrderIds.add(serviceApptId.ParentRecordId);
                    objMap.put(serviceApptId.ParentRecordId, serviceApptId);
                }
            }
            List<WorkOrder> workOrdersToUpdate = [
                SELECT Id, Status, Dealer__c
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ];
            List<WorkOrder> workOrdersToUpdateStatus = new List<WorkOrder>();
            for (WorkOrder workOrderUpdate : workOrdersToUpdate) {
                workOrderUpdate.Status = objMap.get(workOrderUpdate.Id).Status;
                workOrderUpdate.Dealer__c = objMap.get(workOrderUpdate.Id).Dealer__c;
                workOrdersToUpdateStatus.add(workOrderUpdate);
                if (objMap.get(workOrderUpdate.Id).Status == 'Complete') {
                    workOrderUpdate.Work_Type_Code_tmo__c = objMap.get(workOrderUpdate.Id).Work_Type_Code_tmo__c;
                }
            }

            if (!workOrdersToUpdateStatus.isEmpty()) {
                update workOrdersToUpdateStatus;
            }
        } catch (Exception ex) {
            ExceptionUtil.publishException(
                'PV_ServiceAppointmentTriggerHandler.updateRelatedWorkOrder',
                ex.getLineNumber(),
                ex.getMessage(),
                ex.getStackTraceString()
            );
        }
    }
    //Method to update Status of Service Appointments
    public static void handleStatusUpdate(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {
        try {
            Set<Date> updatedDates = new Set<Date>();
            Set<Id> srIds = new Set<Id>();
            for (ServiceAppointment appointment : newMap.values()) {
                ServiceAppointment oldAppointment = oldMap.get(appointment.Id);
                if (appointment.Status == 'Acknowledge' && oldAppointment.Status != 'Acknowledge') {
                    DateTime dT = appointment.SchedStartTime;
                    Date d = Date.newInstance(dT.year(), dT.month(), dT.day());
                    updatedDates.add(d);
                    srIds.add(appointment.FSSK__FSK_Assigned_Service_Resource__c);
                }
            }
            List<ServiceAppointment> appointmentsToUpdate = [
                SELECT Id, Status, SchedStartTime, FSSK__FSK_Assigned_Service_Resource__c
                FROM ServiceAppointment
                WHERE
                    DAY_ONLY(SchedStartTime) IN :updatedDates
                    AND Status = 'Dispatched'
                    AND FSSK__FSK_Assigned_Service_Resource__c IN :srIds
                    AND SchedStartTime != NULL
            ];
            for (ServiceAppointment appointment : appointmentsToUpdate) {
                appointment.Status = 'Acknowledge';
            }
            if (!appointmentsToUpdate.isEmpty()) {
                update appointmentsToUpdate;
            }
        } catch (Exception ex) {
            ExceptionUtil.publishException(
                'PV_ServiceAppointmentTriggerHandler.handleStatusUpdate',
                ex.getLineNumber(),
                ex.getMessage(),
                ex.getStackTraceString()
            );
        }
    }

    public static void immediateDealerAssignment(List<ServiceAppointment> serviceAppointments) {
        Map<Id, ServiceAppointment> serviceAppointementByWorkOrderId = new Map<Id, ServiceAppointment>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointementByWorkOrderId.put(serviceAppointment.ParentRecordId, serviceAppointment);
        }

        List<WorkOrder> workOrders = [
            SELECT Id, Assign_to_Dealer_Immediately__c, ServiceTerritoryId, WorkTypeId, WorkType.Vendor__c
            FROM WorkOrder
            WHERE Id IN :serviceAppointementByWorkOrderId.keySet()
        ];

        FSL_Settings__c settings = FSL_Settings__c.getOrgDefaults();
        Integer Availability_Period = 0;
        if (settings.Availability_Period__c != null) {
            Availability_Period = Integer.valueOf(settings.Availability_Period__c) > 0
                ? Integer.valueOf(settings.Availability_Period__c)
                : 7;
        } else {
            Availability_Period = 7;
        }

        Date Availability_Period_Date = date.today().addDays(Availability_Period);

        Map<String, String> typePerWO = new Map<String, String>();
        Map<String, Set<String>> DealersTerritories = new Map<String, Set<String>>();
        Map<String, Set<String>> territoriesPerParent = new Map<String, Set<String>>();
        Map<String, Set<String>> skillsPerWO = new Map<String, Set<String>>();
        Map<String, Set<String>> resourcesPerDealer = new Map<String, Set<String>>();
        Map<String, Set<String>> skillsPerResource = new Map<String, Set<String>>();
        Map<String, String> ChildTerritoriesAndDealers = new Map<String, String>();
        Map<Id, String> workTypeVendorPerWO = new Map<Id, String>();
        Map<Id, String> vendorsPerDealer = new Map<Id, String>();

        Map<String, ShiftWrapper> shiftsPerResource = new Map<String, ShiftWrapper>();
        Map<String, AppointmentWrapper> appointmentsPerResource = new Map<String, AppointmentWrapper>();

        //Iterates new work orders to get data needed for quering relevant records (workTypes, Skills and territories)
        for (WorkOrder order : workOrders) {
            if (order.Assign_to_Dealer_Immediately__c) {
                if (order.ServiceTerritoryId != null) {
                    territoriesPerParent.put(order.ServiceTerritoryId, new Set<String>());
                }
                skillsPerWO.put(order.Id, new Set<String>());
                typePerWO.put(order.WorkTypeId, order.Id);
                if (order.WorkTypeId != null && order.WorkType.Vendor__c != null) {
                    workTypeVendorPerWO.put(order.Id, order.WorkType.Vendor__c);
                }
                else {
                    workTypeVendorPerWO.put(order.Id, '');
                }
            }
        }

        //Queries and group the skills required for each work order
        for (SkillRequirement skill : [
            SELECT Id, SkillId, RelatedRecordId
            FROM SkillRequirement
            WHERE RelatedRecordId IN :typePerWO.keySet()
        ]) {
            skillsPerWO.get(typePerWO.get(skill.RelatedRecordId)).add(skill.SkillId);
        }

        //Queries and group all child territories with the correspondant dealers
        for (ServiceTerritory territory : [
            SELECT Id, Account__c, Account__r.Available_FSL_Vendors__c, ParentTerritoryId
            FROM ServiceTerritory
            WHERE ParentTerritoryId IN :territoriesPerParent.keySet() AND IsActive = TRUE
        ]) {
            territoriesPerParent.get(territory.ParentTerritoryId).add(territory.Id);
            if (!DealersTerritories.keySet().contains(territory.Account__c)) {
                DealersTerritories.put(territory.Account__c, new Set<String>());
            }
            DealersTerritories.get(territory.Account__c).add(territory.Id);
            ChildTerritoriesAndDealers.put(territory.Id, territory.Account__c);
            if(territory.Account__c != null && String.isNotBlank(territory.Account__r.Available_FSL_Vendors__c)){
                vendorsPerDealer.put(territory.Account__c, territory.Account__r.Available_FSL_Vendors__c);
            }
        }

        //Queries and group all service resources with the correspondant dealers
        for (ServiceResource resource : [
            SELECT id, Name, AccountId
            FROM ServiceResource
            WHERE AccountId IN :DealersTerritories.keySet() AND IsActive = TRUE
        ]) {
            if (!resourcesPerDealer.keySet().contains(resource.AccountId)) {
                resourcesPerDealer.put(resource.AccountId, new Set<String>());
            }
            resourcesPerDealer.get(resource.AccountId).add(resource.Id);
            skillsPerResource.put(resource.Id, new Set<String>());
        }

        ////Queries and group all service resource skills with the correspondant service resource
        for (ServiceResourceSkill skill : [
            SELECT Id, ServiceResourceId, SkillId
            FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :skillsPerResource.keySet()
        ]) {
            skillsPerResource.get(skill.ServiceResourceId).add(skill.SkillId);
        }

        //Queries and group all shifts with its correspondant service resource and calculates the sum of shift hours between today and the availability period
        for (Shift shift : [
            SELECT Id, StartTime, EndTime, ServiceResourceId
            FROM Shift
            WHERE StartTime >= TODAY AND Status = 'Confirmed' AND ServiceResourceId IN :skillsPerResource.keySet()
        ]) {
            if (shift.StartTime.date() <= Availability_Period_Date) {
                if (!shiftsPerResource.keySet().contains(shift.ServiceResourceId)) {
                    ShiftWrapper newWrapper = new ShiftWrapper();
                    newWrapper.shiftList = new List<Shift>();
                    newWrapper.hours = 0;
                    shiftsPerResource.put(shift.ServiceResourceId, newWrapper);
                }

                Long difference = shift.EndTime.getTime() - shift.StartTime.getTime();
                Integer hours = Integer.ValueOf(difference / 3600000);

                shiftsPerResource.get(shift.ServiceResourceId).hours =
                    shiftsPerResource.get(shift.ServiceResourceId).hours + hours;
                shiftsPerResource.get(shift.ServiceResourceId).shiftList.add(shift);
            }
        }

        //Queries and group all service appointments with its correspondant service resource and calculates the sum of service appointment hours between today and the availability period
        for (ServiceAppointment appointment : [
            SELECT id, FSSK__FSK_Assigned_Service_Resource__c, SchedEndTime, SchedStartTime
            FROM ServiceAppointment
            WHERE
                FSSK__FSK_Assigned_Service_Resource__c IN :skillsPerResource.keySet()
                AND SchedStartTime >= TODAY
                AND Status = 'Scheduled'
        ]) {
            if (appointment.SchedStartTime.date() <= Availability_Period_Date) {
                if (!appointmentsPerResource.keySet().contains(appointment.FSSK__FSK_Assigned_Service_Resource__c)) {
                    AppointmentWrapper newWrapper = new AppointmentWrapper();
                    newWrapper.appointmentList = new List<ServiceAppointment>();
                    newWrapper.hours = 0;
                    appointmentsPerResource.put(appointment.FSSK__FSK_Assigned_Service_Resource__c, newWrapper);
                }

                Long difference = appointment.SchedEndTime.getTime() - appointment.SchedStartTime.getTime();
                Integer hours = Integer.ValueOf(difference / 3600000);

                appointmentsPerResource.get(appointment.FSSK__FSK_Assigned_Service_Resource__c).hours =
                    appointmentsPerResource.get(appointment.FSSK__FSK_Assigned_Service_Resource__c).hours + hours;
                appointmentsPerResource.get(appointment.FSSK__FSK_Assigned_Service_Resource__c)
                    .appointmentList.add(appointment);
            }
        }

        //for each work order, calculates the availability balance per dealer depending on territory and skills required, and updates the dealer__c value to the most adequate dealer
        for (WorkOrder order : workOrders) {
            if (order.Assign_to_Dealer_Immediately__c && order.ServiceTerritoryId != null) {
                double bestBalance = 0;
                String winningDealer = null;

                Integer shiftsHours = 0;
                Integer appointmentHours = 0;
                Integer numberOfResources = 0;
                Set<String> childTerrirtories = territoriesPerParent.get(order.ServiceTerritoryId);
                Set<String> possibleDealers = new Set<String>();
                Set<String> possibleResources = new Set<String>();
                String workTypeVendor = workTypeVendorPerWO.get(order.Id);
                for (String territoryId : childTerrirtories) {
                    possibleDealers.add(ChildTerritoriesAndDealers.get(territoryId));
                }
                for (String resourceId : skillsPerResource.keySet()) {
                    if (skillsPerResource.get(resourceId).containsAll(skillsPerWO.get(order.Id))) {
                        possibleResources.add(resourceId);
                    }
                }

                for (String dealerId : possibleDealers) {
                    if(vendorsPerDealer.get(dealerId) != null && vendorsPerDealer.get(dealerId).contains(workTypeVendor)){
                        Double balance = 0;
                        Set<String> DealerResourcesIds = resourcesPerDealer.get(dealerId);
                        if (DealerResourcesIds != null) {
                            for (String resourceId : DealerResourcesIds) {
                                if (possibleResources.contains(resourceId)) {
                                    numberOfResources++;
                                    if (shiftsPerResource.get(resourceId) != null) {
                                        shiftsHours = shiftsHours + shiftsPerResource.get(resourceId).hours;
                                    }
                                    if (appointmentsPerResource.get(resourceId) != null) {
                                        appointmentHours = appointmentHours + appointmentsPerResource.get(resourceId).hours;
                                    }
                                }
                            }

                            if (numberOfResources > 0) {
                                balance = (shiftsHours - appointmentHours) / numberOfResources;
                            }
                            if (balance > bestBalance) {
                                bestBalance = balance;
                                winningDealer = dealerId;
                            }
                        }
                    }
                }

                if (winningDealer != null) {
                    System.debug('winningDealer ' + winningDealer);
                    for (String childTerritoryId : ChildTerritoriesAndDealers.keySet()) {
                        if (ChildTerritoriesAndDealers.get(childTerritoryId) == winningDealer) {
                            serviceAppointementByWorkOrderId.get(order.Id).ServiceTerritoryId = childTerritoryId;
                            System.debug('childTerritoryId ' + childTerritoryId);
                            break;
                        }
                    }
                    // order.Dealer__c = winningDealer;
                }
            }
        }
    }

    public static void handleFirstAvailableSlotStartTime(List<ServiceAppointment> newAppointments, Map<Id, ServiceAppointment> oldServiceAppointments) {
        Set<Id> appointmentsIds = new Set<Id>();

        Map<Id, ServiceAppointment> appointmentsMap = new Map<Id, ServiceAppointment>([
            SELECT
                Id,
                ServiceTerritoryId,
                ServiceTerritory.ParentTerritoryId
            FROM ServiceAppointment
            WHERE Id IN :newAppointments
        ]);
        for (ServiceAppointment appointment : newAppointments) {
            if (appointment.First_Available_Slot_Start_Time__c == null
                && (oldServiceAppointments == null && appointment.ServiceTerritoryId != null
                    || oldServiceAppointments != null
                        && appointmentsMap.get(appointment.Id).ServiceTerritory.ParentTerritoryId != null)) {
                appointmentsIds.add(appointment.Id);
            }
        }

        if (!appointmentsIds.isEmpty()) {
            if (System.isFuture() || System.isBatch()) {
                updateFirstAvailableSlotStartTime(appointmentsIds);
            } else {
                updateFirstAvailableSlotStartTimeFuture(appointmentsIds);
            }
        }
    }

    @future
    public static void updateFirstAvailableSlotStartTimeFuture(Set<Id> appointmentsIds) {
        updateFirstAvailableSlotStartTime(appointmentsIds);
    }

    public static void updateFirstAvailableSlotStartTime(Set<Id> appointmentsIds) {
        List<Error_Alert__e> errorAlerts = new List<Error_Alert__e>();
        
        try {
            Id schedulingPolicyId = getDefaultPolicy();
            if (schedulingPolicyId == null) {
                return;
            }

            List<ServiceAppointment> appointments = [
                SELECT  Id, First_Available_Slot_Start_Time__c, ServiceTerritoryId, ServiceTerritory.ParentTerritoryId
                FROM    ServiceAppointment
                WHERE   Id IN :appointmentsIds
            ];

            Set<Id> serviceTerritoryIds = new Set<Id>();
            for (ServiceAppointment appointment : appointments) {
                if (appointment.First_Available_Slot_Start_Time__c == null && appointment.ServiceTerritory.ParentTerritoryId != null) {
                    serviceTerritoryIds.add(appointment.ServiceTerritoryId);
                }
            }

            Map<Id, ServiceTerritory> serviceTerritoryMap = new Map<Id, ServiceTerritory>([
                SELECT  Id, OperatingHoursId, OperatingHours.TimeZone
                FROM    ServiceTerritory
                WHERE   Id IN :serviceTerritoryIds
            ]);

            List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
            
            for (ServiceAppointment appointment : appointments) {
                ServiceAppointment appointmentToUpdate = new ServiceAppointment(Id = appointment.Id, First_Available_Slot_Start_Time__c = null);

                if (appointment.ServiceTerritoryId != null 
                    && appointment.ServiceTerritory.ParentTerritoryId != null 
                    && serviceTerritoryMap.containsKey(appointment.ServiceTerritoryId)) {

                    ServiceTerritory targetTerritory = serviceTerritoryMap.get(appointment.ServiceTerritoryId);

                    if (targetTerritory.OperatingHoursId != null) {
                        Timezone timeZone = TimeZone.getTimeZone(targetTerritory.OperatingHours.TimeZone);

                        List<FSL.AppointmentBookingSlot> slots;
                        Boolean hasThrownException = false;
                        
                        try {
                            slots = FSL.AppointmentBookingService.GetSlots(appointment.Id, schedulingPolicyId, targetTerritory.OperatingHoursId, timeZone, false);
                        } catch (Exception e) {
                            hasThrownException = true;
                        }

                        if (hasThrownException) {
                            try {
                                slots = FSL.AppointmentBookingService.GetSlots(appointment.Id,schedulingPolicyId,targetTerritory.OperatingHoursId,timeZone,false);
                            } catch (Exception e) {
                                Error_Alert__e errorAlert = ExceptionUtil.prepareException(
                                    'PV_ServiceAppointmentTriggerHandler.updateFirstAvailableSlotStartTime SA: ' + appointment.Id,
                                    e.getLineNumber(),
                                    e.getMessage(),
                                    e.getStackTraceString()
                                );
                                errorAlerts.add(errorAlert);
                            }
                        }

                        if (!slots.isEmpty()) {
                            appointmentToUpdate.First_Available_Slot_Start_Time__c = slots[0].Interval.Start;
                            appointmentsToUpdate.add(appointmentToUpdate);
                        }
                    }
                }
            }
            update appointmentsToUpdate;
        } catch (Exception ex) {
            Error_Alert__e errorAlert = ExceptionUtil.prepareException(
                'PV_ServiceAppointmentTriggerHandler.updateFirstAvailableSlotStartTime',
                ex.getLineNumber(),
                ex.getMessage(),
                ex.getStackTraceString()
            );
            errorAlerts.add(errorAlert);
        } finally {
            if (!errorAlerts.isEmpty()) {
                ExceptionUtil.publishExceptions(errorAlerts);
            }
        }
    }

    public static Id getDefaultPolicy() {
        FSL_Settings__c fslSettings = FSL_Settings__c.getInstance();
        
        List<FSL__Scheduling_Policy__c> policies = [
            SELECT  Id
            FROM    FSL__Scheduling_Policy__c
            WHERE   Name = :fslSettings.Default_Scheduling_Policy_Name__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        return !policies.isEmpty() ? policies[0].Id : null;
    }

    public static DateTime convertToTimeZone(DateTime utcDate, TimeZone targetTimeZone) {
        Integer offsetMilliseconds = targetTimeZone.getOffset(utcDate);
        Integer offsetDifferenceInSeconds = offsetMilliseconds / 1000;
        Integer offsetDifferenceInHours = offsetDifferenceInSeconds / 3600;
        DateTime targetDate = utcDate.addHours(-offsetDifferenceInHours);
        return targetDate;
    }

    public class ShiftWrapper {
        public Integer hours;
        public List<Shift> shiftList;
    }

    public class AppointmentWrapper {
        public Integer hours;
        public List<ServiceAppointment> appointmentList;
    }
}