# Vendor Program Onboarding - End User UX Improvement Plan

**Date:** November 2025  
**Focus:** Simplifying the user experience for end users (non-technical users, reps, dealers)

## Overview

This document outlines a comprehensive UX improvement plan to make the Vendor Program Onboarding Wizard intuitive and user-friendly for end users. The goal is to hide technical complexity and present a clean, guided experience.

---

## 1. Simplify Statuses for End Users

### Current State
- Technical statuses: "Draft", "In Process", "Pending Review", "Complete", etc.
- Internal sub-statuses visible to all users
- Complex status evaluation logic exposed

### Target State
**User-Facing Stages:**
- 🟡 **In Progress** - Work is ongoing
- 🟠 **Review Pending** - Waiting for approval/review
- 🟢 **Completed** - Finished and approved

**Implementation:**
- Create status mapping utility
- Display simplified stages in wizard UI
- Hide technical sub-statuses from end users
- Show detailed statuses only to admins (via permission/role check)

**Status Mapping:**
```
Technical Status          → User-Facing Stage
─────────────────────────────────────────────
Draft                    → In Progress
In Process               → In Progress
Pending Review           → Review Pending
Pending Approval         → Review Pending
Complete                 → Completed
Active                   → Completed
```

**Files to Create/Modify:**
- `VendorProgramStatusMapper.cls` - Status mapping utility for Vendor Programs only (renamed from `OnboardingApplicationStatusMapper`)
- `onboardingFlowEngine.js` - Add status simplification logic
- `onboardingFlowEngine.html` - Update progress indicator with user-friendly stages

---

## 2. Add Contextual Guidance Inline

### Current State
- Compact info boxes added (good start)
- Some guidance in info boxes
- Limited inline help

### Target State
**Enhanced Guidance:**
- **Tooltips** on field labels explaining what each field means
- **Helper text** below fields with examples
- **"Need help?" links** that expand context panels
- **Inline validation** with helpful error messages
- **Placeholder examples** showing expected format

**Implementation:**
- Add `lightning-helptext` components to all field labels
- Add helper text with examples under each input
- Create expandable help panels for each step
- Use friendly, non-technical language

**Example:**
- Add tooltips to all form fields
- Show examples in placeholders
- Add helper text explaining "Why we need this" and "What to enter"

**Files to Modify:**
- All 14 wizard step components
- Add help text for each field
- Create reusable help content library

---

## 3. Visual Progress Indicators

### Current State
- Progress indicator shows all steps
- Shows current step with dots
- Not collapsible

### Target State
**Enhanced Progress Indicator:**
- **Step counter** - "Step 3 of 14"
- **Progress percentage** - "21% Complete"
- **Completion badges** - Checkmarks for completed steps
- **Collapsible sections** - Allow users to minimize completed sections
- **Interactive steps** - Click to jump back to previous steps
- **Summary view** - Quick overview of what's done vs. what's left

**Visual Design:**
```
Vendor Program Onboarding                  [21% Complete]

Step 3 of 14: Select Vendor Program Group

✓ Step 1: Select Vendor
✓ Step 2: Search or Create Vendor Program
🔄 Step 3: Select Vendor Program Group    ← You are here
○ Step 4: Select Requirement Group
○ Step 5: ...
```

**Files to Modify:**
- `onboardingFlowEngine.js` - Add step counter and completion tracking
- `onboardingFlowEngine.html` - Enhance progress indicator

---

## 4. Auto-Save Everything

### Current State
- Manual save on "Next" button
- Explicit "Save and Resume" functionality
- User must remember to save

### Target State
**Auto-Save Features:**
- **Real-time auto-save** - Save field changes automatically (debounced)
- **Visual save indicator** - Show "Saved" icon when auto-saved
- **Save on blur** - Save when user leaves a field
- **Save on step change** - Save automatically when moving between steps
- **Background save** - Save progress in background without blocking UI

**Implementation:**
- Add debounced auto-save after field changes (2-3 second delay)
- Add visual indicator (checkmark icon) when saved
- Auto-save on step navigation
- Save progress silently without blocking

**Files to Modify:**
- `onboardingFlowEngine.js` - Add auto-save logic with debouncing
- All step components - Add change handlers that trigger auto-save
- Create `AutoSaveMixin` utility for reusable auto-save logic

---

## 5. Build for Collaboration First

### Current State
- Basic ownership tracking (Created By, Last Modified By)
- Limited visibility of who's working on what
- No clear indication of what's left to do

### Target State
**Collaboration Features:**
- **Ownership indicators** - "Assigned to: [Name]" clearly displayed
- **Change tracking** - "Last edited by [Name] on [Date]"
- **Activity feed** - Show recent changes and who made them
- **Task indicators** - "What's left to do" summary
- **Collaborator avatars** - Show who's involved
- **Status badges** - Clear indication of current status

**Implementation:**
- Add ownership display component
- Add change tracking display
- Create activity feed component
- Add "What's Left" summary panel
- Show collaborator list

**Files to Create/Modify:**
- `onboardingCollaborationInfo.js` - Collaboration info component (new)
- `onboardingFlowEngine.js` - Add collaboration data loading
- `onboardingFlowEngine.html` - Add collaboration info panel

---

## 6. Document the Dealer Onboarding Flow

### Current State
- Vendor onboarding well documented
- Dealer onboarding flow less clear
- Need to ensure same UX patterns apply

### Target State
**Documentation:**
- Clear step-by-step guide for dealer onboarding
- Same UX patterns as vendor onboarding
- Simplified status indicators
- Contextual guidance at each step
- Visual progress indicators

**Files to Create:**
- `docs/user-guides/dealer-onboarding-flow.md`
- Update existing dealer onboarding components with same UX improvements

---

## Implementation Status

### Phase 1 (Completed ✅)
1. ✅ **Compact info boxes** - Completed
2. ✅ **Required fields visible** - Completed
3. ✅ **Visual progress indicators** - Step counter, percentage, completion badges added
4. ✅ **Auto-save** - Real-time auto-save with visual indicators implemented

### Phase 2 (Completed ✅)
5. ✅ **Status simplification** - `VendorProgramStatusMapper` created (renamed from `OnboardingApplicationStatusMapper`); maps Vendor Program technical statuses to user-friendly stages (front-end only). **Note**: Only for Vendor Programs, NOT for Dealer Onboarding statuses.
6. ✅ **Enhanced tooltips** - Added `lightning-helptext` to key form fields with contextual guidance
7. ✅ **Helper text examples** - Added example text below inputs showing best practices
8. ✅ **Ownership indicators** - Created/Last Modified by information displayed in wizard header
9. ✅ **Change tracking** - Last edited information with timestamps shown

### Phase 3 (Pending)
10. **Activity feed** - Recent changes summary (future enhancement)
11. **Enhanced collaboration UI** - Better visual display of collaborators

### Phase 4 (Pending - Documentation)
12. **Dealer onboarding documentation** - Complete guide with same UX patterns
13. **User-facing help articles** - End user documentation

---

## Technical Implementation Details

### Status Mapping Utility

```apex
/**
 * ⚠️ IMPORTANT: This mapper is ONLY for Vendor_Customization__c.Status__c (Vendor Onboarding).
 * It does NOT apply to Onboarding__c.Onboarding_Status__c (Dealer Onboarding).
 */
public class VendorProgramStatusMapper {
    public static String getUserFacingStage(String technicalStatus, Boolean isAdmin) {
        if (isAdmin) {
            return technicalStatus; // Show technical status to admins
        }
        
        // Map Vendor Program technical statuses to user-friendly stages
        if (technicalStatus == 'Draft' || technicalStatus == 'In Process') {
            return 'In Progress';
        } else if (technicalStatus == 'Pending Review' || technicalStatus == 'Pending Approval') {
            return 'Review Pending';
        } else if (technicalStatus == 'Complete' || technicalStatus == 'Active') {
            return 'Completed';
        }
        
        return 'In Progress'; // Default
    }
}
```

### Auto-Save Implementation

```javascript
// Auto-save with debouncing
handleFieldChange(event) {
  this.fieldValue = event.target.value;
  
  // Clear existing timeout
  if (this.saveTimeout) {
    clearTimeout(this.saveTimeout);
  }
  
  // Set new timeout for auto-save (2 seconds after last change)
  this.saveTimeout = setTimeout(() => {
    this.autoSave();
  }, 2000);
}

async autoSave() {
  // Save silently without blocking UI
  await saveProgress({
    processId: this.processId,
    vendorProgramId: this.vendorProgramId,
    stageId: this.activeStage?.Id
  });
  
  // Show save indicator
  this.showSaveIndicator();
}
```

### Progress Enhancement

```javascript
get stepCounter() {
  return `Step ${this.activeStageIndex + 1} of ${this.stages.length}`;
}

get completionPercentage() {
  const completed = this.activeStageIndex;
  const total = this.stages.length;
  return Math.round((completed / total) * 100);
}

get completedSteps() {
  return this.stages.slice(0, this.activeStageIndex);
}

get remainingSteps() {
  return this.stages.slice(this.activeStageIndex + 1);
}
```

---

## User-Facing Language Guide

### Replace Technical Terms with Friendly Terms

| Technical Term | User-Friendly Term |
|---------------|-------------------|
| Vendor Program Group | Program Category |
| Requirement Group | Requirements Checklist |
| Recipient Group | Notification Group |
| Status Rules Engine | Approval Rules |
| Evaluation Logic | Approval Type |

### Friendly Error Messages

**Instead of:**
- "Error: Validation failed for Logic_Type__c"
- "Required field missing"

**Use:**
- "Please select how approvals work for this program"
- "We need a few more details to continue"

---

## Next Steps

1. **Review and approve this plan**
2. **Prioritize which improvements to implement first**
3. **Create implementation tickets/issues**
4. **Begin with Phase 1 items** (high impact, quick wins)

---

## Related Documentation

- [Wizard UX Improvements Changelog](./CHANGELOG-wizard-ux-improvements.md)
- [Vendor Program Onboarding Flow](./processes/vendor-program-onboarding-flow.md)
- [Getting Started Guide](./user-guides/getting-started.md)
