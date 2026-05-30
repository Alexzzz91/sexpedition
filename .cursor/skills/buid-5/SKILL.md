---
name: buid-5
description: Implements Ticket 5 by tightening Firestore rules for wishes with connection-based access, immutable field protection, and secret visibility constraints. Use when user requests /buid-5 or Ticket 5 security rules.
---

# /buid-5

## Purpose

Implement `TICKET 5`: Firestore security rules for wishes privacy.

## Target

- File: `firestore.rules`

## Required changes

1. Restrict read/write to participants of the related connection.
2. Protect immutable fields from updates:
   - `authorUid`
   - `connectionId`
3. Enforce secret visibility logic for `secret_until_match`.
4. Limit writes to allowed mutable fields (status/match metadata by policy).

## Implementation checklist

- [ ] Membership check helper exists and is reused
- [ ] Create rules validate required fields
- [ ] Update rules block immutable field mutation
- [ ] Secret visibility logic is enforced
- [ ] Rule file remains readable and structured

## Validation

1. Deploy/emulate rules and run permission tests.
2. Verify:
   - non-member denied
   - member allowed
   - immutable field update denied.

## Done criteria

- Wishes data is protected by connection membership and privacy constraints.
