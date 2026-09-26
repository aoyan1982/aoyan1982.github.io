-- create_couple_space を完全に作り直す修正SQL
-- Supabase SQL Editor でこのファイルだけ実行してください。

drop function if exists public.create_couple_space(text) cascade;

create function public.create_couple_space(space_name text default 'ふたり日和')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space_id uuid;
  v_code text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if exists (
    select 1
    from public.couple_members cm
    where cm.user_id = auth.uid()
  ) then
    raise exception 'Already belongs to a space';
  end if;

  loop
    v_code := upper(
      substr(
        md5(random()::text || clock_timestamp()::text || auth.uid()::text),
        1,
        8
      )
    );

    exit when not exists (
      select 1
      from public.couple_spaces cs
      where cs.invite_code = v_code
    );
  end loop;

  execute
    'insert into public.couple_spaces(name, invite_code, created_by)
     values ($1, $2, $3)
     returning id'
  into v_space_id
  using coalesce(nullif(trim(space_name), ''), 'ふたり日和'),
        v_code,
        auth.uid();

  insert into public.couple_members(space_id, user_id)
  values (v_space_id, auth.uid());

  return v_space_id;
end;
$$;

revoke all on function public.create_couple_space(text) from public;
grant execute on function public.create_couple_space(text) to authenticated;

-- PostgREST のスキーマキャッシュ更新
notify pgrst, 'reload schema';
