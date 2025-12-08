public with sharing class OrgWideEmailCMDTRepository {
    
    @TestVisible private static Map<String, Org_Wide_Email__mdt> testMockCatalogs;

    public static void setMockCatalogs(Map<String, Org_Wide_Email__mdt> mockData) {
        testMockCatalogs = mockData;
    }

    // 🔹 Get all existing CMDT records
    public static Map<String, Org_Wide_Email__mdt> getAllOrgWideEmails() {
        if (Test.isRunningTest() && testMockCatalogs != null) {
            return testMockCatalogs;
        }

        Map<String, Org_Wide_Email__mdt> result = new Map<String, Org_Wide_Email__mdt>();
        for (Org_Wide_Email__mdt rec : [
            SELECT Developer_Name__c, MasterLabel, OrgWideEmailAddressId__c,
                   Email_Address__c, Active__c
            FROM Org_Wide_Email__mdt
        ]) {
            result.put(rec.Developer_Name__c, rec);
        }
        return result;
    }

    // 🔹 Build a CMDT record from a DTO
    public static Metadata.CustomMetadata buildCMDT(OrgWideEmailDTO dto) {
        Metadata.CustomMetadata m = new Metadata.CustomMetadata();
        m.fullName = 'Org_Wide_Email.' + dto.developerName;
        m.label = dto.masterLabel;
        m.values = new List<Metadata.CustomMetadataValue>();

        addValue(m, 'Developer_Name__c', dto.developerName);
        addValue(m, 'OrgWideEmailAddressId__c', dto.orgWideEmailAddressId);
        addValue(m, 'Email_Address__c', dto.emailAddress);
        addValue(m, 'Active__c', dto.isActive);

        return m;
    }

    // 🔹 Add a field:value to the CMDT record
    private static void addValue(Metadata.CustomMetadata m, String fieldName, Object value) {
        Metadata.CustomMetadataValue customMetadataValue = new Metadata.CustomMetadataValue();
        customMetadataValue.field = fieldName;
        customMetadataValue.value = value;
        m.values.add(customMetadataValue);
    }

    // 🔹 Deploy CMDTs via Metadata API
    public static Id deployMetadata(List<Metadata.Metadata> records) {
        if (records == null || records.isEmpty()) return null;

        if (Test.isRunningTest()) {
            System.debug('⚠️ Skipping Metadata deployment during test context.');
            // 👉 Return null instead of fake 0Af Id to avoid StringException
            return null;
        }

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        for (Metadata.Metadata m : records) {
            container.addMetadata(m);
        }

        return Metadata.Operations.enqueueDeployment(container, null);
    }


    // 🔹 Upsert CMDTs with diff check
    public static Id upsertCMDTs(List<OrgWideEmailDTO> dtos) {
        if (dtos == null || dtos.isEmpty()) return null;

        Map<String, Org_Wide_Email__mdt> existing = getAllOrgWideEmails();
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        for (OrgWideEmailDTO dto : dtos) {
            Org_Wide_Email__mdt match = existing.get(dto.developerName);

            Boolean unchanged = match != null &&
                match.Email_Address__c == dto.emailAddress &&
                match.Active__c == dto.isActive;

            if (!unchanged) {
                container.addMetadata(buildCMDT(dto));
            }
        }

        return container.getMetadata().isEmpty()
            ? null
            : deployMetadata(container.getMetadata());
    }
}