-- ふたり日和 / Supabase 初期設定
-- 既存の共有版から更新する場合も、そのまま再実行できます。
create extension if not exists pgcrypto;

create table if not exists public.couple_spaces (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'ふたり日和',
  invite_code text not null unique,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.couple_members (
  space_id uuid not null references public.couple_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key(space_id,user_id)
);
create table if not exists public.bucket_items (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.couple_spaces(id) on delete cascade,
  title text not null check(char_length(title) between 1 and 60),
  category text not null default 'other' check(category in('date','food','trip','home','other')),
  planned_date date, place text not null default '', note text not null default '', done boolean not null default false,
  completed_date date, memory_note text not null default '', photo_paths text[] not null default '{}',
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.bucket_items add column if not exists favorite boolean not null default false;
alter table public.bucket_items add column if not exists latitude double precision;
alter table public.bucket_items add column if not exists longitude double precision;
create index if not exists bucket_items_space_id_idx on public.bucket_items(space_id);

create table if not exists public.couple_profiles (
  space_id uuid not null references public.couple_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default '',
  area_preference text not null default '',
  updated_at timestamptz not null default now(),
  primary key(space_id,user_id)
);
create table if not exists public.anniversaries (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.couple_spaces(id) on delete cascade,
  title text not null,
  date date not null,
  repeat_type text not null default 'yearly' check(repeat_type in('yearly','once')),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.memory_reflections (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.couple_spaces(id) on delete cascade,
  item_id uuid not null references public.bucket_items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default '',
  reflection text not null default '',
  updated_at timestamptz not null default now(),
  unique(item_id,user_id)
);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists bucket_items_set_updated_at on public.bucket_items;
create trigger bucket_items_set_updated_at before update on public.bucket_items for each row execute function public.set_updated_at();

alter table public.couple_spaces enable row level security;
alter table public.couple_members enable row level security;
alter table public.bucket_items enable row level security;
alter table public.couple_profiles enable row level security;
alter table public.anniversaries enable row level security;
alter table public.memory_reflections enable row level security;

drop policy if exists "members can view their spaces" on public.couple_spaces;
create policy "members can view their spaces" on public.couple_spaces for select to authenticated using(exists(select 1 from public.couple_members m where m.space_id=id and m.user_id=auth.uid()));
drop policy if exists "users can view own membership" on public.couple_members;
create policy "users can view own membership" on public.couple_members for select to authenticated using(user_id=auth.uid());

drop policy if exists "members can select items" on public.bucket_items;
create policy "members can select items" on public.bucket_items for select to authenticated using(exists(select 1 from public.couple_members m where m.space_id=bucket_items.space_id and m.user_id=auth.uid()));
drop policy if exists "members can insert items" on public.bucket_items;
create policy "members can insert items" on public.bucket_items for insert to authenticated with check(created_by=auth.uid() and exists(select 1 from public.couple_members m where m.space_id=bucket_items.space_id and m.user_id=auth.uid()));
drop policy if exists "members can update items" on public.bucket_items;
create policy "members can update items" on public.bucket_items for update to authenticated using(exists(select 1 from public.couple_members m where m.space_id=bucket_items.space_id and m.user_id=auth.uid())) with check(exists(select 1 from public.couple_members m where m.space_id=bucket_items.space_id and m.user_id=auth.uid()));
drop policy if exists "members can delete items" on public.bucket_items;
create policy "members can delete items" on public.bucket_items for delete to authenticated using(exists(select 1 from public.couple_members m where m.space_id=bucket_items.space_id and m.user_id=auth.uid()));

drop policy if exists "members manage profiles" on public.couple_profiles;
create policy "members manage profiles" on public.couple_profiles for all to authenticated using(exists(select 1 from public.couple_members m where m.space_id=couple_profiles.space_id and m.user_id=auth.uid())) with check(user_id=auth.uid() and exists(select 1 from public.couple_members m where m.space_id=couple_profiles.space_id and m.user_id=auth.uid()));
drop policy if exists "members manage anniversaries" on public.anniversaries;
create policy "members manage anniversaries" on public.anniversaries for all to authenticated using(exists(select 1 from public.couple_members m where m.space_id=anniversaries.space_id and m.user_id=auth.uid())) with check(exists(select 1 from public.couple_members m where m.space_id=anniversaries.space_id and m.user_id=auth.uid()));
drop policy if exists "members view reflections" on public.memory_reflections;
create policy "members view reflections" on public.memory_reflections for select to authenticated using(exists(select 1 from public.couple_members m where m.space_id=memory_reflections.space_id and m.user_id=auth.uid()));
drop policy if exists "users insert own reflection" on public.memory_reflections;
create policy "users insert own reflection" on public.memory_reflections for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.couple_members m where m.space_id=memory_reflections.space_id and m.user_id=auth.uid()));
drop policy if exists "users update own reflection" on public.memory_reflections;
create policy "users update own reflection" on public.memory_reflections for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists "users delete own reflection" on public.memory_reflections;
create policy "users delete own reflection" on public.memory_reflections for delete to authenticated using(user_id=auth.uid());

create or replace function public.create_couple_space(space_name text default 'ふたり日和') returns table(space_id uuid,invite_code text) language plpgsql security definer set search_path=public as $$
declare new_space_id uuid; new_code text;
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 if exists(select 1 from public.couple_members where user_id=auth.uid()) then raise exception 'Already belongs to a space'; end if;
 loop new_code:=upper(substr(md5(random()::text || clock_timestamp()::text || auth.uid()::text),1,8)); exit when not exists(select 1 from public.couple_spaces cs where cs.invite_code=new_code); end loop;
 insert into public.couple_spaces(name,invite_code,created_by) values(coalesce(nullif(trim(space_name),''),'ふたり日和'),new_code,auth.uid()) returning id into new_space_id;
 insert into public.couple_members(space_id,user_id) values(new_space_id,auth.uid());
 return query select new_space_id,new_code;
end $$;
create or replace function public.join_couple_space(code text) returns uuid language plpgsql security definer set search_path=public as $$
declare target_id uuid; member_count integer;
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 if exists(select 1 from public.couple_members where user_id=auth.uid()) then raise exception 'Already belongs to a space'; end if;
 select cs.id into target_id from public.couple_spaces cs where cs.invite_code=upper(trim(code)); if target_id is null then raise exception 'Invite code not found'; end if;
 perform 1 from public.couple_spaces where id=target_id for update; select count(*) into member_count from public.couple_members where space_id=target_id; if member_count>=2 then raise exception 'This space already has two members'; end if;
 insert into public.couple_members(space_id,user_id) values(target_id,auth.uid()); return target_id;
end $$;
revoke all on function public.create_couple_space(text) from public;revoke all on function public.join_couple_space(text) from public;grant execute on function public.create_couple_space(text) to authenticated;grant execute on function public.join_couple_space(text) to authenticated;

revoke all on table public.couple_spaces,public.couple_members,public.bucket_items,public.couple_profiles,public.anniversaries,public.memory_reflections from anon;
grant select on public.couple_spaces,public.couple_members to authenticated;
grant select,insert,update,delete on public.bucket_items,public.couple_profiles,public.anniversaries,public.memory_reflections to authenticated;

insert into storage.buckets(id,name,public) values('memories','memories',false) on conflict(id) do update set public=false;
drop policy if exists "members can view memory photos" on storage.objects;
create policy "members can view memory photos" on storage.objects for select to authenticated using(bucket_id='memories' and exists(select 1 from public.couple_members m where m.space_id::text=(storage.foldername(name))[1] and m.user_id=auth.uid()));
drop policy if exists "members can upload memory photos" on storage.objects;
create policy "members can upload memory photos" on storage.objects for insert to authenticated with check(bucket_id='memories' and (storage.foldername(name))[2]=auth.uid()::text and exists(select 1 from public.couple_members m where m.space_id::text=(storage.foldername(name))[1] and m.user_id=auth.uid()));
drop policy if exists "members can delete memory photos" on storage.objects;
create policy "members can delete memory photos" on storage.objects for delete to authenticated using(bucket_id='memories' and exists(select 1 from public.couple_members m where m.space_id::text=(storage.foldername(name))[1] and m.user_id=auth.uid()));

do $$ begin alter publication supabase_realtime add table public.bucket_items; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.anniversaries; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.memory_reflections; exception when duplicate_object then null; end $$;
