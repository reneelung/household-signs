-- Migration: get_invite_preview RPC
-- Created: 2026-05-30
-- Purpose: fetchBoardPreview client logic can't read board_invites / boards / signs
--          for a board the caller isn't a member of (RLS blocks the SELECT).
--          A SECURITY DEFINER RPC runs as the function owner, bypasses RLS, and
--          returns only the preview fields the join screen needs:
--          board name, inviter name, member count, sign count, top 5 sign emojis.

create or replace function public.get_invite_preview(invite_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    invite_row board_invites%rowtype;
    board_row boards%rowtype;
    member_count int;
    sign_count int;
    signs_json jsonb;
    inviter_name text;
begin
    select * into invite_row
    from board_invites
    where code = upper(invite_code)
      and revoked_at is null
      and (expires_at is null or expires_at > now())
      and (max_uses is null or use_count < max_uses);

    if not found then
        return null;
    end if;

    select * into board_row from boards where id = invite_row.board_id;
    if not found then
        return null;
    end if;

    select count(*) into member_count
    from board_members
    where board_id = invite_row.board_id;

    select count(*) into sign_count
    from signs
    where board_id = invite_row.board_id;

    select coalesce(jsonb_agg(emoji order by position), '[]'::jsonb)
    into signs_json
    from (
        select emoji, position
        from signs
        where board_id = invite_row.board_id
        order by position
        limit 5
    ) s;

    select display_name into inviter_name
    from profiles
    where id = invite_row.created_by;

    return jsonb_build_object(
        'board_id',     invite_row.board_id,
        'board_name',   board_row.name,
        'member_count', member_count,
        'sign_count',   sign_count,
        'sign_emojis',  signs_json,
        'inviter_name', inviter_name
    );
end;
$$;

grant execute on function public.get_invite_preview(text) to authenticated;
