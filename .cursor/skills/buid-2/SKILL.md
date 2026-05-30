---
name: buid-2
description: Implements Ticket 2 by extending wishes repository with secret wish create/update methods, normalized tags, and streams for own unmatched wishes and matched wishes. Use when user requests /buid-2 or Ticket 2 repository work.
---

# /buid-2

## Purpose

Implement `TICKET 2`: repository methods for secret wishes and match-related streams.

## Target

- File: `lib/services/wishes_repository.dart`

## Required changes

1. Add methods:
   - `Future<void> createSecretWish(...)`
   - `Stream<List<Wish>> watchOwnUnmatchedWishes(String connectionId, String uid)`
   - `Stream<List<Wish>> watchMatchedWishes(String connectionId)`
   - `Future<void> updateWishStatus(String wishId, WishStatus status)`
2. Normalize tags when creating a wish:
   - trim, lowercase, remove empty, deduplicate.
3. Ensure filters are deterministic:
   - own unmatched: `authorUid == uid`, unmatched, sorted by create time.
   - matched: only wishes with match markers.

## Implementation checklist

- [ ] Added required public methods
- [ ] Tag normalization helper added and used
- [ ] Streams return mapped `Wish` models
- [ ] Status updates are minimal and safe
- [ ] Errors are propagated or handled consistently

## Validation

1. Run `flutter analyze`.
2. Verify repository calls compile from existing UI/service call sites.

## Done criteria

- Secret wish CRUD path is available.
- Own unmatched and matched streams return expected results.
- Status update works for `new/discuss/planned/done`.
