-- Migration: Add default_board_id to profiles + allow users to update their own profile
-- Created: 2026-05-30
-- Purpose:
--   1. Persist a per-user default board so launching / signing in jumps straight
--      to its BoardView. Per-user (not per-device) so it carries across installs.
--      ON DELETE SET NULL auto-clears the default if the board is deleted or the
--      user is removed.
--   2. profiles had only a SELECT policy — clients couldn't UPDATE their own
--      default_board_id (or display_name without going through auth metadata),
--      so writes silently no-op'd. Add a self-only UPDATE policy.

alter table public.profiles
    add column if not exists default_board_id uuid references public.boards(id) on delete set null;

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
    on public.profiles for update
    to authenticated
    using (id = auth.uid())
    with check (id = auth.uid());
