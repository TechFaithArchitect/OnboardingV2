global class FSL_OrdersServiceHandler {

    @testVisible private static Boolean throwException = false;

    public static Map<String, Object> getSlots(String requestPath) {
        try { 
            if (Test.isRunningTest() && throwException) {
                throw new CustomException();
            }

            String serviceAppointmentId = requestPath.substringAfter('getSlots/');

            if (String.isBlank(serviceAppointmentId)) {
                return missingParameterError('serviceAppointmentId');
            }

            ServiceAppointment serviceAppointment = getServiceAppointment(serviceAppointmentId);

            if (serviceAppointment == null) {
                return resourceNotFoundError('Service appointment');
            } else if (serviceAppointment != null && serviceAppointment.Dealer__c == null) {
                RestContext.response.statusCode = 500;
                return new Map<String, Object>{
                    'errorCode' => 'UNASSIGNED_APPOINTMENT',
                    'message' => 'The service appointment is not assigned to a dealer.'
                };
            }

            Id schedulingPolicyId = getDefaultPolicy();
            Timezone timeZone = TimeZone.getTimeZone(serviceAppointment.ServiceTerritory.OperatingHours.TimeZone);
            String tzName = timeZone.getDisplayName();

            List<FSL.AppointmentBookingSlot> slots = FSL.AppointmentBookingService.GetSlots(
                serviceAppointment.Id,
                schedulingPolicyId,
                serviceAppointment.ServiceTerritory.OperatingHoursId,
                timeZone,
                false
            );

            List<Slot> slotList = new List<Slot>();

            for (Integer i = 0; i < slots.size(); i++) {
                Slot sl = new Slot();
                sl.startDateTime = slots[i].Interval.Start;
                sl.endDateTime = slots[i].Interval.Finish;
                slotList.add(sl);
            }

            RestContext.response.statusCode = 200;
            return new Map<String, Object>{
                'timezone' => tzName,
                'slots' => slotList
            };
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', FSL_OrdersServiceHandler.class.getName(), e.getMessage());
            return FSL_OrdersServiceHandler.unexpectedError(e.getMessage());
        }
    }

    public static Map<String, Object> bookAppointment(String requestPath) {
        try { 
            if (Test.isRunningTest() && throwException) {
                throw new CustomException();
            }

            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestPath);

            if (!requestData.containsKey('serviceAppointmentId') || String.isBlank((String)requestData.get('serviceAppointmentId'))) {
                return missingParameterError('serviceAppointmentId');
            }

            String serviceAppointmentId = (String) requestData.get('serviceAppointmentId');
            ServiceAppointment serviceAppointment = getServiceAppointment(serviceAppointmentId);

            if (serviceAppointment == null) {
                return resourceNotFoundError('Service appointment');
            }

            TimeZone territoryTimeZone = getSaTerritoryTimeZone(serviceAppointment);
            Id schedulingPolicyId = getDefaultPolicy();

            FSL.ScheduleResult myResult = FSL.ScheduleService.schedule(schedulingPolicyId, serviceAppointmentId);

            if (myResult == null) {
                return notMatchingResources();
            }

            serviceAppointment = getServiceAppointment(serviceAppointmentId);
            Id serviceResourceId = serviceAppointment.ServiceResources[0].ServiceResourceId;
            DateTime convertedScheduledTime = convertToTimeZone(serviceAppointment.SchedStartTime, territoryTimeZone);

            RestContext.response.statusCode = 201;
            return new Map<String, Object>{
                'technicianId' => serviceResourceId,
                'status' => serviceAppointment.Status,
                'scheduledStart' => convertedScheduledTime
            };
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', FSL_OrdersServiceHandler.class.getName(), e.getMessage());
            return FSL_OrdersServiceHandler.unexpectedError(e.getMessage());
        }
    }

    public static ServiceAppointment getServiceAppointment(String serviceAppointmentId) {
        List<ServiceAppointment> serviceAppointment = [
            SELECT  
                Id, ArrivalWindowStartTime, ArrivalWindowEndTime, ServiceTerritoryId, Status, SchedStartTime, EarliestStartTime, DueDate,
                ServiceTerritory.OperatingHoursId, ServiceTerritory.OperatingHours.TimeZone, Dealer__c,
                (SELECT ServiceResourceId FROM ServiceResources LIMIT 1)
            FROM    ServiceAppointment
            WHERE   Id = :serviceAppointmentId
            LIMIT 1
        ];

        if (serviceAppointment.size() > 0) {
            return serviceAppointment[0];
        } else {
            return null;
        }
    }

    public static TimeZone getSaTerritoryTimeZone(ServiceAppointment serviceAppointment) {
        ServiceTerritory serviceTerritory = [
            SELECT  Id, OperatingHours.TimeZone
            FROM    ServiceTerritory
            WHERE   Id = :serviceAppointment.ServiceTerritoryId
        ];

        return TimeZone.getTimeZone(serviceTerritory.OperatingHours.TimeZone);
    }

    public static DateTime convertToTimeZone(DateTime utcDate, TimeZone targetTimeZone) {
        Integer offsetMilliseconds = targetTimeZone.getOffset(utcDate);
        Integer offsetDifferenceInSeconds = offsetMilliseconds / 1000;
        Integer offsetDifferenceInHours = offsetDifferenceInSeconds / 3600;
        DateTime targetDate = utcDate.addHours(offsetDifferenceInHours);
        return targetDate;
    }

    public static Id getDefaultPolicy() {
        FSL_Settings__c fslSettings = FSL_Settings__c.getInstance();
        
        return [
            SELECT  Id
            FROM    FSL__Scheduling_Policy__c
            WHERE   Name = :fslSettings.Default_Scheduling_Policy_Name__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ].Id;
    }

    public static Map<String, Object> missingParameterError(String parameters) {
        RestContext.response.statusCode = 400;
        return new Map<String, Object>{
            'errorCode' => 'MISSING_PARAMETER',
            'message' => 'Missing or empty required parameters: ' + parameters + '.'
        };
    }

    public static Map<String, Object> resourceNotFoundError(String objectName) {
        RestContext.response.statusCode = 404;
        return new Map<String, Object>{
            'errorCode' => 'RESOURCE_NOT_FOUND',
            'message' => objectName + ' ID not found.'
        };
    }
    
    public static Map<String, Object> unexpectedError(String internalError) {
        RestContext.response.statusCode = 500;
        return new Map<String, Object>{
            'errorCode' => 'INTERNAL_SERVER_ERROR',
            'message' => internalError
        };
    }

    public static Map<String, Object> notMatchingResources() {
        RestContext.response.statusCode = 404;
        return new Map<String, Object>{
            'errorCode' => 'NO_MATCHING_RESOURCES',
            'message' => 
            'We couldn\'t get candidates for the service appointment because ' +
            'there aren\'t any service resources that match the requirements. ' +
            'Fix the issue and try again.'
        };
    }

    public class Slot {
        DateTime startDateTime;
        DateTime endDateTime;
    }
    
    global class GetSlotsResponseWrapper {
        public List<Slot> slots;
        public String timezone;
        public String errorCode = '';
        public String message = 'SUCCESS';
        
        public GetSlotsResponseWrapper(Map<String, Object> content) {
            if (content.containsKey('slots')) {
                this.slots = (List<Slot>) content.get('slots');
            }
            if (content.containsKey('errorCode')) {
                this.errorCode = (String) content.get('errorCode');
            }
            if (content.containsKey('message')) {
                this.message = (String) content.get('message');
            }
            if(content.containsKey('timezone')) {
                this.timezone = String.valueOf(content.get('timezone'));
            }
        }
    }

    global class BookAppointmentResponseWrapper {
        public String errorCode = '';
        public String message = 'SUCCESS';
        public String technicianId;
        public String status;
        public String scheduledStart;
        
        public BookAppointmentResponseWrapper(Map<String, Object> content) {
            if (content.containsKey('errorCode')) {
                this.errorCode = (String) content.get('errorCode');
            }
            if (content.containsKey('message')) {
                this.message = (String) content.get('message');
            }
            if (content.containsKey('technicianId')) {
                this.technicianId = (String) content.get('technicianId');
            }
            if (content.containsKey('status')) {
                this.status = (String) content.get('status');
            }
            if (content.containsKey('scheduledStart')) {
                this.scheduledStart = String.valueOf(content.get('scheduledStart'));
            }
        }
    }

    public class FSL_OrdersServiceHandlerException extends Exception {}
}