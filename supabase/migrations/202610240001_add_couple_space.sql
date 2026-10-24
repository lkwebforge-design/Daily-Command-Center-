-- Daily Command Center: secure shared Our Space chat and goals
-- Apply this file in the SQL Editor of the DCC Supabase project only.
create table if not exists public.couple_spaces (
 id uuid primary key default gen_random_uuid(),
 name text not null default 'Our Space' check (char_length(name) between 1 and 80),
 invite_code text not null unique default encode(gen_random_bytes(8),'hex'),
 created_by uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
create table if not exists public.couple_members (
 space_id uuid not null references public.couple_spaces(id) on delete cascade,
 user_id uuid not null unique references auth.users(id) on delete cascade,
 joined_at timestamptz not null default now(),
 primary key(space_id,user_id)
);
create table if not exists public.couple_messages (
 id uuid primary key default gen_random_uuid(),
 space_id uuid not null references public.couple_spaces(id) on delete cascade,
 sender_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(char_length(trim(body)) between 1 and 1500),
 created_at timestamptz not null default now()
);
create index if not exists couple_messages_space_created_idx on public.couple_messages(space_id,created_at);
create table if not exists public.couple_goals (
 id uuid primary key default gen_random_uuid(),
 space_id uuid not null references public.couple_spaces(id) on delete cascade,
 created_by uuid not null references auth.users(id) on delete cascade,
 title text not null check(char_length(trim(title)) between 1 and 180),
 details text not null default '',
 due_date date,
 completed_by uuid references auth.users(id) on delete set null,
 completed_at timestamptz,
 created_at timestamptz not null default now()
);
create index if not exists couple_goals_space_created_idx on public.couple_goals(space_id,created_at desc);
create index if not exists couple_spaces_created_by_idx on public.couple_spaces(created_by);
create index if not exists couple_messages_sender_id_idx on public.couple_messages(sender_id);
create index if not exists couple_goals_created_by_idx on public.couple_goals(created_by);
create index if not exists couple_goals_completed_by_idx on public.couple_goals(completed_by);
create index if not exists couple_weekly_checkins_user_id_idx on public.couple_weekly_checkins(user_id);
create table if not exists public.couple_weekly_checkins (
 id uuid primary key default gen_random_uuid(),
 space_id uuid not null references public.couple_spaces(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 week_start date not null,
 plan text not null default '',
 completed boolean not null default false,
 updated_at timestamptz not null default now(),
 unique(space_id,user_id,week_start)
);
alter table public.couple_spaces enable row level security;
alter table public.couple_members enable row level security;
alter table public.couple_messages enable row level security;
alter table public.couple_goals enable row level security;
alter table public.couple_weekly_checkins enable row level security;
create or replace function public.is_couple_member(p_space uuid)
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.couple_members m where m.space_id=p_space and m.user_id=(select auth.uid())) $$;
revoke all on function public.is_couple_member(uuid) from public, anon;
grant execute on function public.is_couple_member(uuid) to authenticated;
drop policy if exists couple_members_read_spaces on public.couple_spaces;
create policy couple_members_read_spaces on public.couple_spaces for select to authenticated using(public.is_couple_member(id));
drop policy if exists members_read_member_list on public.couple_members;
create policy members_read_member_list on public.couple_members for select to authenticated using(public.is_couple_member(space_id));
drop policy if exists members_read_messages on public.couple_messages;
create policy members_read_messages on public.couple_messages for select to authenticated using(public.is_couple_member(space_id));
drop policy if exists members_send_own_messages on public.couple_messages;
create policy members_send_own_messages on public.couple_messages for insert to authenticated with check(sender_id=(select auth.uid()) and public.is_couple_member(space_id));
drop policy if exists members_read_goals on public.couple_goals;
create policy members_read_goals on public.couple_goals for select to authenticated using(public.is_couple_member(space_id));
drop policy if exists members_create_goals on public.couple_goals;
create policy members_create_goals on public.couple_goals for insert to authenticated with check(created_by=(select auth.uid()) and public.is_couple_member(space_id));
drop policy if exists members_update_goals on public.couple_goals;
create policy members_update_goals on public.couple_goals for update to authenticated using(public.is_couple_member(space_id)) with check(public.is_couple_member(space_id));
drop policy if exists members_delete_own_goals on public.couple_goals;
create policy members_delete_own_goals on public.couple_goals for delete to authenticated using(created_by=(select auth.uid()) and public.is_couple_member(space_id));
drop policy if exists members_read_weekly_checkins on public.couple_weekly_checkins;
create policy members_read_weekly_checkins on public.couple_weekly_checkins for select to authenticated using(public.is_couple_member(space_id));
drop policy if exists members_insert_own_weekly_checkins on public.couple_weekly_checkins;
create policy members_insert_own_weekly_checkins on public.couple_weekly_checkins for insert to authenticated with check(user_id=(select auth.uid()) and public.is_couple_member(space_id));
drop policy if exists members_update_own_weekly_checkins on public.couple_weekly_checkins;
create policy members_update_own_weekly_checkins on public.couple_weekly_checkins for update to authenticated using(user_id=(select auth.uid()) and public.is_couple_member(space_id)) with check(user_id=(select auth.uid()) and public.is_couple_member(space_id));
grant select on public.couple_spaces,public.couple_members,public.couple_messages,public.couple_goals,public.couple_weekly_checkins to authenticated;
grant insert on public.couple_messages,public.couple_goals,public.couple_weekly_checkins to authenticated;
grant update,delete on public.couple_goals to authenticated;
grant update on public.couple_weekly_checkins to authenticated;
create or replace function public.create_couple_space(p_name text default 'Our Space')
returns table(space_id uuid, invite_code text)
language plpgsql security definer set search_path=''
as $$
declare v_user uuid:=auth.uid(); v_space uuid; v_code text;
begin
 if v_user is null then raise exception 'Sign in required'; end if;
 if exists(select 1 from public.couple_members where user_id=v_user) then raise exception 'You already belong to a couple space'; end if;
 insert into public.couple_spaces(name,created_by) values(coalesce(nullif(trim(p_name),''),'Our Space'),v_user) returning id,public.couple_spaces.invite_code into v_space,v_code;
 insert into public.couple_members(space_id,user_id) values(v_space,v_user);
 return query select v_space,v_code;
end $$;
create or replace function public.join_couple_space(p_code text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_user uuid:=auth.uid(); v_space uuid;
begin
 if v_user is null then raise exception 'Sign in required'; end if;
 if exists(select 1 from public.couple_members where user_id=v_user) then raise exception 'You already belong to a couple space'; end if;
 select id into v_space from public.couple_spaces where invite_code=lower(trim(p_code));
 if v_space is null then raise exception 'Invite code not found'; end if;
 if (select count(*) from public.couple_members where space_id=v_space)>=2 then raise exception 'This space already has two members'; end if;
 insert into public.couple_members(space_id,user_id) values(v_space,v_user);
 return v_space;
end $$;
revoke all on function public.create_couple_space(text) from public, anon;
revoke all on function public.join_couple_space(text) from public, anon;
grant execute on function public.create_couple_space(text) to authenticated;
grant execute on function public.join_couple_space(text) to authenticated;
