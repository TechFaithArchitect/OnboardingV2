public class POE_GeoCodeMDUs {
    @InvocableMethod(label='Geocode MDUs' description='Geocode MDUs with address updates or during creation.')
    public static void updateMDUs(List<MDU_Chuzo__c> events) {
        String address =
            events[0].Street_Address__c +
            ', ' +
            events[0].City__c +
            ', ' +
            events[0].State__c +
            ' ' +
            events[0].Zip_Code__c +
            ' USA';
        geoCodeRecord(address, events[0].Id);
    }

    @future(callout=true)
    public static void geoCodeRecord(String address, String recordId) {
        Map<string, object> options = new Map<String, Object>{ 'version' => '1', 'address' => address };
        Map<String, Object> response = new Map<String, Object>();
        if (!Test.isRunningTest()) {
            response = maps.API.Geocode(options);
        } else {
            Map<String, Object> position = new Map<String, Object>();
            position.put('lat', 37.7897784);
            position.put('lng', -122.3973206);
            Map<String, Object> data = new Map<String, Object>();
            data.put('position', position);
            response.put('data', data);
        }
        try {
            Map<String, Object> data = (Map<String, Object>) response.get('data');
            Map<String, Object> position = (Map<String, Object>) data.get('position');
            Decimal lat = (Decimal) position.get('lat');
            Decimal lng = (Decimal) position.get('lng');
            MDU_Chuzo__c mdu = [
                SELECT Id, Location__Latitude__s, Location__Longitude__s
                FROM MDU_Chuzo__c
                WHERE Id = :recordId
            ];
            mdu.Location__Latitude__s = lat;
            mdu.Location__Longitude__s = lng;
            update mdu;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    public class Output {
        public String baseUrl;
        public Data data;
        public String source;
        public String success;
    }

    public class Data {
        public String houseNumber;
        public String matchLevel;
        public Integer score;
        public String country;
        public String postal;
        public String state;
        public String city;
        public String street;
        public String fullAddress;
        public Position position;
    }

    public class Position {
        public Decimal lng;
        public Decimal lat;
    }
    
}