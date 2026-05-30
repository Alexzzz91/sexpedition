---
name: onboarding-2
description: Implements onboarding Ticket 2 by creating a multi-step welcome flow that explains app purpose, usage, value, and privacy with clear next actions. Use when user requests /onboarding-2 or onboarding UI screens.
---

# /onboarding-2

## Purpose

Implement guided onboarding UI (3-6 steps) with value-first messaging.

## Target

- `lib/screen/` (new onboarding screen/widget files)
- `lib/app.dart` (or startup routing location)

## Required screens (minimum)

1. Welcome: what the app is for.
2. Why use it: benefits for the couple.
3. Privacy: how sensitive data is protected.
4. How it works: partner connection + Wish Match.
5. First action: prompt user to do one meaningful step.

## UX constraints

- Keep each step short and emotional, not technical.
- Show progress indicator (e.g., step 2/5).
- Allow back/next and optional skip (if product policy allows).
- Primary CTA on each step; one clear action only.

## Implementation checklist

- [ ] Onboarding screen flow is integrated into startup routing
- [ ] User sees onboarding only when required
- [ ] Copy is concise and benefit-oriented
- [ ] Completion action calls `markOnboardingCompleted`

## Validation

1. Run `flutter analyze`.
2. Verify first-run flow end-to-end.
3. Verify app relaunch bypasses onboarding after completion.

## Done criteria

- New users get a clear, complete onboarding walkthrough.
