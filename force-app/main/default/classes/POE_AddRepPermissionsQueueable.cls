public without sharing class POE_AddRepPermissionsQueueable implements Queueable {
    private Id contactId;
    private Id userId;

    public POE_AddRepPermissionsQueueable(Id contactId, Id userId) {
        this.contactId = contactId;
        this.userId = userId;
    }

    public void execute(QueueableContext context) {
        Contact fslContact = [
            SELECT Id, POE_Representative_Type__c, POE_Functional_Role__c, POE_RO_Status__c
            FROM Contact
            WHERE Id = :this.contactId
        ];

        Boolean hasD2D = fslContact.POE_Representative_Type__c.contains('Door To Door');
        Boolean hasEvent = fslContact.POE_Representative_Type__c.contains('Event');
        Boolean hasRetail = fslContact.POE_Representative_Type__c.contains('Retail');

        Map<String, Id> permSetOrGroupIdsByName = POE_PermissionsUtility.getPermissionsAndGroupsByName();
        for (PermissionSetAssignment psa : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :this.userId
        ]) {
            permSetOrGroupIdsByName.remove(psa.PermissionSet.Name);
        }

        List<PermissionSetAssignment> psasToCreate = new List<PermissionSetAssignment>();
        if (fslContact.POE_Functional_Role__c != 'Office Representative') {
            Id ownerNoMapsPSGId = permSetOrGroupIdsByName.get(POE_PermissionsUtility.OWNER_PSG_NO_MAPS);
            if (ownerNoMapsPSGId != null) {
                psasToCreate.add(
                    new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetGroupId = ownerNoMapsPSGId)
                );
            }

            Id ownerPSId = permSetOrGroupIdsByName.get(POE_PermissionsUtility.OWNER_PERMISSION_SET_NAME);
            if (ownerPSId != null) {
                psasToCreate.add(new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetId = ownerPSId));
            }

            Id ownerPSGId = permSetOrGroupIdsByName.get(POE_PermissionsUtility.OWNER_PSG);
            if (hasD2D && ownerPSGId != null) {
                psasToCreate.add(
                    new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetGroupId = ownerPSGId)
                );
            }
        }

        if (fslContact.POE_Representative_Type__c.contains('Phone Sales')) {
            Id phoneSalesPSId = permSetOrGroupIdsByName.get(POE_PermissionsUtility.PHONE_SALES_PS_NAME);
            if (phoneSalesPSId != null) {
                psasToCreate.add(
                    new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetId = phoneSalesPSId)
                );
            }

            Id phoneSalesPSGId = permSetOrGroupIdsByName.get(POE_PermissionsUtility.PHONE_SALES_PS_GROUP_NAME);
            if (phoneSalesPSGId != null) {
                psasToCreate.add(
                    new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetGroupId = phoneSalesPSGId)
                );
            }
        }

        Id residentialPSId = permSetOrGroupIdsByName.get(POE_PermissionsUtility.RESIDENTIAL_PS_NAME);
        if (residentialPSId != null && (hasD2D || hasEvent || hasRetail)) {
            psasToCreate.add(new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetId = residentialPSId));
        }

        if (String.isNotBlank(fslContact.POE_Representative_Type__c)) {
            List<String> repTypes = fslContact.POE_Representative_Type__c.split(';');

            for (String repType : repTypes) {
                String clickerPSName = POE_PermissionsUtility.CLICKER_PS_BY_REP_TYPE.get(repType);

                Id clickerPermSetId = permSetOrGroupIdsByName.get(clickerPSName);
                if (clickerPermSetId != null) {
                    psasToCreate.add(
                        new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetId = clickerPermSetId)
                    );
                }
            }
        }

        if (hasD2D) {
            PermissionSetLicense mapsLicense = [
                SELECT Id
                FROM PermissionSetLicense
                WHERE DeveloperName = 'SFMaps_Maps_CommunityNamedUser'
                LIMIT 1
            ];

            Integer mapsLicenseAssignmentCount = [
                SELECT COUNT()
                FROM PermissionSetLicenseAssign
                WHERE PermissionSetLicenseId = :mapsLicense.Id AND AssigneeId = :this.userId
            ];

            if (mapsLicenseAssignmentCount == 0) {
                PermissionSetLicenseAssign licenseAssignment = new PermissionSetLicenseAssign(
                    AssigneeId = this.userId,
                    PermissionSetLicenseId = mapsLicense.Id
                );

                insert licenseAssignment;
            }

            List<String> mapsPermissionNames = new List<String>{
                POE_PermissionsUtility.COMMUNITY_NAMED_USER_PS_NAME,
                POE_PermissionsUtility.MAPS_USER_PS_NAME,
                POE_PermissionsUtility.SF_MAPS_PS_NAME
            };
            for (String psName : mapsPermissionNames) {
                Id psId = permSetOrGroupIdsByName.get(psName);
                if (psId == null) {
                    continue;
                }

                psasToCreate.add(new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetId = psId));
            }

            Id d2dPSGId = permSetOrGroupIdsByName.get(POE_PermissionsUtility.D2D_PS_GROUP_NAME);
            if (d2dPSGId != null) {
                psasToCreate.add(
                    new PermissionSetAssignment(AssigneeId = this.userId, PermissionSetGroupId = d2dPSGId)
                );
            }
        }
        insert psasToCreate;
    }
}