---
name: buid-3
description: Implements Ticket 3 by adding tag-based Wish Match MVP logic with safe write semantics and duplicate-match protection. Use when user requests /buid-3 or Ticket 3 matching algorithm implementation.
---

# /buid-3

## Purpose

Implement `TICKET 3`: Wish Match MVP algorithm.

## Target

- Preferred: `lib/services/wishes_repository.dart`
- Optional split: `lib/services/wish_match_service.dart`

## Required changes

1. Add `Future<int> runMatch(String connectionId)`.
2. Read candidate wishes:
   - `visibility == secret_until_match`
   - `status == new`
   - not already matched.
3. Match rules:
   - different `authorUid`
   - intersection of `normalizedTags` is not empty.
4. Write match data atomically:
   - set `matchedWithWishId`
   - set `matchedAt`
   - update visibility/status per MVP rule.
5. Prevent duplicate matching on repeated runs.

## Implementation checklist

- [ ] Candidate selection is correct
- [ ] Pairing avoids same-author matches
- [ ] Atomic write via transaction/batch
- [ ] Duplicate protection added
- [ ] Return value is count of new matches

## Validation

1. Run `flutter analyze`.
2. Manually test:
   - no overlap tags -> zero matches
   - overlap tags from two partners -> match created
   - second run does not duplicate.

## Done criteria

- Matching is deterministic and repeat-safe.
- Matches are persisted with required metadata.
