-- Migration: Add profiles table mirroring auth.users
-- Created: 2026-05-25
-- Purpose: Allow client-side queries to join board members with display names.
--          auth.users is in the protected `auth` schema and not queryable from PostgREST,
--          so we mirror just the bits we need into public.profiles.

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Trigger function: auto-create a profile row when a new auth user signs up.
-- Reads display_name out of raw_user_meta_data (where Supabase auth stores it).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, display_name)
    values (new.id, new.raw_user_meta_data->>'display_name')
    on conflict (id) do nothing;
    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Trigger function: keep profiles.display_name in sync if the user updates their metadata.
create or replace function public.handle_user_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.profiles
    set display_name = new.raw_user_meta_data->>'display_name',
        updated_at = now()
    where id = new.id;
    return new;
end;
$$;

create trigger on_auth_user_updated
    after update of raw_user_meta_data on auth.users
    for each row execute function public.handle_user_update();

-- Backfill existing users
insert into public.profiles (id, display_name)
select id, raw_user_meta_data->>'display_name'
from auth.users
on conflict (id) do nothing;

-- RLS: any authenticated user can read all profiles
-- (so board members can see each other's names). Writes are not exposed via the table
-- — display_name is updated by the trigger above when the user updates their auth metadata.
alter table public.profiles enable row level security;

create policy "Profiles are readable by authenticated users"
    on public.profiles for select
    to authenticated
    using (true);
