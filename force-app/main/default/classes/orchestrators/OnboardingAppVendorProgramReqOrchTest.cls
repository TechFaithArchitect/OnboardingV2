@isTest
private class OnboardingAppVendorProgramReqOrchTest {

    @isTest
    static void testOrchestrateCredentialLoad_Success() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType('Type A', 1, vendorProgram, true, true);
        Required_Credential__c rc = TestCredentialFactory.createRequiredCredential(type1, vendorProgram, true, true);
        
        // Act
        Test.startTest();
        List<Required_Credential__c> result = OnboardingAppVendorProgramReqOrch.orchestrateCredentialLoad(vendorProgram.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return required credentials');
    }

    @isTest
    static void testOrchestrateCredentialLoad_NullId_Throws() {
        // Act + Assert
        try {
            Test.startTest();
            OnboardingAppVendorProgramReqOrch.orchestrateCredentialLoad(null);
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('must not be null'), 'Should throw exception for null ID');
        }
    }

    @isTest
    static void testOrchestrateTrainingLoad_Success() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Training_System__c trainingSystem = TestTrainingSystemFactory.create(true);
        Training_Requirement__c trainingReq = TestTrainingRequirementFactory.create(true, vendorProgram, trainingSystem);
        
        // Act
        Test.startTest();
        List<Training_Requirement__c> result = OnboardingAppVendorProgramReqOrch.orchestrateTrainingLoad(vendorProgram.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return training requirements');
    }

    @isTest
    static void testOrchestrateTrainingLoad_NullId_Throws() {
        // Act + Assert
        try {
            Test.startTest();
            OnboardingAppVendorProgramReqOrch.orchestrateTrainingLoad(null);
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('must not be null'), 'Should throw exception for null ID');
        }
    }

    @isTest
    static void testOrchestrateCreateCredential_Success() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType('Type A', 1, vendorProgram, true, true);
        Required_Credential__c newCredential = new Required_Credential__c(
            Vendor_Customization__c = vendorProgram.Id,
            External_Contact_Credential_Type__c = type1.Id
        );
        
        // Act
        Test.startTest();
        Id credentialId = OnboardingAppVendorProgramReqOrch.orchestrateCreateCredential(newCredential);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, credentialId, 'Credential ID should be returned');
    }

    @isTest
    static void testOrchestrateCreateCredential_NullRecord_Throws() {
        // Act + Assert
        try {
            Test.startTest();
            OnboardingAppVendorProgramReqOrch.orchestrateCreateCredential(null);
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('must not be null'), 'Should throw exception for null record');
        }
    }

    @isTest
    static void testOrchestrateCreateCredential_NullVendorProgram_Throws() {
        // Arrange
        Required_Credential__c newCredential = new Required_Credential__c();
        
        // Act + Assert
        try {
            Test.startTest();
            OnboardingAppVendorProgramReqOrch.orchestrateCreateCredential(newCredential);
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('must not be null'), 'Should throw exception for null vendor program');
        }
    }

    @isTest
    static void testOrchestrateCreateTraining_Success() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Training_System__c trainingSystem = TestTrainingSystemFactory.create(true);
        Training_Requirement__c newTraining = new Training_Requirement__c(
            Vendor_Customization__c = vendorProgram.Id,
            Training_System__c = trainingSystem.Id
        );
        
        // Act
        Test.startTest();
        Id trainingId = OnboardingAppVendorProgramReqOrch.orchestrateCreateTraining(newTraining);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, trainingId, 'Training ID should be returned');
    }

    @isTest
    static void testOrchestrateCreateTraining_NullRecord_Throws() {
        // Act + Assert
        try {
            Test.startTest();
            OnboardingAppVendorProgramReqOrch.orchestrateCreateTraining(null);
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('must not be null'), 'Should throw exception for null record');
        }
    }

    @isTest
    static void testOrchestrateCreateTraining_NullVendorProgram_Throws() {
        // Arrange
        Training_Requirement__c newTraining = new Training_Requirement__c();
        
        // Act + Assert
        try {
            Test.startTest();
            OnboardingAppVendorProgramReqOrch.orchestrateCreateTraining(newTraining);
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('must not be null'), 'Should throw exception for null vendor program');
        }
    }

    @isTest
    static void testOrchestrateCreateTraining_NullTrainingSystem_Throws() {
        // Arrange
        Vendor__c vendor = TestVendorFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Training_Requirement__c newTraining = new Training_Requirement__c(
            Vendor_Customization__c = vendorProgram.Id
        );
        
        // Act + Assert
        try {
            Test.startTest();
            OnboardingAppVendorProgramReqOrch.orchestrateCreateTraining(newTraining);
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('must not be null'), 'Should throw exception for null training system');
        }
    }
}

