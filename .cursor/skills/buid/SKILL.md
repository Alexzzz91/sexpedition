---
name: buid
description: Implements Ticket 1 for Wish Match MVP by extending lib/models/wish.dart with new fields, enums, backward-compatible fromMap/toMap parsing, and safe enum fallbacks. Use when the user says /buid, asks for Ticket 1, or requests Wish model expansion for matching.
---

# /buid

## Purpose

Implement `TICKET 1`: extend the `Wish` model for Match MVP in a backward-compatible way.

## Target

- File: `lib/models/wish.dart`
- Do not modify `lib/firebase_options.dart`

## Required changes

1. Add fields to `Wish`:
   - `connectionId: String`
   - `authorUid: String`
   - `visibility: WishVisibility` (`secret_until_match`, `shared`)
   - `status: WishStatus` (`new`, `discuss`, `planned`, `done`)
   - `normalizedTags: List<String>`
   - `matchedWithWishId: String?`
   - `matchedAt: DateTime?`
2. Add enums:
   - `WishVisibility`
   - `WishStatus`
3. Update mapping:
   - `fromMap`: safely parse missing/invalid values using defaults
   - `toMap`: serialize all new fields
4. Keep old Firestore documents readable:
   - missing `visibility` -> `secret_until_match`
   - missing `status` -> `new`
   - missing `normalizedTags` -> `[]`
   - invalid enum string -> safe fallback (never throw)

## Implementation checklist

- [ ] Enums are declared in `wish.dart`
- [ ] New fields added to model constructor
- [ ] `fromMap` handles absent keys without exceptions
- [ ] `fromMap` handles unknown enum values with fallback
- [ ] `toMap` includes all new fields
- [ ] Null-safe conversion for `matchedAt`
- [ ] Existing call sites still compile

## Validation

1. Run analyzer:
   - `flutter analyze`
2. Confirm no runtime parsing failures for old `wishes` docs with missing new fields.

## Done criteria

- App compiles.
- Old and new `wishes` documents deserialize successfully.
- Enum parsing is resilient to unknown values.
