---
name: buid-8
description: Implements Ticket 8 by instrumenting Wish Match funnel analytics events through a dedicated analytics service and resilient event calls from repository and UI. Use when user requests /buid-8 or Ticket 8 analytics instrumentation.
---

# /buid-8

## Purpose

Implement `TICKET 8`: analytics for Wish Match funnel.

## Target

- New file: `lib/services/analytics_service.dart`
- Integrations:
  - `lib/services/wishes_repository.dart`
  - `lib/screen/wishes_screen.dart`

## Required changes

1. Add analytics abstraction service.
2. Track events:
   - `wish_created_secret`
   - `wish_matched`
   - `wish_status_changed`
   - `wish_soft_suggestion_sent`
3. Add resilient tracking:
   - analytics failure must not break UX.
4. Keep payload minimal and privacy-safe.

## Implementation checklist

- [ ] Service API designed and documented in code
- [ ] Event calls wired in key flow points
- [ ] Failures are caught/logged safely
- [ ] No sensitive free-text leaks in payload

## Validation

1. Run `flutter analyze`.
2. Execute happy-path flow and verify all events are emitted.
3. Simulate analytics failure and confirm UI still works.

## Done criteria

- Full funnel instrumentation is available and stable.
