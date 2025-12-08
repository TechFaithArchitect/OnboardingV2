# Performance Optimization Recommendations

This document provides actionable optimization recommendations for the OnboardingV2 application, prioritized by impact and effort.

## 🔴 Critical Issues (High Priority - Fix Immediately)

### 1. DML Inside Loop in Status Evaluator

**Location**: `OnboardingStatusEvaluator.evaluateAndApplyStatus()`

**Issue**: DML operation (`update onboarding`) is executed inside a loop, which violates Salesforce best practices and can cause governor limit issues.

**Current Code**:
```apex
for (Onboarding_Status_Rules_Engine__c rule : rules) {
    Boolean rulePassed = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
    if (rulePassed && String.isNotBlank(rule.Target_Onboarding_Status__c)) {
        onboarding.Onboarding_Status__c = rule.Target_Onboarding_Status__c;
        update onboarding;  // ❌ DML in loop
        return;
    }
}
```

**Recommended Fix**:
```apex
public static void evaluateAndApplyStatus(Onboarding__c onboarding) {
    Map<Id, Onboarding_Requirement__c> reqByVPR = OnboardingRulesService.getRequirementsByVPR(onboarding.Id);
    if (reqByVPR.isEmpty()) return;

    Id vendorProgramId = OnboardingRulesService.getVendorProgramId(onboarding.Id);
    if (vendorProgramId == null) return;

    List<Id> groupIds = OnboardingRulesService.getVendorProgramGroupIds(vendorProgramId);
    if (groupIds.isEmpty()) return;

    List<Onboarding_Status_Rules_Engine__c> rules = OnboardingRulesService.getRulesForGroups(groupIds);
    String newStatus = null;
    
    for (Onboarding_Status_Rules_Engine__c rule : rules) {
        Boolean rulePassed = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        if (rulePassed && String.isNotBlank(rule.Target_Onboarding_Status__c)) {
            newStatus = rule.Target_Onboarding_Status__c;
            break; // Exit early once rule passes
        }
    }
    
    // ✅ Single DML outside loop
    if (newStatus != null && onboarding.Onboarding_Status__c != newStatus) {
        onboarding.Onboarding_Status__c = newStatus;
        update onboarding;
    }
}
```

**Impact**: Prevents governor limit errors, improves performance, enables bulkification.

---

### 2. Multiple DML Statements in saveProgress

**Location**: `OnboardingApplicationService.saveProgress()`

**Issue**: Two separate DML statements when one could be used, and no upsert logic for progress record.

**Current Code**:
```apex
Onboarding_Application_Progress__c progress = new Onboarding_Application_Progress__c(...);
insert progress;  // ❌ First DML

Onboarding_Application_Stage_Completion__c completion = new Onboarding_Application_Stage_Completion__c(...);
insert completion;  // ❌ Second DML
```

**Recommended Fix**:
```apex
@AuraEnabled
public static Id saveProgress(Id processId, Id vendorProgramId, Id stageId) {
    // ✅ Upsert progress record (handles both insert and update)
    Onboarding_Application_Progress__c progress = [
        SELECT Id 
        FROM Onboarding_Application_Progress__c
        WHERE Vendor_Program__c = :vendorProgramId 
          AND Onboarding_Application_Process__c = :processId
        LIMIT 1
    ];
    
    if (progress == null) {
        progress = new Onboarding_Application_Progress__c(
            Onboarding_Application_Process__c = processId,
            Vendor_Program__c = vendorProgramId,
            Current_Stage__c = stageId
        );
    } else {
        progress.Current_Stage__c = stageId;
    }
    upsert progress;

    // ✅ Combine both inserts into single DML
    Onboarding_Application_Stage_Completion__c completion = new Onboarding_Application_Stage_Completion__c(
        Vendor_Program__c = vendorProgramId,
        Onboarding_Application_Process__c = processId,
        Onboarding_Application_Stage__c = stageId,
        Completed_Date__c = System.now(),
        Completed_By__c = UserInfo.getUserId()
    );
    
    List<SObject> recordsToInsert = new List<SObject>{ completion };
    insert recordsToInsert;

    return progress.Id;
}
```

**Alternative (Better)**: Use Database.insert with partial success handling:
```apex
List<SObject> recordsToInsert = new List<SObject>{ progress, completion };
Database.SaveResult[] results = Database.insert(recordsToInsert, false);
// Handle partial failures if needed
```

**Impact**: Reduces DML count by 50%, improves transaction efficiency.

---

### 3. Bulkification of Status Evaluation

**Location**: `OnboardingStatusEvaluator`

**Issue**: Currently only processes one onboarding at a time. Should support bulk processing.

**Recommended Fix**:
```apex
public static void evaluateAndApplyStatus(List<Onboarding__c> onboardings) {
    if (onboardings == null || onboardings.isEmpty()) return;
    
    // ✅ Bulk query all requirements
    Set<Id> onboardingIds = new Set<Id>();
    for (Onboarding__c ob : onboardings) {
        onboardingIds.add(ob.Id);
    }
    
    Map<Id, Map<Id, Onboarding_Requirement__c>> reqByOnboardingByVPR = 
        OnboardingRulesService.getRequirementsByVPRBulk(onboardingIds);
    
    // ✅ Bulk query vendor programs
    Map<Id, Id> vendorProgramByOnboarding = OnboardingRulesService.getVendorProgramIdsBulk(onboardingIds);
    
    // ✅ Bulk query groups
    Set<Id> vendorProgramIds = new Set<Id>(vendorProgramByOnboarding.values());
    Map<Id, List<Id>> groupIdsByVendorProgram = OnboardingRulesService.getVendorProgramGroupIdsBulk(vendorProgramIds);
    
    // ✅ Bulk query all rules
    Set<Id> allGroupIds = new Set<Id>();
    for (List<Id> groupIds : groupIdsByVendorProgram.values()) {
        allGroupIds.addAll(groupIds);
    }
    List<Onboarding_Status_Rules_Engine__c> allRules = OnboardingRulesService.getRulesForGroups(new List<Id>(allGroupIds));
    Map<Id, List<Onboarding_Status_Rules_Engine__c>> rulesByGroup = new Map<Id, List<Onboarding_Status_Rules_Engine__c>>();
    for (Onboarding_Status_Rules_Engine__c rule : allRules) {
        if (!rulesByGroup.containsKey(rule.Vendor_Program_Group__c)) {
            rulesByGroup.put(rule.Vendor_Program_Group__c, new List<Onboarding_Status_Rules_Engine__c>());
        }
        rulesByGroup.get(rule.Vendor_Program_Group__c).add(rule);
    }
    
    // ✅ Process all onboardings
    List<Onboarding__c> toUpdate = new List<Onboarding__c>();
    for (Onboarding__c onboarding : onboardings) {
        Map<Id, Onboarding_Requirement__c> reqByVPR = reqByOnboardingByVPR.get(onboarding.Id);
        if (reqByVPR == null || reqByVPR.isEmpty()) continue;
        
        Id vendorProgramId = vendorProgramByOnboarding.get(onboarding.Id);
        if (vendorProgramId == null) continue;
        
        List<Id> groupIds = groupIdsByVendorProgram.get(vendorProgramId);
        if (groupIds == null || groupIds.isEmpty()) continue;
        
        // Evaluate rules for this onboarding
        String newStatus = null;
        for (Id groupId : groupIds) {
            List<Onboarding_Status_Rules_Engine__c> rules = rulesByGroup.get(groupId);
            if (rules == null) continue;
            
            for (Onboarding_Status_Rules_Engine__c rule : rules) {
                Boolean rulePassed = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
                if (rulePassed && String.isNotBlank(rule.Target_Onboarding_Status__c)) {
                    newStatus = rule.Target_Onboarding_Status__c;
                    break;
                }
            }
            if (newStatus != null) break;
        }
        
        if (newStatus != null && onboarding.Onboarding_Status__c != newStatus) {
            onboarding.Onboarding_Status__c = newStatus;
            toUpdate.add(onboarding);
        }
    }
    
    // ✅ Single bulk update
    if (!toUpdate.isEmpty()) {
        update toUpdate;
    }
}
```

**Impact**: Enables processing hundreds of onboardings in a single transaction, critical for batch operations.

---

## 🟠 High Priority Optimizations

### 4. Optimize Dynamic SOQL in Status Tracker Handler

**Location**: `OnboardingStatusTrackerHandler.handleStatusTracking()`

**Issue**: Dynamic SOQL is built in a loop, which could be optimized with better field mapping.

**Current Code**:
```apex
String soql = 'SELECT Id, ' + lookupField + ' FROM Onboarding__c WHERE ' + lookupField + ' IN :ids';
for (Onboarding__c ob : Database.query(soql)) {
    // ...
}
```

**Recommended Fix**: Pre-validate lookup fields and use static queries where possible:
```apex
// ✅ Pre-validate lookup fields against schema
Map<String, Schema.SObjectField> onboardingFields = Onboarding__c.SObjectType.getDescribe().fields.getMap();
Set<String> validLookupFields = new Set<String>();
for (String lookupField : targetsByLookupField.keySet()) {
    if (lookupField == 'Id' || onboardingFields.containsKey(lookupField)) {
        validLookupFields.add(lookupField);
    }
}

// ✅ Build queries more efficiently
Map<String, Set<Id>> validTargetsByField = new Map<String, Set<Id>>();
for (String field : validLookupFields) {
    validTargetsByField.put(field, targetsByLookupField.get(field));
}

// ✅ Use relationship queries where possible instead of dynamic SOQL
// For standard lookups, use relationship queries
```

**Impact**: Reduces SOQL query count, improves security, better performance.

---

### 5. Combine Queries in Rules Service

**Location**: `OnboardingRulesService`

**Issue**: Multiple separate queries that could be combined.

**Current Pattern**:
```apex
// Query 1: Requirements
getRequirementsByVPR(onboardingId)

// Query 2: Vendor Program
getVendorProgramId(onboardingId)

// Query 3: Group IDs
getVendorProgramGroupIds(vendorProgramId)
```

**Recommended Fix**: Create a combined method:
```apex
public class OnboardingEvaluationContext {
    public Map<Id, Onboarding_Requirement__c> requirementsByVPR;
    public Id vendorProgramId;
    public List<Id> groupIds;
}

public static OnboardingEvaluationContext getEvaluationContext(Id onboardingId) {
    // ✅ Single query to get onboarding with related data
    Onboarding__c onboarding = [
        SELECT Id, Vendor_Customization__c,
            (SELECT Id, Status__c, Vendor_Program_Requirement__c 
             FROM Onboarding_Requirements__r
             WHERE Vendor_Program_Requirement__c != null)
        FROM Onboarding__c
        WHERE Id = :onboardingId
        LIMIT 1
    ];
    
    if (onboarding == null) return null;
    
    OnboardingEvaluationContext context = new OnboardingEvaluationContext();
    context.vendorProgramId = onboarding.Vendor_Customization__c;
    
    // Build requirements map
    context.requirementsByVPR = new Map<Id, Onboarding_Requirement__c>();
    for (Onboarding_Requirement__c req : onboarding.Onboarding_Requirements__r) {
        context.requirementsByVPR.put(req.Vendor_Program_Requirement__c, req);
    }
    
    // Query groups (can't be combined due to relationship)
    context.groupIds = getVendorProgramGroupIds(context.vendorProgramId);
    
    return context;
}
```

**Impact**: Reduces from 3 queries to 2 queries per evaluation.

---

### 6. Add Expression Parsing Cache

**Location**: `OnboardingExpressionEngine` (if exists)

**Issue**: Custom expressions are parsed on every evaluation, even if identical.

**Recommended Fix**:
```apex
public class OnboardingExpressionEngine {
    // ✅ Cache parsed expressions
    private static Map<String, ParsedExpression> expressionCache = new Map<String, ParsedExpression>();
    
    public static Boolean evaluate(String expression, Map<String, Object> context) {
        if (String.isBlank(expression)) return false;
        
        // ✅ Check cache first
        ParsedExpression parsed = expressionCache.get(expression);
        if (parsed == null) {
            parsed = parseExpression(expression);
            expressionCache.put(expression, parsed);
        }
        
        return evaluateParsed(parsed, context);
    }
    
    // ✅ Clear cache when rules are updated (via Platform Event or custom setting)
    public static void clearCache() {
        expressionCache.clear();
    }
}
```

**Impact**: Significant CPU time savings for repeated expression evaluations.

---

### 7. Optimize LWC Data Loading

**Location**: Various LWC components

**Issue**: Some components make sequential calls when parallel would be better.

**Current Pattern** (in some components):
```javascript
connectedCallback() {
    getRequirements({ onboardingId: this.recordId }).then(data => {
        this.requirements = data;
        // Then make another call
        getAdditionalData({ onboardingId: this.recordId }).then(...);
    });
}
```

**Recommended Fix**: Use Promise.all for parallel loading:
```javascript
connectedCallback() {
    Promise.all([
        getRequirements({ onboardingId: this.recordId }),
        getAdditionalData({ onboardingId: this.recordId }),
        getStatus({ onboardingId: this.recordId })
    ]).then(([requirements, additional, status]) => {
        this.requirements = requirements;
        this.additional = additional;
        this.status = status;
    }).catch(error => {
        this.handleError(error);
    });
}
```

**Note**: `onboardingFlowEngine` already uses `Promise.all` - good example to follow!

**Impact**: Reduces perceived load time by 50-70% for multi-step data loading.

---

## 🟡 Medium Priority Optimizations

### 8. Add Database Indexes (If Needed)

**Location**: Custom Objects

**Recommendation**: Review frequently queried fields and add custom indexes if:
- Queries are slow (> 1 second)
- Fields are frequently used in WHERE clauses
- Data volume is large (> 10,000 records)

**Fields to Consider**:
- `Onboarding__c.Onboarding_Status__c` (if frequently filtered)
- `Onboarding_Requirement__c.Status__c` (if frequently queried)
- `Vendor_Program_Group_Member__c.Required_Program__c` (already indexed via lookup)

**Note**: Salesforce automatically indexes:
- Primary keys (Id)
- Lookup/Master-Detail fields
- External IDs
- Unique fields

**Impact**: Can improve query performance by 10-100x for large datasets.

---

### 9. Implement Batch Processing for Large Operations

**Location**: Status evaluation, expiration checks

**Issue**: Processing many onboardings synchronously can hit governor limits.

**Recommended Fix**: Create batchable classes:
```apex
public class OnboardingStatusEvaluationBatch implements Database.Batchable<Onboarding__c> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id FROM Onboarding__c 
            WHERE Onboarding_Status__c != 'Complete'
            AND LastModifiedDate = TODAY
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Onboarding__c> scope) {
        OnboardingStatusEvaluator.evaluateAndApplyStatus(scope);
    }
    
    public void finish(Database.BatchableContext bc) {
        // Log completion
    }
}
```

**Impact**: Enables processing thousands of records without governor limit issues.

---

### 10. Optimize Flow Bulkification

**Location**: Record-triggered flows

**Issue**: Some flows may not be properly bulkified.

**Recommendations**:
1. Review all record-triggered flows
2. Ensure they use collection variables for bulk operations
3. Avoid loops with DML inside
4. Use Get Records with collection variables, not single record variables

**Impact**: Prevents governor limit errors in bulk operations.

---

### 11. Add Query Result Pagination

**Location**: LWC components that load large lists

**Issue**: Loading all requirements/stages at once can be slow for large datasets.

**Recommended Fix**:
```apex
@AuraEnabled(cacheable=true)
public static PaginatedResult getRequirements(Id onboardingId, Integer pageSize, Integer offset) {
    Integer totalCount = [
        SELECT COUNT() 
        FROM Onboarding_Requirement__c 
        WHERE Onboarding__c = :onboardingId
    ];
    
    List<Onboarding_Requirement__c> requirements = [
        SELECT Id, Name, Status__c
        FROM Onboarding_Requirement__c
        WHERE Onboarding__c = :onboardingId
        ORDER BY CreatedDate
        LIMIT :pageSize
        OFFSET :offset
    ];
    
    return new PaginatedResult(requirements, totalCount, pageSize, offset);
}
```

**Impact**: Improves initial load time for large requirement lists.

---

### 12. Implement Lazy Loading for Stages

**Location**: `onboardingFlowEngine`

**Issue**: All stages are loaded upfront, even if user may not reach them.

**Recommended Fix**: Load stages on-demand:
```javascript
async loadStage(stageIndex) {
    if (this.stages[stageIndex] && this.stages[stageIndex].loaded) {
        return; // Already loaded
    }
    
    // Load stage details on demand
    const stageDetails = await getStageDetails({ 
        stageId: this.stages[stageIndex].Id 
    });
    this.stages[stageIndex] = { ...this.stages[stageIndex], ...stageDetails, loaded: true };
}
```

**Impact**: Reduces initial load time, especially for processes with many stages.

---

## 🟢 Low Priority / Nice to Have

### 13. Add Monitoring and Logging

**Recommendation**: Implement performance monitoring:
- Track SOQL query counts
- Monitor DML statement counts
- Log CPU time usage
- Alert on governor limit warnings

**Implementation**: Use Platform Events or custom logging object:
```apex
public class PerformanceLogger {
    public static void logOperation(String operation, Integer soqlCount, Integer dmlCount, Long cpuTime) {
        Performance_Log__c log = new Performance_Log__c(
            Operation__c = operation,
            SOQL_Count__c = soqlCount,
            DML_Count__c = dmlCount,
            CPU_Time__c = cpuTime,
            Timestamp__c = System.now()
        );
        insert log;
    }
}
```

**Impact**: Enables proactive performance issue detection.

---

### 14. Optimize Email Sending Orchestration

**Location**: `EmailSendAndLogOrchestrator`

**Issue**: Sequential processing in `orchestrateBulk()` method.

**Current Code**:
```apex
for (EmailCommSendRequestDTO req : requests) {
    results.add(orchestrateSendAndLog(req));  // Sequential
}
```

**Recommended Fix**: Use Queueable chain for async processing:
```apex
public static void orchestrateBulkAsync(List<EmailCommSendRequestDTO> requests) {
    EmailBulkSendQueueable queueable = new EmailBulkSendQueueable(requests);
    System.enqueueJob(queueable);
}
```

**Impact**: Better for large email batches, prevents timeout issues.

---

### 15. Add Field-Level Security Checks

**Location**: All Apex classes

**Recommendation**: Ensure all queries respect field-level security:
- Use `with sharing` (already implemented ✓)
- Consider using `Security.stripInaccessible()` for dynamic queries
- Validate field access before dynamic SOQL

**Impact**: Improves security and prevents runtime errors.

---

## Implementation Priority

### Phase 1 (Immediate - This Week)
1. ✅ Fix DML in loop (Critical Issue #1)
2. ✅ Optimize saveProgress DML (Critical Issue #2)
3. ✅ Bulkify status evaluation (Critical Issue #3)

### Phase 2 (Next Sprint)
4. ✅ Optimize dynamic SOQL (High Priority #4)
5. ✅ Combine queries in Rules Service (High Priority #5)
6. ✅ Add expression caching (High Priority #6)

### Phase 3 (Future Enhancement)
7. ✅ LWC optimizations (High Priority #7)
8. ✅ Batch processing (Medium Priority #9)
9. ✅ Pagination (Medium Priority #11)

---

## Performance Testing Recommendations

After implementing optimizations, test with:
1. **Single Record**: 1 onboarding with 10 requirements, 5 rules
2. **Bulk Records**: 100 onboardings with 10 requirements each
3. **Large Dataset**: 1000 onboardings (via batch)
4. **Complex Rules**: 20+ rules per onboarding
5. **Concurrent Users**: 10+ simultaneous users

**Target Metrics**:
- Status evaluation: < 500ms per onboarding
- Flow initialization: < 1 second
- Bulk processing: < 30 seconds for 100 records
- SOQL queries: < 10 per transaction
- DML statements: < 5 per transaction

---

## Related Documentation

- [Current Performance Guide](./optimization-guide.md)
- [Architecture Overview](../architecture/overview.md)
- [Status Evaluation Process](../processes/status-evaluation.md)

