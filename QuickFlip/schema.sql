create extension if not exists "uuid-ossp";

-- Enum for board member roles
create type board_role as enum ('owner', 'admin', 'member');

-- Boards table
create table public.boards (
    id uuid not null default gen_random_uuid(),
    name text not null,
    created_by uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (id)
);

-- Board members table
create table public.board_members (
    id uuid not null default gen_random_uuid(),
    board_id uuid not null references boards(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role board_role not null,
    joined_at timestamptz not null default now(),
    primary key (id),
    unique (board_id, user_id)
);

-- Board invites table
create table public.board_invites (
    id uuid not null default gen_random_uuid(),
    board_id uuid not null references boards(id) on delete cascade,
    code text not null unique,
    created_by uuid not null references auth.users(id),
    created_at timestamptz not null default now(),
    expires_at timestamptz,
    max_uses int,
    use_count int not null default 0,
    revoked_at timestamptz,
    primary key (id)
);

-- Signs table
create table public.signs (
    id uuid not null default gen_random_uuid(),
    board_id uuid not null references boards(id) on delete cascade,
    label text not null,
    emoji text not null,
    state_off_label text not null,
    state_on_label text not null,
    active boolean not null default false,
    last_changed_at timestamptz,
    last_changed_by text,
    position int not null default 0,
    color_index int not null default 0,
    created_at timestamptz not null default now(),
    primary key (id)
);

-- Sign flips event log table
create table public.sign_flips (
    id bigserial not null primary key,
    sign_id uuid not null references signs(id) on delete cascade,
    board_id uuid not null references boards(id) on delete cascade,
    to_state boolean not null,
    flipped_by text,
    flipped_at timestamptz not null default now()
);

-- Enable RLS
alter table boards enable row level security;
alter table board_members enable row level security;
alter table board_invites enable row level security;
alter table signs enable row level security;
alter table sign_flips enable row level security;

-- Helper function to get user's role in a board
create function auth_user_board_role(board_id uuid) returns board_role as $$
  select role from board_members where board_id = $1 and user_id = auth.uid()
$$ language sql stable;

-- RLS Policies for boards
create policy "Users can view boards they are a member of" on boards for select
  using (exists(select 1 from board_members where boards.id = board_id and user_id = auth.uid()));

-- RLS Policies for board_members
create policy "Users can view members in their boards" on board_members for select
  using (board_id in (select board_id from board_members where user_id = auth.uid()));

-- RLS Policies for board_invites
create policy "Owners and admins can view invites" on board_invites for select
  using (auth_user_board_role(board_id) in ('owner', 'admin'));

create policy "Owners and admins can create invites" on board_invites for insert
  with check (auth_user_board_role(board_id) in ('owner', 'admin'));

create policy "Owners and admins can delete invites" on board_invites for delete
  using (auth_user_board_role(board_id) in ('owner', 'admin'));

-- RLS Policies for signs
create policy "Board members can view signs" on signs for select
  using (board_id in (select board_id from board_members where user_id = auth.uid()));

create policy "Owners and admins can insert signs" on signs for insert
  with check (auth_user_board_role(board_id) in ('owner', 'admin'));

create policy "Owners and admins can update signs" on signs for update
  using (auth_user_board_role(board_id) in ('owner', 'admin'))
  with check (auth_user_board_role(board_id) in ('owner', 'admin'));

create policy "Owners and admins can delete signs" on signs for delete
  using (auth_user_board_role(board_id) in ('owner', 'admin'));

-- RLS Policies for sign_flips
create policy "Board members can view flips" on sign_flips for select
  using (board_id in (select board_id from board_members where user_id = auth.uid()));

create policy "Board members can log flips" on sign_flips for insert
  with check (board_id in (select board_id from board_members where user_id = auth.uid()));

-- Realtime publication
alter publication supabase_realtime add table signs;

-- RPC: Create a new board and add caller as owner
create function create_board(board_name text) returns uuid as $$
declare
    new_board_id uuid;
begin
    insert into boards (name, created_by) values (board_name, auth.uid()) returning id into new_board_id;
    insert into board_members (board_id, user_id, role) values (new_board_id, auth.uid(), 'owner');
    return new_board_id;
end;
$$ language plpgsql security definer;

-- RPC: Join a board with an invite code
create function join_board(invite_code text) returns uuid as $$
declare
    board_id_var uuid;
begin
    update board_invites
    set use_count = use_count + 1
    where code = upper(invite_code)
      and (expires_at is null or expires_at > now())
      and (revoked_at is null)
      and (max_uses is null or use_count < max_uses)
    returning board_id into board_id_var;

    if board_id_var is null then
        raise exception 'Invalid or expired invite code';
    end if;

    insert into board_members (board_id, user_id, role)
    values (board_id_var, auth.uid(), 'member')
    on conflict (board_id, user_id) do nothing;

    return board_id_var;
end;
$$ language plpgsql security definer;
