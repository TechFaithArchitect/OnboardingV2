@isTest
public with sharing class POE_DispositionControllerTest {
    private static final String TEST_NAME = 'Test';
    private static final String TASK_SUBJECT = 'Test task';
    private static final String TASK_STATUS = 'Open';

    @TestSetup
    static void makeData() {
        Account testAccount = new Account(
            Name = TEST_NAME
        );
        insert testAccount;

        testAccount = [SELECT Id FROM Account LIMIT 1];
        Task testTask = new Task(
            WhatId = testAccount.Id,
            ActivityDate = Date.today(),
            Subject = TASK_SUBJECT,
            Status = TASK_STATUS
        );
        insert testTask;
    }

    @isTest
    public static void testGetTasks() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Task> result = POE_DispositionController.getTasks(testAccount.Id);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'testGetTasks');
    }
}