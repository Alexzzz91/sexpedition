---
name: onboarding-all
description: Orchestrates onboarding rollout from state model to UI, activation checklist, copy pass, and analytics with quality gates between onboarding-1 through onboarding-5. Use when user requests /onboarding-all or full onboarding implementation.
---

# /onboarding-all

## Purpose

Run the full onboarding rollout in sequence:

1. `onboarding-1` (state foundation)
2. `onboarding-2` (welcome flow UI)
3. `onboarding-3` (activation checklist)
4. `onboarding-4` (value messaging pass)
5. `onboarding-5` (analytics instrumentation)

## Stage gates

### Stage A
- Execute `onboarding-1`.
- Gate: app can decide if onboarding should show.

### Stage B
- Execute `onboarding-2`.
- Gate: first-run walkthrough appears once and can complete.

### Stage C
- Execute `onboarding-3`.
- Gate: post-onboarding checklist drives first meaningful actions.

### Stage D
- Execute `onboarding-4`.
- Gate: messaging explains how to use app, why it matters, and user outcomes.

### Stage E
- Execute `onboarding-5`.
- Gate: onboarding funnel and drop-offs are measurable.

## Mandatory verification

1. Run `flutter analyze` after substantial changes.
2. Check lints for edited files and fix introduced issues.
3. Verify no regressions in auth/startup routing.
4. Ensure onboarding logic is backward-compatible for existing users.

## Completion criteria

- New user gets clear guided onboarding.
- Existing users are not forced through onboarding unexpectedly.
- Activation checklist is functional.
- Onboarding copy communicates purpose, usage, and benefits.
- Funnel analytics is in place and resilient.
