public without sharing class FSL_TechnicianLocationService {
    @InvocableMethod(label='Get Technician Location' description='Get the location of a technician')
    public static List<TechnicianLocationOutput> getTechnicianLocation(List<String> encryptedServiceAppointmentIds) {
        List<TechnicianLocationOutput> technicianLocations = new List<TechnicianLocationOutput>();

        List<String> decodedServiceAppointmentIds = new List<String>();
        for (String encryptedServiceAppointmentId : encryptedServiceAppointmentIds) {
            decodedServiceAppointmentIds.add(EncodingUtil.base64Decode(EncodingUtil.urlDecode(encryptedServiceAppointmentId, 'UTF-8')).toString());
        }

        List<String> serviceAppointmentIds = DecryptSAforSelfScheduling.decrypt(decodedServiceAppointmentIds);
        Map<Id, ServiceAppointment> serviceAppointmentsById = new Map<Id, ServiceAppointment>([
            SELECT
                Id,
                Status,
                Street,
                City,
                State,
                PostalCode,
                Country,
                SchedStartTime,
                SchedEndTime,
                Dealer__r.Name,
                FSSK__FSK_Assigned_Service_Resource__r.RelatedRecordId,
                FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.FirstName,
                FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.Name,
                FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.MediumPhotoUrl,
                ServiceTerritory.OperatingHours.TimeZone
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ]);
        for (Id serviceAppointmentId : serviceAppointmentIds) {
            TechnicianLocationOutput technicianLocation = new TechnicianLocationOutput();
            if (serviceAppointmentsById.containsKey(serviceAppointmentId)) {
                ServiceAppointment serviceAppointment = serviceAppointmentsById.get(serviceAppointmentId);
                technicianLocation.serviceAppointmentStatus = serviceAppointment.Status;
                technicianLocation.serviceAppointmentAddress = serviceAppointment.Street + ' ' + serviceAppointment.City + ' ' + serviceAppointment.State + ' ' + serviceAppointment.PostalCode + ' ' + serviceAppointment.Country;
                String strSTTZ = serviceAppointment.ServiceTerritory.OperatingHours.TimeZone;
                if (strSTTZ != null) {
                    technicianLocation.serviceAppointmentStartTime = serviceAppointment.SchedStartTime?.format('hh:mm aaa', strSTTZ);
                    technicianLocation.serviceAppointmentEndTime = serviceAppointment.SchedEndTime?.format('hh:mm aaa', strSTTZ);
                }
                technicianLocation.dealerName = serviceAppointment.Dealer__r.Name;
                technicianLocation.technicianFirstName = serviceAppointment.FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.FirstName;
                technicianLocation.technicianName = serviceAppointment.FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.Name;
                technicianLocation.technicianPhoto = serviceAppointment.FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.MediumPhotoUrl;
            }
            technicianLocations.add(technicianLocation);
        }
        return technicianLocations;
    }

    public class TechnicianLocationInput {
        @InvocableVariable(label='Encrypted Service Appointment ID')
        public String encryptedServiceAppointmentId;
    }

    public class TechnicianLocationOutput {
        @InvocableVariable(label='Service Appointment Status')
        public String serviceAppointmentStatus;
        @InvocableVariable(label='Service Appointment Address')
        public String serviceAppointmentAddress;
        @InvocableVariable(label='Service Appointment Start Time')
        public String serviceAppointmentStartTime;
        @InvocableVariable(label='Service Appointment End Time')
        public String serviceAppointmentEndTime;
        @InvocableVariable(label='Dealer Name')
        public String dealerName;
        @InvocableVariable(label='Technician First Name')
        public String technicianFirstName;
        @InvocableVariable(label='Technician Name')
        public String technicianName;
        @InvocableVariable(label='Technician Photo')
        public String technicianPhoto;
    }
}