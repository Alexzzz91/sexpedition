---
name: buid-4
description: Implements Ticket 4 by updating WishesScreen with tabs for own secret wishes and matches, wiring repository streams, and status actions in UI. Use when user requests /buid-4 or Ticket 4 UI work.
---

# /buid-4

## Purpose

Implement `TICKET 4`: UI for secret wishes and matches.

## Target

- File: `lib/screen/wishes_screen.dart`

## Required changes

1. Add two tabs/segments:
   - `Мои секретные`
   - `Совпадения`
2. Initialize streams once in `initState`.
3. Bind UI to repository streams:
   - own unmatched list
   - matched list
4. Add actions on matched cards:
   - `Обсудить`
   - `Запланировать`
   - `Выполнено`
5. Handle empty/error/loading states for each tab.

## Implementation checklist

- [ ] Tab switching works without recreating subscriptions
- [ ] Lists render correctly for both tabs
- [ ] Status actions call repository update
- [ ] Empty states are user-friendly
- [ ] No build-time stream recreation

## Validation

1. Run `flutter analyze`.
2. Manually verify:
   - both tabs load
   - status action updates item state
   - empty states display when no data.

## Done criteria

- Wishes screen supports full MVP browsing and status flow.
