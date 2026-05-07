-- ============================================================
-- House Signs — refined schema (multitenancy + roles + invites)
-- Run in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- Types
-- ============================================================

create type household_role as enum ('owner', 'admin', 'member');


-- ============================================================
-- Tables
-- ============================================================

create table households (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  created_by   uuid not null references auth.users(id),
  created_at   timestamptz not null default now()
);

-- One row per (user, household) pair. A user can appear once per household.
create table household_members (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         household_role not null default 'member',
  joined_at    timestamptz not null default now(),

  unique (household_id, user_id)
);

create index household_members_user_idx      on household_members(user_id);
create index household_members_household_idx on household_members(household_id);

-- Invite codes. One code joins you into one household as a member.
-- Codes can optionally expire and/or cap their use count.
create table household_invites (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  code         text not null unique,
  created_by   uuid not null references auth.users(id),
  created_at   timestamptz not null default now(),
  expires_at   timestamptz,                       -- null = never expires
  max_uses     int,                               -- null = unlimited
  use_count    int not null default 0,
  revoked_at   timestamptz                        -- null = active
);

create index household_invites_code_idx on household_invites(code);

-- Signs — unchanged structurally, but now RLS-enforced via household_members
create table signs (
  id                uuid primary key default gen_random_uuid(),
  household_id      uuid not null references households(id) on delete cascade,
  label             text not null,
  emoji             text not null default '📌',
  state_off_label   text not null,
  state_on_label    text not null,
  active            boolean not null default false,
  last_changed_at   timestamptz,
  last_changed_by   text,                         -- display name; migrate to user_id when auth is wired in the app
  position          int not null default 0,
  created_at        timestamptz not null default now()
);

create index signs_household_position_idx on signs(household_id, position);

-- Event log
create table sign_flips (
  id           bigserial primary key,
  sign_id      uuid not null references signs(id) on delete cascade,
  household_id uuid not null references households(id) on delete cascade,
  to_state     boolean not null,
  flipped_by   text,
  flipped_at   timestamptz not null default now()
);

create index sign_flips_sign_time_idx      on sign_flips(sign_id, flipped_at desc);
create index sign_flips_household_time_idx on sign_flips(household_id, flipped_at desc);

-- Realtime
alter publication supabase_realtime add table signs;


-- ============================================================
-- Helper function: is the current user a member of a household?
-- (and optionally: at a minimum role level)
-- Used inside RLS policies to avoid repeated subqueries.
-- ============================================================

create or replace function auth_user_household_role(hid uuid)
returns household_role
language sql
security definer
stable
as $$
  select role
  from household_members
  where household_id = hid
    and user_id = auth.uid()
  limit 1;
$$;


-- ============================================================
-- Trigger: enforce rule 7 — owner cannot remove themselves
-- Belt-and-suspenders alongside the RLS delete policy.
-- ============================================================

create or replace function prevent_owner_self_removal()
returns trigger
language plpgsql
as $$
begin
  if OLD.role = 'owner' and OLD.user_id = auth.uid() then
    raise exception 'An owner cannot remove themselves from a household. Transfer ownership first.';
  end if;
  return OLD;
end;
$$;

create trigger enforce_owner_cannot_leave
  before delete on household_members
  for each row
  execute function prevent_owner_self_removal();


-- ============================================================
-- RLS
-- ============================================================

alter table households        enable row level security;
alter table household_members enable row level security;
alter table household_invites enable row level security;
alter table signs             enable row level security;
alter table sign_flips        enable row level security;

-- ---- households ----

-- Any member can see their households
create policy "members can read their households"
  on households for select
  using (
    id in (
      select household_id from household_members where user_id = auth.uid()
    )
  );

-- Any authenticated user can create a household (they become the owner via create_household())
create policy "authenticated users can create households"
  on households for insert
  with check (auth.uid() is not null);

-- Only owners can rename/update the household
create policy "owners can update household"
  on households for update
  using (auth_user_household_role(id) = 'owner');

-- Owners can delete the household
create policy "owners can delete household"
  on households for delete
  using (auth_user_household_role(id) = 'owner');


-- ---- household_members ----

-- Any member of a household can see who else is in it
create policy "members can view household members"
  on household_members for select
  using (
    household_id in (
      select household_id from household_members where user_id = auth.uid()
    )
  );

-- Inserts handled exclusively via join_household() and create_household() RPCs
-- No direct insert policy — the functions use SECURITY DEFINER

-- Rule 5: any non-owner can remove themselves
create policy "non-owners can leave a household"
  on household_members for delete
  using (
    user_id = auth.uid()
    and role != 'owner'
  );

-- Rules 6 + 7 + "admins cannot remove owners":
--   owners and admins can remove other non-owner members
--   nobody can remove an owner via this path
create policy "owners and admins can remove non-owners"
  on household_members for delete
  using (
    role != 'owner'                                      -- target must not be an owner
    and user_id != auth.uid()                            -- not self (covered by policy above)
    and auth_user_household_role(household_id) in ('owner', 'admin')
  );

-- Only owners can change roles
create policy "owners can update member roles"
  on household_members for update
  using (auth_user_household_role(household_id) = 'owner');


-- ---- household_invites ----

-- Members can view invites for their households (so they can share the code)
create policy "members can view invites"
  on household_invites for select
  using (
    household_id in (
      select household_id from household_members where user_id = auth.uid()
    )
  );

-- Owners and admins can create invite codes
create policy "owners and admins can create invites"
  on household_invites for insert
  with check (
    auth_user_household_role(household_id) in ('owner', 'admin')
  );

-- Owners and admins can revoke (update) invites
create policy "owners and admins can revoke invites"
  on household_invites for update
  using (
    auth_user_household_role(household_id) in ('owner', 'admin')
  );


-- ---- signs ----

create policy "members can read signs"
  on signs for select
  using (auth_user_household_role(household_id) is not null);

create policy "members can flip signs"
  on signs for update
  using (auth_user_household_role(household_id) is not null);

create policy "owners and admins can create signs"
  on signs for insert
  with check (
    auth_user_household_role(household_id) in ('owner', 'admin')
  );

create policy "owners and admins can delete signs"
  on signs for delete
  using (
    auth_user_household_role(household_id) in ('owner', 'admin')
  );


-- ---- sign_flips ----

create policy "members can read flip history"
  on sign_flips for select
  using (auth_user_household_role(household_id) is not null);

create policy "members can insert flips"
  on sign_flips for insert
  with check (auth_user_household_role(household_id) is not null);


-- ============================================================
-- RPCs
-- ============================================================

-- Create a household and atomically add the creator as owner.
-- Call from the app instead of raw inserts.
create or replace function create_household(household_name text)
returns uuid
language plpgsql
security definer
as $$
declare
  new_id uuid;
begin
  insert into households (name, created_by)
    values (household_name, auth.uid())
    returning id into new_id;

  insert into household_members (household_id, user_id, role)
    values (new_id, auth.uid(), 'owner');

  return new_id;
end;
$$;

-- Generate a new invite code for a household.
-- Only owners and admins can call this (enforced by insert RLS above,
-- but we double-check here for a clean error message).
create or replace function create_invite(
  hid        uuid,
  expires_in interval default null,   -- e.g. interval '7 days'
  max_uses   int      default null
)
returns text
language plpgsql
security definer
as $$
declare
  caller_role household_role;
  new_code    text;
begin
  caller_role := auth_user_household_role(hid);

  if caller_role not in ('owner', 'admin') then
    raise exception 'Only owners and admins can create invite codes.';
  end if;

  -- 8-character alphanumeric code, retry on collision
  loop
    new_code := upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    exit when not exists (select 1 from household_invites where code = new_code);
  end loop;

  insert into household_invites (household_id, code, created_by, expires_at, max_uses)
    values (
      hid,
      new_code,
      auth.uid(),
      case when expires_in is not null then now() + expires_in else null end,
      max_uses
    );

  return new_code;
end;
$$;

-- Redeem an invite code. Adds the calling user as a member.
-- Handles expiry, use cap, and revocation checks atomically.
create or replace function join_household(invite_code text)
returns uuid   -- returns the household_id they joined
language plpgsql
security definer
as $$
declare
  invite  household_invites%rowtype;
begin
  select * into invite
  from household_invites
  where code = upper(invite_code)
  for update;   -- lock the row for the use_count increment

  if not found then
    raise exception 'Invite code not found.';
  end if;

  if invite.revoked_at is not null then
    raise exception 'This invite code has been revoked.';
  end if;

  if invite.expires_at is not null and invite.expires_at < now() then
    raise exception 'This invite code has expired.';
  end if;

  if invite.max_uses is not null and invite.use_count >= invite.max_uses then
    raise exception 'This invite code has reached its maximum number of uses.';
  end if;

  -- Already a member? No-op rather than error.
  if exists (
    select 1 from household_members
    where household_id = invite.household_id
      and user_id = auth.uid()
  ) then
    return invite.household_id;
  end if;

  insert into household_members (household_id, user_id, role)
    values (invite.household_id, auth.uid(), 'member');

  update household_invites
    set use_count = use_count + 1
    where id = invite.id;

  return invite.household_id;
end;
$$;


-- ============================================================
-- Open questions / future considerations
-- ============================================================

-- 1. MULTIPLE OWNERS: A household can have multiple owners. This means
--    rule 7 (owner can't leave) only traps you if you're the *sole* owner.
--    Consider a check or UI nudge: "You're the only owner. Promote someone
--    before leaving."

-- 2. ADMIN vs ADMIN: As written, admins can remove other admins (rule 6
--    says "a user" with no carve-out for admin-on-admin). If you want
--    admins to only remove members, add `and role = 'member'` to the
--    "owners and admins can remove non-owners" policy's `role != 'owner'` check.

-- 3. OWNERSHIP TRANSFER: No mechanism yet for an owner to hand off ownership
--    or to promote a member to owner. Just an UPDATE on household_members.role
--    via the "owners can update member roles" policy — but you'll want a
--    dedicated UI flow for it.

-- 4. last_changed_by in signs/sign_flips is still a plain text display name.
--    When you wire Supabase Auth into the app, add a `profiles` table
--    (id uuid references auth.users, display_name text) and join on that
--    instead, so the name stays consistent even if someone changes it.
