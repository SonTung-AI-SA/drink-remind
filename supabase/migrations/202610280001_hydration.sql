-- Initial backend schema. Runs on Supabase Postgres 17, local or self-hosted.
begin;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  daily_goal integer not null default 2000 check (daily_goal between 500 and 5000 and daily_goal % 50 = 0),
  start_minute integer not null default 480 check (start_minute between 0 and 1439),
  end_minute integer not null default 1260 check (end_minute between 0 and 1439),
  age integer check (age between 18 and 100),
  weight numeric check (weight between 30 and 250),
  height numeric check (height between 100 and 230),
  sex text not null default 'unspecified' check (sex in ('unspecified','female','male')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_minute - start_minute >= 60)
);

create table public.daily_goals (
  user_id uuid not null references auth.users(id) on delete cascade,
  local_day date not null,
  goal integer not null check (goal between 500 and 5000 and goal % 50 = 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, local_day)
);

create table public.water_intakes (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount integer not null check (amount between 10 and 2000),
  occurred_at timestamptz not null,
  local_day date not null,
  offset_minutes integer not null check (offset_minutes between -840 and 840),
  on_time boolean not null default false,
  deleted boolean not null default false,
  revision bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index water_intakes_user_day on public.water_intakes(user_id, local_day, occurred_at);

create table public.sync_receipts (
  user_id uuid not null references auth.users(id) on delete cascade,
  command_id uuid not null,
  request jsonb not null,
  result jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id, command_id)
);

alter table public.profiles enable row level security;
alter table public.daily_goals enable row level security;
alter table public.water_intakes enable row level security;
alter table public.sync_receipts enable row level security;

create policy profiles_select on public.profiles for select to authenticated using (user_id=(select auth.uid()));
create policy profiles_update on public.profiles for update to authenticated
  using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
create policy goals_select on public.daily_goals for select to authenticated using (user_id=(select auth.uid()));
create policy goals_insert on public.daily_goals for insert to authenticated with check (user_id=(select auth.uid()));
create policy goals_update on public.daily_goals for update to authenticated
  using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
create policy intakes_select on public.water_intakes for select to authenticated using (user_id=(select auth.uid()));
create policy receipts_select on public.sync_receipts for select to authenticated using (user_id=(select auth.uid()));

revoke all on public.profiles, public.daily_goals, public.water_intakes, public.sync_receipts from anon, authenticated;
grant select on public.profiles, public.daily_goals, public.water_intakes, public.sync_receipts to authenticated;
grant update (daily_goal,start_minute,end_minute,age,weight,height,sex) on public.profiles to authenticated;
grant insert, update on public.daily_goals to authenticated;
grant all on public.profiles, public.daily_goals, public.water_intakes, public.sync_receipts to service_role;

create function public.touch_updated_at() returns trigger language plpgsql
set search_path = '' as $$
begin
  new.updated_at=clock_timestamp();
  return new;
end;
$$;
create trigger profiles_touch before update on public.profiles for each row execute function public.touch_updated_at();
create trigger goals_touch before update on public.daily_goals for each row execute function public.touch_updated_at();

create function public.create_user_profile() returns trigger language plpgsql security definer
set search_path = '' as $$
begin
  insert into public.profiles(user_id) values(new.id) on conflict do nothing;
  return new;
end;
$$;
create trigger create_profile_after_signup after insert on auth.users
for each row execute function public.create_user_profile();
insert into public.profiles(user_id) select id from auth.users on conflict do nothing;

-- Mutation endpoint: verifies identity, ownership, revision and replay key in one transaction.
-- user_id comes exclusively from the authenticated JWT, never the client payload.
create function public.apply_intake_command(
  p_command_id uuid,
  p_operation text,
  p_payload jsonb,
  p_expected_revision bigint default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  owner uuid := auth.uid();
  intake_id uuid;
  existing public.water_intakes%rowtype;
  receipt public.sync_receipts%rowtype;
  command_request jsonb;
  command_result jsonb;
  record_exists boolean;
begin
  if owner is null then raise exception 'Authentication required' using errcode='28000'; end if;
  if p_command_id is null or p_operation not in ('intake.upsert','intake.delete') or p_operation is null
    or p_payload is null or jsonb_typeof(p_payload)<>'object' then
    raise exception 'Invalid command' using errcode='22023';
  end if;
  intake_id := (p_payload->>'id')::uuid;
  if intake_id is null then raise exception 'Missing intake id' using errcode='22023'; end if;
  command_request := jsonb_build_object('operation',p_operation,'payload',p_payload,'expected_revision',p_expected_revision);
  -- Serialize mutations of this user's entries, including retries of the same command.
  perform pg_advisory_xact_lock(hashtextextended(owner::text,0));
  select * into receipt from public.sync_receipts where user_id=owner and command_id=p_command_id;
  if found then
    if receipt.request<>command_request then raise exception 'Command id reused with different input' using errcode='22023'; end if;
    return receipt.result;
  end if;
  select * into existing from public.water_intakes where id=intake_id for update;
  record_exists:=found;
  if record_exists and existing.user_id<>owner then
    raise exception 'Intake unavailable' using errcode='42501';
  end if;
  if record_exists and (p_expected_revision is null or p_expected_revision<>existing.revision) then
    raise exception 'Revision conflict' using errcode='40001';
  end if;
  if not record_exists and p_expected_revision is not null then
    raise exception 'Revision conflict' using errcode='40001';
  end if;
  if p_operation='intake.delete' then
    if not record_exists then raise exception 'Intake unavailable' using errcode='22023'; end if;
    update public.water_intakes set deleted=true, revision=revision+1,updated_at=clock_timestamp()
      where id=intake_id returning * into existing;
  elsif record_exists then
    if existing.deleted then raise exception 'Deleted intake cannot be resurrected' using errcode='22023'; end if;
    update public.water_intakes set amount=(p_payload->>'amount')::integer,
      revision=revision+1,updated_at=clock_timestamp()
      where id=intake_id returning * into existing;
  else
    insert into public.water_intakes(id,user_id,amount,occurred_at,local_day,offset_minutes,on_time)
      values(intake_id,owner,(p_payload->>'amount')::integer,(p_payload->>'occurred_at')::timestamptz,
        (p_payload->>'local_day')::date,(p_payload->>'offset_minutes')::integer,
        coalesce((p_payload->>'on_time')::boolean,false)) returning * into existing;
  end if;
  command_result:=to_jsonb(existing);
  insert into public.sync_receipts(user_id,command_id,request,result)
    values(owner,p_command_id,command_request,command_result);
  return command_result;
end;
$$;

revoke all on function public.touch_updated_at() from public;
revoke all on function public.create_user_profile() from public;
revoke all on function public.apply_intake_command(uuid,text,jsonb,bigint) from public;
grant execute on function public.apply_intake_command(uuid,text,jsonb,bigint) to authenticated;

commit;
