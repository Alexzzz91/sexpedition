---
name: buid-6
description: Implements Ticket 6 by adding Firestore composite indexes required for wishes queries used in the match flow. Use when user requests /buid-6 or Ticket 6 index setup.
---

# /buid-6

## Purpose

Implement `TICKET 6`: Firestore composite indexes for wishes queries.

## Target

- File: `firestore.indexes.json`

## Required changes

1. Add index:
   - `wishes(connectionId asc, status asc, createdAt desc)`
2. Add index:
   - `wishes(connectionId asc, visibility asc, createdAt desc)`
3. Keep existing index definitions intact.

## Implementation checklist

- [ ] JSON format remains valid
- [ ] Both required indexes present
- [ ] No accidental removals of current indexes

## Validation

1. Run Firebase index deploy command for the project.
2. Verify key repository queries no longer request missing indexes.

## Done criteria

- Match-flow queries execute without Firestore index errors.
