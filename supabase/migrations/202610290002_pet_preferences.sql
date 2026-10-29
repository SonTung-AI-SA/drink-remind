begin;
alter table public.profiles add column pet text not null default 'cat' check (pet in ('cat','dog','fish'));
create or replace function public.apply_settings_command(
  p_command_id uuid, p_operation text, p_payload jsonb,
  p_expected_revision bigint default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  owner uuid := auth.uid();
  req jsonb;
  receipt public.sync_receipts%rowtype;
  result jsonb;
  current_revision bigint;
  target_day date;
begin
  if owner is null then raise exception 'Authentication required' using errcode='28000'; end if;
  if p_command_id is null or p_operation is null or p_operation not in ('preferences.upsert','goal.upsert')
    or p_payload is null or jsonb_typeof(p_payload)<>'object' then
    raise exception 'Invalid command' using errcode='22023';
  end if;
  req:=jsonb_build_object('operation',p_operation,'payload',p_payload,'expected_revision',p_expected_revision);
  perform pg_advisory_xact_lock(hashtextextended(owner::text,0));
  select * into receipt from public.sync_receipts where user_id=owner and command_id=p_command_id;
  if found then
    if receipt.request<>req then raise exception 'Command id reused with different input' using errcode='22023'; end if;
    return receipt.result;
  end if;
  if p_operation='preferences.upsert' then
    select revision into current_revision from public.profiles where user_id=owner for update;
    if current_revision is distinct from p_expected_revision then raise exception 'Revision conflict' using errcode='40001'; end if;
    update public.profiles set daily_goal=(p_payload->>'goal')::integer,
      start_minute=(p_payload->>'start_minute')::integer,end_minute=(p_payload->>'end_minute')::integer,
      age=(p_payload->>'age')::integer,weight=(p_payload->>'weight')::numeric,
      height=(p_payload->>'height')::numeric,sex=p_payload->>'sex',pet=coalesce(p_payload->>'pet',pet),revision=revision+1
      where user_id=owner returning to_jsonb(profiles.*) into result;
  else
    target_day:=(p_payload->>'local_day')::date;
    if target_day is null then raise exception 'Missing day' using errcode='22023'; end if;
    select revision into current_revision from public.daily_goals where user_id=owner and local_day=target_day for update;
    if current_revision is distinct from p_expected_revision then raise exception 'Revision conflict' using errcode='40001'; end if;
    insert into public.daily_goals(user_id,local_day,goal) values(owner,target_day,(p_payload->>'goal')::integer)
      on conflict(user_id,local_day) do update set goal=excluded.goal,revision=daily_goals.revision+1
      returning to_jsonb(daily_goals.*) into result;
  end if;
  if result is null then raise exception 'Profile unavailable' using errcode='22023'; end if;
  insert into public.sync_receipts(user_id,command_id,request,result) values(owner,p_command_id,req,result);
  return result;
end;
$$;
revoke all on function public.apply_settings_command(uuid,text,jsonb,bigint) from public;
grant execute on function public.apply_settings_command(uuid,text,jsonb,bigint) to authenticated;
commit;
