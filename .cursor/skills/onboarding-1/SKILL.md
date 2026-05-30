---
name: onboarding-1
description: Implements onboarding Ticket 1 by adding first-run completion state and data model needed to show onboarding only when required. Use when user requests /onboarding-1 or asks to add onboarding state management.
---

# /onboarding-1

## Purpose

Implement onboarding foundation: persistent first-run state and minimal model support.

## Target

- `lib/models/user_profile.dart` (or existing profile model file)
- `lib/services/` (profile/preferences repository)
- optional local persistence helper if already used in project

## Required changes

1. Add onboarding fields:
   - `onboardingCompletedAt: DateTime?`
   - `onboardingVersion: int` (default `1`)
   - `onboardingSkipped: bool` (default `false`)
2. Add read/write methods:
   - `isOnboardingCompleted(uid)`
   - `markOnboardingCompleted(uid, version)`
   - `skipOnboarding(uid)` (if product allows skip)
3. Keep backward compatibility:
   - old docs with missing fields must parse safely.

## Implementation checklist

- [ ] Profile model has safe defaults for missing onboarding fields
- [ ] Repository methods are implemented
- [ ] Existing auth/startup flow can query onboarding completion
- [ ] No breaking changes for current users

## Validation

1. Run `flutter analyze`.
2. Verify:
   - new user -> onboarding required
   - completed user -> onboarding not shown
   - old profile doc without fields still works.

## Done criteria

- App can reliably decide whether to show onboarding.
