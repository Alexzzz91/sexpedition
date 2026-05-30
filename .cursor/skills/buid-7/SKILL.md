---
name: buid-7
description: Implements Ticket 7 by adding soft suggestion actions in matched wish cards and persisting sent suggestion actions for partner communication. Use when user requests /buid-7 or Ticket 7 soft suggestion flow.
---

# /buid-7

## Purpose

Implement `TICKET 7`: soft suggestion actions from matched wishes.

## Target

- Primary: `lib/screen/wishes_screen.dart`
- Optional: `lib/services/wishes_repository.dart`
- Optional data sink: `wish_requests` collection

## Required changes

1. Add CTA actions for matched wish cards:
   - `Хочу обсудить это с тобой`
   - `Давай попробуем в выходные?`
2. Persist action intent (event/log/document) for partner awareness.
3. Add idempotency or predictable repeated-click behavior.

## Implementation checklist

- [ ] CTA buttons are visible for matched items
- [ ] Action persists successfully
- [ ] Duplicate click behavior defined (disabled/cooldown/repeat-safe)
- [ ] UI confirms action sent

## Validation

1. Run `flutter analyze`.
2. Verify one-tap send flow and post-send state.

## Done criteria

- User can safely initiate discussion from a match in one tap.
