---
name: onboarding-3
description: Implements onboarding Ticket 3 by adding an in-app quick-start checklist that guides users through first meaningful actions after onboarding. Use when user requests /onboarding-3 or asks for first-run activation checklist.
---

# /onboarding-3

## Purpose

Implement post-onboarding quick-start checklist to drive activation.

## Target

- `lib/screen/` (likely main shell/home-related screen)
- `lib/services/` for checklist completion state

## Required checklist items

1. Connect partner.
2. Add first secret wish.
3. Complete first shared action (discuss/planned/done).

## Behavior

- Show checklist until all items are done or user dismisses.
- Each item has direct CTA deep-linking to the right screen.
- Show progress (e.g., `1/3 done`).

## Implementation checklist

- [ ] Checklist visibility state persists
- [ ] Completion is computed from real data/events
- [ ] CTA navigation works to target screens
- [ ] Completed checklist state is stable across app restarts

## Validation

1. Run `flutter analyze`.
2. Verify each checklist item completes when corresponding action is done.
3. Verify progress updates without manual refresh.

## Done criteria

- First-time users are guided to activation milestones.
