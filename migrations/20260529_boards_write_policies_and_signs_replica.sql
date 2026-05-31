-- Migration: Add boards write policies + signs REPLICA IDENTITY
-- Created: 2026-05-29
-- Purpose:
--   1. boards table has SELECT policy only; no DELETE or UPDATE policy. Under RLS,
--      that means delete/update silently no-op (0 rows affected, no error). UI does
--      an optimistic remove, then checkMembership refetches and the row reappears.
--   2. signs table needs REPLICA IDENTITY FULL so the realtime delete event carries
--      the row's id. Without it, cross-device delete updates silently fail to fire
--      handleRealtimeChange's removeAll. Local optimistic removal handles the
--      single-device case but other devices viewing the same board won't see the
--      delete until they refetch.

-- 1a · Allow owners to delete their boards
create policy "Owners can delete boards" on boards for delete
  using (auth_user_board_role(id) = 'owner');

-- 1b · Allow owners + admins to update board fields (name, is_pinned)
create policy "Owners and admins can update boards" on boards for update
  using (auth_user_board_role(id) in ('owner', 'admin'));

-- 2 · Include full row in WAL events for DELETE so realtime echoes carry id
alter table public.signs replica identity full;
