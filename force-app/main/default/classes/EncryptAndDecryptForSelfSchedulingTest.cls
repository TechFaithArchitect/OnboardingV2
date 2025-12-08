@isTest
public class EncryptAndDecryptForSelfSchedulingTest {
    @testSetup static void createTestData() {
        WorkOrder wo = new WorkOrder();
        wo.Subject = 'Test WO';
        wo.Vendor__c = 'T-Mobile';
        insert wo;
        
        OperatingHours op = new OperatingHours();
        op.Name = 'Test OH';
        insert op;
        
        ServiceTerritory st = new ServiceTerritory();
        st.Name = 'Test SA';
        st.OperatingHoursId = op.Id;
        st.IsActive = true;
        insert st;
        
        ServiceAppointment sa1 = new ServiceAppointment();
        sa1.Status = 'Unscheduled';
        sa1.ParentRecordId = wo.Id;
        sa1.FSSK__FSK_Work_Order__c = wo.Id;
        sa1.Subject = 'SA 1';
        sa1.ServiceTerritoryId = st.Id;
        insert sa1;
        
        ServiceAppointment sa2 = new ServiceAppointment();
        sa2.Status = 'Unscheduled';
        sa2.ParentRecordId = wo.Id;
        sa2.FSSK__FSK_Work_Order__c = wo.Id;
        sa2.Subject = 'SA 2';
        sa2.ServiceTerritoryId = st.Id;
        insert sa2;
    }

    @isTest
    static void testEncryptAndDecryptURL() {
        List<String> encryptedURLList = new List<String>();
        List<String> encryptedRecordIdList = new List<String>();
        List<String> decryptedRecordIdList = new List<String>();
        List<ServiceAppointment> serviceAppointmentList = [SELECT Id, Subject,Status FROM ServiceAppointment WHERE Subject LIKE '%SA%'];
        List<EncryptSAForSelfScheduling.EncryptionInput> encryptionInputs = new List<EncryptSAForSelfScheduling.EncryptionInput>();
        for(ServiceAppointment sa : serviceAppointmentList) {
            EncryptSAForSelfScheduling.EncryptionInput input = new EncryptSAForSelfScheduling.EncryptionInput();
            input.recordIdList = sa.Id;
            input.url = '';
            encryptionInputs.add(input);
        }

        Test.startTest();
        encryptedURLList = EncryptSAForSelfScheduling.encrypt(encryptionInputs); 
        for(String decode : encryptedURLList){
            encryptedRecordIdList.add(decode.substringAfter('recordId='));
        }
        decryptedRecordIdList = DecryptSAforSelfScheduling.decrypt(encryptedRecordIdList);
        Test.stopTest();

        Assert.areEqual(decryptedRecordIdList[0], serviceAppointmentList[0].Id, 'Decrypted record ID should match');
    }    
}