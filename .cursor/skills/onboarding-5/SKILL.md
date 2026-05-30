---
name: onboarding-5
description: Implements onboarding Ticket 5 by instrumenting onboarding analytics and drop-off tracking across steps, completion, skip behavior, and first activation actions. Use when user requests /onboarding-5 or onboarding funnel analytics.
---

# /onboarding-5

## Purpose

Implement analytics for onboarding funnel and activation drop-off.

## Target

- `lib/services/analytics_service.dart` (or existing analytics abstraction)
- onboarding UI files
- checklist integration points

## Required events

1. `onboarding_started`
2. `onboarding_step_viewed` (step index/name)
3. `onboarding_next_clicked`
4. `onboarding_skipped`
5. `onboarding_completed`
6. `onboarding_activation_checklist_item_completed`

## Requirements

- Events should be privacy-safe (no sensitive free text).
- Analytics failures must not break UX.
- Keep event payload minimal and consistent.

## Implementation checklist

- [ ] All key onboarding transitions emit events
- [ ] Completion/skip tracked exactly once per session flow
- [ ] Activation checklist events connected
- [ ] Error-safe analytics calls

## Validation

1. Run `flutter analyze`.
2. Manually traverse onboarding:
   - complete path
   - skip path
   - partial drop-off path.
3. Verify event sequence in logs/analytics sink.

## Done criteria

- Onboarding funnel and drop-off points are measurable.
