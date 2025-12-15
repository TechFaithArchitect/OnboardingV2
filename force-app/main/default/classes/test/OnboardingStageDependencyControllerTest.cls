/**
 * Test class for OnboardingStageDependencyController
 */
@isTest
private class OnboardingStageDependencyControllerTest {

    /**
     * Helper method to create test process with stages
     */
    private static Onboarding_Application_Process__c createTestProcessWithStages(Integer numStages) {
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Test Process',
            Active__c = true
        );
        insert process;

        List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>();
        for (Integer i = 1; i <= numStages; i++) {
            Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
                Name = 'Stage ' + i,
                Label__c = 'Stage ' + i,
                Display_Order__c = i,
                Onboarding_Application_Process__c = process.Id,
                Required__c = true
            );
            stages.add(stage);
        }
        insert stages;

        return process;
    }

    /**
     * Helper method to create stage dependency
     */
    private static Onboarding_Application_Stage_Dependency__c createStageDependency(
        Id targetStageId,
        Id requiredStageId,
        Boolean required
    ) {
        Onboarding_Application_Stage_Dependency__c dependency = new Onboarding_Application_Stage_Dependency__c(
            Name = 'Dependency',
            Target_Stage__c = targetStageId,
            Required__c = required != null ? required : true,
            Logic_Type__c = 'All'
        );
        insert dependency;

        // Create dependency member
        // Note: Field name is Stage_Dependency__c (not Onboarding_Application_Stage_Dependency__c)
        Onboarding_App_Stage_Dependency_Member__c member = new Onboarding_App_Stage_Dependency_Member__c(
            Stage_Dependency__c = dependency.Id,
            Required_Stage__c = requiredStageId,
            Required__c = true
        );
        insert member;

        return dependency;
    }

    /**
     * Helper method to create stage completion
     */
    private static Onboarding_Application_Stage_Completion__c createStageCompletion(
        Id vendorProgramId,
        Id processId,
        Id stageId
    ) {
        Onboarding_Application_Stage_Completion__c completion = new Onboarding_Application_Stage_Completion__c(
            Vendor_Program__c = vendorProgramId,
            Onboarding_Application_Process__c = processId,
            Onboarding_Application_Stage__c = stageId
        );
        insert completion;
        return completion;
    }

    @isTest
    static void testGetStagesWithDependencies_Basic() {
        // Create test data
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id, Name, Display_Order__c
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        System.assertEquals('Stage 1', result[0].stageName, 'First stage should be Stage 1');
        System.assertEquals(1, result[0].sequence, 'First stage sequence should be 1');
        System.assertEquals(false, result[0].isCompleted, 'Stage should not be completed');
        System.assertEquals(false, result[0].isBlocked, 'Stage should not be blocked');
        System.assertEquals(0, result[0].requiredStageIds.size(), 'No dependencies');
    }

    @isTest
    static void testGetStagesWithDependencies_WithVendorProgram() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Mark first stage as completed
        createStageCompletion(testProgram.Id, process.Id, stages[0].Id);

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, testProgram.Id);
        Test.stopTest();

        // Verify results
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        System.assertEquals(true, result[0].isCompleted, 'First stage should be completed');
        System.assertEquals(false, result[1].isCompleted, 'Second stage should not be completed');
        System.assertEquals(false, result[2].isCompleted, 'Third stage should not be completed');
    }

    @isTest
    static void testGetStagesWithDependencies_WithDependencies() {
        // Create test data
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 2 requires Stage 1
        createStageDependency(stages[1].Id, stages[0].Id, true);

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        
        // Stage 1 should have no dependencies
        System.assertEquals(0, result[0].requiredStageIds.size(), 'Stage 1 should have no dependencies');
        System.assertEquals(false, result[0].isBlocked, 'Stage 1 should not be blocked');
        
        // Stage 2 should have Stage 1 as dependency
        System.assertEquals(1, result[1].requiredStageIds.size(), 'Stage 2 should have 1 dependency');
        System.assertEquals(stages[0].Id, result[1].requiredStageIds[0], 'Stage 2 should depend on Stage 1');
        System.assertEquals(true, result[1].isBlocked, 'Stage 2 should be blocked (Stage 1 not completed)');
    }

    @isTest
    static void testGetStagesWithDependencies_WithCompletedDependencies() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 2 requires Stage 1
        createStageDependency(stages[1].Id, stages[0].Id, true);
        
        // Mark Stage 1 as completed
        createStageCompletion(testProgram.Id, process.Id, stages[0].Id);

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, testProgram.Id);
        Test.stopTest();

        // Verify results
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        
        // Stage 2 should have dependency but not be blocked (Stage 1 is completed)
        System.assertEquals(1, result[1].requiredStageIds.size(), 'Stage 2 should have 1 dependency');
        System.assertEquals(false, result[1].isBlocked, 'Stage 2 should not be blocked (dependency met)');
    }

    @isTest
    static void testGetStagesWithDependencies_NullProcessId() {
        Test.startTest();
        try {
            OnboardingStageDependencyController.getStagesWithDependencies(null, null);
            System.assert(false, 'Should throw exception for null process ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Process ID'), 'Error message should mention Process ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetStagesWithDependencies_NoStages() {
        // Create process with no stages
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Empty Process',
            Active__c = true
        );
        insert process;

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(0, result.size(), 'Should return empty list for process with no stages');
    }

    @isTest
    static void testGetStagesWithDependencies_ComplexDependencies() {
        // Create test data
        Onboarding_Application_Process__c process = createTestProcessWithStages(4);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create complex dependencies:
        // Stage 2 requires Stage 1
        // Stage 3 requires Stage 1 and Stage 2
        createStageDependency(stages[1].Id, stages[0].Id, true);
        createStageDependency(stages[2].Id, stages[0].Id, true);
        createStageDependency(stages[2].Id, stages[1].Id, true);

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(4, result.size(), 'Should return 4 stages');
        
        // Stage 1 should have no dependencies
        System.assertEquals(0, result[0].requiredStageIds.size(), 'Stage 1 should have no dependencies');
        
        // Stage 2 should depend on Stage 1
        System.assertEquals(1, result[1].requiredStageIds.size(), 'Stage 2 should have 1 dependency');
        System.assertEquals(true, result[1].isBlocked, 'Stage 2 should be blocked');
        
        // Stage 3 should depend on Stage 1 and Stage 2
        System.assertEquals(2, result[2].requiredStageIds.size(), 'Stage 3 should have 2 dependencies');
        System.assertEquals(true, result[2].isBlocked, 'Stage 3 should be blocked');
    }

    @isTest
    static void testGetStagesWithDependencies_NonRequiredDependency() {
        // Create test data
        Onboarding_Application_Process__c process = createTestProcessWithStages(2);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create non-required dependency: Stage 2 has optional dependency on Stage 1
        Onboarding_Application_Stage_Dependency__c dependency = new Onboarding_Application_Stage_Dependency__c(
            Name = 'Optional Dependency',
            Target_Stage__c = stages[1].Id,
            Required__c = false,
            Logic_Type__c = 'All'
        );
        insert dependency;

        // Note: Field name is Stage_Dependency__c (not Onboarding_Application_Stage_Dependency__c)
        Onboarding_App_Stage_Dependency_Member__c member = new Onboarding_App_Stage_Dependency_Member__c(
            Stage_Dependency__c = dependency.Id,
            Required_Stage__c = stages[0].Id,
            Required__c = false
        );
        insert member;

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(2, result.size(), 'Should return 2 stages');
        
        // Stage 2 should not have dependencies (non-required dependencies are ignored)
        System.assertEquals(0, result[1].requiredStageIds.size(), 'Non-required dependencies should be ignored');
        System.assertEquals(false, result[1].isBlocked, 'Stage 2 should not be blocked');
    }

    @isTest
    static void testGetStagesWithDependencies_SortedBySequence() {
        // Create test data with stages in random order
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Test Process',
            Active__c = true
        );
        insert process;

        List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>();
        // Create stages in reverse order
        for (Integer i = 3; i >= 1; i--) {
            Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
                Name = 'Stage ' + i,
                Label__c = 'Stage ' + i,
                Display_Order__c = i,
                Onboarding_Application_Process__c = process.Id,
                Required__c = true
            );
            stages.add(stage);
        }
        insert stages;

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results are sorted by sequence
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        System.assertEquals(1, result[0].sequence, 'First result should have sequence 1');
        System.assertEquals(2, result[1].sequence, 'Second result should have sequence 2');
        System.assertEquals(3, result[2].sequence, 'Third result should have sequence 3');
    }

    @isTest
    static void testGetStagesWithDependencies_NullDisplayOrder() {
        // Create test data with null Display_Order__c
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Test Process',
            Active__c = true
        );
        insert process;

        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Label__c = 'Stage 1',
            Display_Order__c = null,
            Onboarding_Application_Process__c = process.Id,
            Required__c = true
        );
        insert stage;

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(1, result.size(), 'Should return 1 stage');
        System.assertEquals(0, result[0].sequence, 'Null Display_Order__c should default to 0');
    }
}

