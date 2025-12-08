# Phase 0.6: Follow-Up Retry Automation Setup Guide

## Overview
This guide documents the Apex trigger-based retry automation for failed follow-up messages. The implementation uses an Apex trigger for better bulk processing performance.

## Apex Trigger Implementation

### Components Created

1. **Trigger**: `FollowUpQueueTrigger`
   - **Object**: `Follow_Up_Queue__c`
   - **Event**: `after update`
   - **Handler**: `FollowUpQueueTriggerHandler.handleAfterUpdate()`

2. **Handler Class**: `FollowUpQueueTriggerHandler`
   - Implements retry eligibility checks
   - Calculates exponential backoff delays
   - Updates follow-up records
   - Publishes Platform Events for async processing

### Retry Logic

#### Eligibility Criteria
- `Status__c` must change to `'Failed'`
- `Attempt_Count__c` must be less than `3`
- `Last_Attempt_Date__c` must be at least 1 hour ago

#### Exponential Backoff Schedule
- **1st retry**: 1 hour after failure
- **2nd retry**: 4 hours after first retry
- **3rd retry**: 12 hours after second retry
- **Maximum**: 3 retry attempts

#### Process Flow

```
Follow_Up_Queue__c.Status__c → 'Failed'
  ↓
Trigger fires (after update)
  ↓
FollowUpQueueTriggerHandler.handleAfterUpdate()
  ↓
Check retry eligibility
  ├─ Eligible → Calculate next retry date
  │              ↓
  │              Update Status__c = 'Pending Retry'
  │              Update Next_Attempt_Date__c
  │              ↓
  │              Publish FollowUpRetryTrigger__e Platform Event
  │              ↓
  │              FollowUpRetryHandler.handleRetry() (async)
  │              ↓
  │              FollowUpExecutionService.retryFailedFollowUps()
  │
  └─ Not Eligible → No action
```

### Testing Checklist

- [ ] Trigger fires when `Status__c` changes to `'Failed'`
- [ ] Trigger does not fire if status was already `'Failed'`
- [ ] Retry is skipped if `Attempt_Count__c >= 3`
- [ ] Retry is skipped if `Last_Attempt_Date__c` is less than 1 hour ago
- [ ] `Next_Attempt_Date__c` is calculated correctly based on attempt count
- [ ] Platform Event is published with correct data
- [ ] `FollowUpRetryHandler` receives and processes the event
- [ ] Retry logic executes successfully
- [ ] Bulk processing works correctly (200+ records)

### Benefits of Apex Trigger Approach

- **Bulk Processing**: Handles large batches efficiently (200+ records)
- **Performance**: No governor limits from Flow iterations
- **Maintainability**: Logic is in code, easier to version control
- **Flexibility**: Easy to add complex business logic
- **Testing**: Full test coverage with Apex test classes

### Configuration

All retry logic is configured in the database:
- Retry eligibility checks use fields on `Follow_Up_Queue__c`
- Exponential backoff delays are calculated in code (can be moved to Custom Metadata if needed)
- Maximum retry attempts: 3 (hardcoded, can be made configurable)

### Future Enhancements

- Move retry delays to Custom Metadata Type for configuration
- Add retry attempt limits per follow-up type
- Add timezone-aware retry scheduling
- Add retry suppression rules (fatigue logic)


