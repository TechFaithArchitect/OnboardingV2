/**
 * Test class for OnboardingStageDependencyService
 */
@isTest
private class OnboardingStageDependencyServiceTest {

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
     * Helper method to create vendor program
     */
    private static Vendor_Customization__c createTestVendorProgram() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        return TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
    }

    /**
     * Helper method to create stage dependency
     */
    private static Onboarding_Application_Stage_Dependency__c createStageDependency(
        Id targetStageId,
        List<Id> requiredStageIds,
        String logicType,
        Boolean required
    ) {
        Onboarding_Application_Stage_Dependency__c dependency = new Onboarding_Application_Stage_Dependency__c(
            Name = 'Dependency ' + String.valueOf(DateTime.now().getTime()),
            Target_Stage__c = targetStageId,
            Required__c = required != null ? required : true,
            Logic_Type__c = logicType != null ? logicType : 'ALL'
        );
        insert dependency;

        // Create dependency members
        if (requiredStageIds != null && !requiredStageIds.isEmpty()) {
            List<Onboarding_App_Stage_Dependency_Member__c> members = new List<Onboarding_App_Stage_Dependency_Member__c>();
            for (Id requiredStageId : requiredStageIds) {
                Onboarding_App_Stage_Dependency_Member__c member = new Onboarding_App_Stage_Dependency_Member__c(
                    Stage_Dependency__c = dependency.Id,
                    Required_Stage__c = requiredStageId,
                    Required__c = true
                );
                members.add(member);
            }
            insert members;
        }

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
    static void testCanStartStage_NoDependencies() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[0].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when no dependencies');
        System.assertEquals(0, result.blockingDependencies.size(), 'Should have no blocking dependencies');
    }

    @isTest
    static void testCanStartStage_ALL_Logic_AllMet() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 AND Stage 2
        createStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            'ALL',
            true
        );

        // Complete Stage 1 and Stage 2
        createStageCompletion(vendorProgram.Id, process.Id, stages[0].Id);
        createStageCompletion(vendorProgram.Id, process.Id, stages[1].Id);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when ALL dependencies met');
        System.assertEquals(0, result.blockingDependencies.size(), 'Should have no blocking dependencies');
    }

    @isTest
    static void testCanStartStage_ALL_Logic_NotAllMet() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 AND Stage 2
        createStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            'ALL',
            true
        );

        // Complete only Stage 1 (not Stage 2)
        createStageCompletion(vendorProgram.Id, process.Id, stages[0].Id);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.canStart, 'Stage should NOT be startable when ALL dependencies not met');
        System.assertEquals(1, result.blockingDependencies.size(), 'Should have 1 blocking dependency');
        System.assertEquals(2, result.blockingDependencies[0].requiredStageIds.size(), 'Should require 2 stages');
        System.assertEquals(1, result.blockingDependencies[0].completedStageIds.size(), 'Should have 1 completed stage');
        System.assertEquals(1, result.blockingDependencies[0].missingStageIds.size(), 'Should have 1 missing stage');
    }

    @isTest
    static void testCanStartStage_ANY_Logic_OneMet() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 OR Stage 2
        createStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            'ANY',
            true
        );

        // Complete only Stage 1
        createStageCompletion(vendorProgram.Id, process.Id, stages[0].Id);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when ANY dependency met');
        System.assertEquals(0, result.blockingDependencies.size(), 'Should have no blocking dependencies');
    }

    @isTest
    static void testCanStartStage_ANY_Logic_NoneMet() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 OR Stage 2
        createStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            'ANY',
            true
        );

        // Don't complete any stages

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.canStart, 'Stage should NOT be startable when ANY dependency not met');
        System.assertEquals(1, result.blockingDependencies.size(), 'Should have 1 blocking dependency');
    }

    @isTest
    static void testCanStartStage_CUSTOM_Logic() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 AND Stage 2 (CUSTOM defaults to ALL)
        createStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            'CUSTOM',
            true
        );

        // Complete both stages
        createStageCompletion(vendorProgram.Id, process.Id, stages[0].Id);
        createStageCompletion(vendorProgram.Id, process.Id, stages[1].Id);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when CUSTOM dependencies met (defaults to ALL)');
    }

    @isTest
    static void testCanStartStage_NotRequiredDependency() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1, but dependency is not required
        createStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id },
            'ALL',
            false
        );

        // Don't complete Stage 1

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when dependency is not required');
        System.assertEquals(0, result.blockingDependencies.size(), 'Should have no blocking dependencies');
    }

    @isTest
    static void testGetDependencyInfo_NoDependencies() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(2);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        Test.startTest();
        List<OnboardingStageDependencyService.DependencyInfo> result = 
            OnboardingStageDependencyService.getDependencyInfo(
                stages[0].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'Should return no dependency info when no dependencies exist');
    }

    @isTest
    static void testGetDependencyInfo_WithDependencies() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(3);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 AND Stage 2
        Onboarding_Application_Stage_Dependency__c dependency = createStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            'ALL',
            true
        );

        // Complete Stage 1 only
        createStageCompletion(vendorProgram.Id, process.Id, stages[0].Id);

        Test.startTest();
        List<OnboardingStageDependencyService.DependencyInfo> result = 
            OnboardingStageDependencyService.getDependencyInfo(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(1, result.size(), 'Should return 1 dependency info');
        System.assertEquals(dependency.Id, result[0].dependencyId, 'Dependency ID should match');
        System.assertEquals('ALL', result[0].logicType, 'Logic type should be ALL');
        System.assertEquals(2, result[0].requiredStageIds.size(), 'Should require 2 stages');
        System.assertEquals(1, result[0].completedStageIds.size(), 'Should have 1 completed stage');
        System.assertEquals(1, result[0].missingStageIds.size(), 'Should have 1 missing stage');
    }

    @isTest
    static void testCanStartStage_MultipleDependencies() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(4);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create first dependency: Stage 4 requires Stage 1 AND Stage 2
        createStageDependency(
            stages[3].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            'ALL',
            true
        );

        // Create second dependency: Stage 4 requires Stage 3
        createStageDependency(
            stages[3].Id,
            new List<Id>{ stages[2].Id },
            'ALL',
            true
        );

        // Complete Stage 1 and Stage 2, but not Stage 3
        createStageCompletion(vendorProgram.Id, process.Id, stages[0].Id);
        createStageCompletion(vendorProgram.Id, process.Id, stages[1].Id);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[3].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.canStart, 'Stage should NOT be startable when multiple dependencies not met');
        System.assertEquals(2, result.blockingDependencies.size(), 'Should have 2 blocking dependencies');
    }

    @isTest
    static void testCanStartStage_EmptyRequiredStages() {
        // Arrange
        Onboarding_Application_Process__c process = createTestProcessWithStages(2);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency with no required stages (empty members)
        createStageDependency(
            stages[1].Id,
            null, // No required stages
            'ALL',
            true
        );

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[1].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when dependency has no required stages');
    }
}



