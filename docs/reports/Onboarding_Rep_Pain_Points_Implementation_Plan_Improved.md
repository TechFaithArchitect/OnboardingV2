# Onboarding Pain Point Implementation Plan

### (Enhanced with Salesforce Best Practices, Scalability Patterns & Secure Architecture)

---

## 🔥 Objective

Transform onboarding into a **self-correcting, guided workflow** that:

1. Eliminates form restarts with *field‑level validation and correction*
2. Automates communication with *event‑driven follow‑up & SMS escalation*
3. Enables future integration with Adobe *for PDF prefill, e‑sign, & return mapping*

This version builds on the original plan and enhances it using **Salesforce platform best practices** — including Platform Events, Custom Metadata, Shield Security, Feature Toggles, and decoupled Apex architecture.

---

---

# Phase 1 — Sub‑Step Decomposition & Field‑Level Validation

> Goal: Only fix what's wrong — not the entire form.

### New Objects (Improved)

| Object                                     | Purpose                                                           |
| ------------------------------------------ | ----------------------------------------------------------------- |
| `Requirement_Field__c`                     | Defines the specific data fields required within a requirement    |
| `Requirement_Field_Group__c` ⭐             | Logical grouping of fields for UX display + batch validation      |
| `Requirement_Field_Value__c`               | Stores vendor responses + encryption support                      |
| `Requirement_Field_Validation_Rule__mdt` ⭐ | Validation logic stored as metadata — no code deployment required |

> 🆕 Key improvement — validations are metadata‑driven instead of hardcoded.

---

### Architecture Best Practices Applied

| Improvement                               | Benefit                                |
| ----------------------------------------- | -------------------------------------- |
| Platform Events for async validation      | Faster UX, no long‑running saves       |
| Queueable Apex fallback                   | Handles high volume + retry logic      |
| Shield Field Encryption (not Apex crypto) | Native security + searchable fields    |
| FLS enforcement in all services           | Prevents unauthorized read/write       |
| Dynamic Forms or LWC rendering by group   | Flexible UX + no layout changes needed |

---

### Component & Services

| Layer                   | Component                                                  |
| ----------------------- | ---------------------------------------------------------- |
| Apex Business Service   | `RequirementFieldValidationService.cls`                    |
| Platform Event Handler  | `RequirementValidationPlatformEventHandler.cls`            |
| UI                      | `requirementValidationPanel` LWC (expanded field‑level UI) |
| Invocable Apex for Flow | `ValidateRequirementFieldsAction.cls`                      |

---

### User Flow

1. Dealer enters fields in onboarding UI
2. Save fires Platform Event: `RequirementValidationEvent__e`
3. Validation service runs asynchronously
4. Only invalid fields return with status = `Needs_Correction`
5. Dealer is guided to fix *just those fields*

> 🟢 No restarts.
> 🔥 Just‑in‑time error messaging.

---

---

# Phase 2 — Automated Follow‑Up Queue (SMS/Email/In‑App)

> Goal: Stop waiting — follow up automatically and relentlessly.

### New Objects (Improved)

| Object                         | Purpose                                                |
| ------------------------------ | ------------------------------------------------------ |
| `Follow_Up_Queue__c`           | Queue of pending vendor follow‑ups                     |
| `Follow_Up_Rule__mdt` ⭐        | Configurable escalation logic (no deployment required) |
| `Follow_Up_Suppression__mdt` ⭐ | Temporarily pause outreach (holidays/throttle control) |

---

### Event‑Driven Follow‑Up System

| Trigger Source                       | Example                                      |
| ------------------------------------ | -------------------------------------------- |
| No progress on requirement           | "Background Check Started but not Submitted" |
| Field corrections requested but idle | Dealer hasn’t fixed flagged fields           |
| Stalled onboarding > X days          | Follow‑up escalates automatically            |

---

### Best Practice Enhancements

| Improvement                                           | Benefit                                   |
| ----------------------------------------------------- | ----------------------------------------- |
| Replace scheduler‑only execution with Platform Events | Near real‑time reminders                  |
| Flows orchestrate escalation logic                    | Admin‑manageable, low‑code futureproofing |
| Twilio via External Services not custom Apex          | Fewer endpoints to maintain               |

> Apex only handles event logic — Flow handles escalation, retry rules, and suppression logic.

---

### Execution Pattern

```
Event -> Flow -> Queue Record -> Twilio SMS / Email / In-App Alert
                         ↑
          CM Metadata defines timing, escalation, channel
```

Scales to millions of follow‑ups without governor risk.

---

---

# Phase 3 — Adobe Integration Architecture

> Goal: Generate PDFs → send to vendor → capture signature → push fields back into Salesforce.

### New Object Structure

| Object                   | Purpose                                                    |
| ------------------------ | ---------------------------------------------------------- |
| `Form_Data_Staging__c`   | Temporary storage for outbound/inbound JSON to Adobe       |
| `FormMappingRule__mdt` ⭐ | Defines mapping between Adobe fields ←→ Requirement Fields |
| `AdobeSyncFailure__c`    | Logging for failed pushes/pulls (support‑ready visibility) |

---

### Best‑Practice Adobe Integration

| Feature                      | Method                                                          |
| ---------------------------- | --------------------------------------------------------------- |
| Prefill                      | `External Services` schema → JSON build from Requirement Fields |
| Push Form Data               | `AdobeFormAPI.cls` (invocable by Flow)                          |
| Webhook Return (signature) ⭐ | Adobe → Platform Event → Mapping Service                        |
| Retry/Resume                 | Async Queueable job on failure record                           |

---

### Data Flow Diagram

```
Salesforce Fields
      ↓ map via FormMappingRule__mdt
 Form_Data_Staging__c  →  Adobe Document
      ↑ webhook                    ↓
   Signature + Updated Fields return
      ↓ map to Requirement_Field_Value__c
```

Zero manual copy/paste.
Zero form restarts.
Full traceability.

---

---

# Deployment + Governance Model (Upgraded)

| Tooling Enhancement                   | Purpose                                  |
| ------------------------------------- | ---------------------------------------- |
| Feature Flags (`Feature_Toggle__mdt`) | Progressive rollout with rollback safety |
| Permission Set Groups                 | Limit preview access to pilot users      |
| Event Monitoring or Splunk            | Track volume + latency + SMS events      |
| Apex Test Suites                      | Segment automated test runs by feature   |

---

## Rollout Plan by Week

| Week  | Deliverables                                      |
| ----- | ------------------------------------------------- |
| 1‑2   | Phase 1 objects + metadata + event framework      |
| 3‑4   | Validation Services + UI + Queueable + UX Preview |
| 5     | Field UI Launch (Pilot)                           |
| 6‑7   | Follow‑Up Queue + Rules + Twilio Integration      |
| 8     | Experience Cloud Status + Twilio Live             |
| 9‑10  | Adobe object + schema + mapping builder           |
| 11‑12 | Webhook return + sync + production rollout        |

Each feature is toggle‑controlled — launch safely.

---

---

# Final Summary

This enhanced plan:

| Original                      | Improved                                      |
| ----------------------------- | --------------------------------------------- |
| Validation at save            | Async + metadata + platform events            |
| Follow‑ups manual             | Automated escalations (SMS/Email/In‑App)      |
| Adobe integration theoretical | Full data flow + mapping + signature webhooks |
| Hard‑coded logic              | 100% metadata configurable                    |
| Single‑step failures          | Field‑level corrections only                  |


