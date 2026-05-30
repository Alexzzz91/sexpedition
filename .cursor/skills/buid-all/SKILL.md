---
name: buid-all
description: Orchestrates implementation of Tickets 1 through 8 in sequence with quality gates between stages, then prepares the next onboarding walkthrough phase. Use when user says /buid-all, asks to implement all buid steps, or wants full Wish Match MVP rollout.
---

# /buid-all

## Purpose

Run the full `Wish Match MVP` implementation pipeline end-to-end:

1. `buid` (Ticket 1)
2. `buid-2` (Ticket 2)
3. `buid-3` (Ticket 3)
4. `buid-4` (Ticket 4)
5. `buid-5` (Ticket 5)
6. `buid-6` (Ticket 6)
7. `buid-7` (Ticket 7)
8. `buid-8` (Ticket 8)

After Tickets 1-8 are complete, create a follow-up onboarding implementation plan.

## Execution order and gates

Follow strict sequence. Do not skip gates.

### Stage A: Domain and data foundation

- Execute `buid` then `buid-2`.
- Gate:
  - code compiles
  - `Wish` mapping is backward-compatible
  - repository methods exist and are used.

### Stage B: Matching behavior

- Execute `buid-3`.
- Gate:
  - match algorithm is idempotent
  - no same-author matching
  - duplicate match protection verified.

### Stage C: Product UI

- Execute `buid-4`.
- Gate:
  - tabs and streams behave correctly
  - status actions update data and UI.

### Stage D: Security and infra

- Execute `buid-5` then `buid-6`.
- Gate:
  - rules enforce connection access and immutable fields
  - required indexes exist and queries run without index errors.

### Stage E: Engagement and measurement

- Execute `buid-7` then `buid-8`.
- Gate:
  - soft suggestion CTA works with predictable repeated-click behavior
  - funnel events are emitted and failures are non-blocking.

## Mandatory verification at each stage

1. Run static checks (`flutter analyze`) after substantial edits.
2. Check lints for changed files and fix introduced issues.
3. Validate target behavior for the current stage before proceeding.
4. Keep changes aligned with existing project structure:
   - models in `lib/models/`
   - Firestore logic in `lib/services/`
   - UI in `lib/screen/`
5. Never edit `lib/firebase_options.dart` manually.

## Completion criteria for /buid-all

- Tickets 1-8 are implemented and verified.
- No newly introduced analyzer/lint issues in edited files.
- Wish Match MVP flow works end-to-end:
  - create secret wish
  - match appears
  - discuss/plan/done status flow
  - soft suggestion action
  - analytics events in funnel.

## Next phase after 1-8: onboarding walkthrough

Create a new epic: `Guided Onboarding`.

### Goal

Welcome the user, explain how to use the app, why to use it, and what value they get.

### Minimum scope

1. First-run stepper (3-6 screens):
   - what the app does
   - privacy guarantees
   - how pairing works
   - how Wish Match works
   - first action prompt.
2. Quick-start checklist on home flow:
   - connect partner
   - add first secret wish
   - complete first shared action.
3. "Value framing" copy:
   - benefits for couple connection
   - no-pressure tone
   - clear expected outcomes.

### Suggested tickets for onboarding phase

- `onboarding-1`: model + local completion state
- `onboarding-2`: onboarding UI screens and navigation
- `onboarding-3`: first-run checklist widget
- `onboarding-4`: copywriting pass for value messaging
- `onboarding-5`: onboarding analytics and drop-off tracking
