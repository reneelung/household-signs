# house-signs

A "status flipper" app — shared household binary state signs, like a dishwasher clean/dirty magnet but as an app. Tap to flip state, see who flipped it and when.

## Stack

- **Frontend:** React + Vite
- **Backend:** Supabase (Postgres, RLS, Realtime subscriptions)
- **Target platform:** iOS via Capacitor → TestFlight → eventually App Store
- **Deploy:** Vercel (web), Capacitor (iOS)

## Where we are

The app loads and connects to Supabase. The board renders but is empty because:

1. No seed data exists (intentional — app should be self-seeding via Add Sign)
2. RLS is currently **disabled** on all tables for development. Re-enable once auth is wired.

The Add Sign modal exists in the UI but hasn't been tested end-to-end against Supabase yet. That's the immediate next task.

## Immediate next tasks (in order)

1. **Insert a household row** into Supabase (Table Editor → `households`) and make sure `HOUSEHOLD_ID` in `App.jsx` matches it. `created_by` can be any UUID for now.
2. **Wire up and test Add Sign** — the modal and `addSign()` function exist, just needs a real household to write to.
3. **Add Supabase Auth** (magic link / email OTP). This replaces the current device-name prompt. Once auth is in place, re-enable RLS.
4. **Household creation + join flow** — first-time UX where a user creates a household or joins one via invite code. `HOUSEHOLD_ID` is currently hardcoded and needs to become dynamic.
5. **Capacitor setup** for iOS build → TestFlight.

## Data model

Five tables:

```
households          id, name, created_by, created_at
household_members   id, household_id, user_id, role (owner|admin|member), joined_at
household_invites   id, household_id, code, created_by, expires_at, max_uses, use_count, revoked_at
signs               id, household_id, label, emoji, state_off_label, state_on_label,
                    active, last_changed_at, last_changed_by (text, temp), position, created_at
sign_flips          id, sign_id, household_id, to_state, flipped_by (text, temp), flipped_at
```

`signs` is current state. `sign_flips` is the append-only event log for analytics.
`last_changed_by` and `flipped_by` are plain text display names for now — migrate to `user_id` references once auth is wired.

## Three RPCs in the schema

- `create_household(name)` — creates household + inserts calling user as owner atomically
- `create_invite(household_id, expires_in, max_uses)` — generates invite code
- `join_household(code)` — redeems invite code, adds user as member

## Role rules

- `owner` > `admin` > `member`
- Owners and admins can remove non-owners (including other admins)
- Owners cannot remove themselves (enforced by trigger AND RLS)
- Owners can update member roles
- Only owners and admins can create/delete signs and create invite codes
- All members can flip signs and read flip history
- Multiple owners per household are allowed

## RLS

Written and in the schema but currently disabled. The helper function
`auth_user_household_role(household_id uuid)` is used across policies — it returns the
calling user's role in a given household. Re-enable RLS and wire Supabase Auth together.

## Design

- Warm earthy palette (`#faf6f1` background, rich reds/greens for card states)
- Typography: DM Serif Display (headings, state labels) + DM Sans (body)
- 2-column card grid, cards flip state on tap, long-press to delete
- Each card shows: emoji, label, current state, who flipped it + how long ago
- On first open, user is prompted for a display name (temporary — replaced by auth)

## Key decisions already made (don't re-litigate)

- Supabase over Firebase — Postgres familiarity, SQL analytics against `sign_flips`
- Capacitor over React Native — preserve existing React code, faster to TestFlight
- `sign_flips` as a separate event log (not just `signs.active`) — enables streak/analytics queries
- `last_changed_by` denormalized onto `signs` for cheap card renders (avoid join on every load)
- Multiple owners allowed per household
- Admins can remove other admins
- Invite codes are household-scoped, support optional expiry and use caps
