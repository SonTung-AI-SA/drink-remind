begin;
insert into auth.users(id,email) values('77777777-7777-4777-8777-777777777777','settings-sync@example.invalid');
set local role authenticated;
set local request.jwt.claim.sub='77777777-7777-4777-8777-777777777777';
do $$
declare
  command uuid:=gen_random_uuid();
  payload jsonb:='{"goal":1800,"start_minute":480,"end_minute":1260,"age":26,"weight":60,"height":165,"sex":"unspecified"}';
  result jsonb;
begin
  result:=public.apply_settings_command(command,'preferences.upsert',payload,1);
  if result->>'revision'<>'2' or result->>'daily_goal'<>'1800' then raise exception 'FAIL: profile update'; end if;
  if public.apply_settings_command(command,'preferences.upsert',payload,1)<>result then raise exception 'FAIL: settings replay'; end if;
  begin
    perform public.apply_settings_command(command,'preferences.upsert',payload||'{"goal":2000}',1);
    raise exception 'FAIL: altered replay accepted';
  exception when invalid_parameter_value then null; end;
  begin
    perform public.apply_settings_command(gen_random_uuid(),'preferences.upsert',payload,1);
    raise exception 'FAIL: stale settings accepted';
  exception when serialization_failure then null; end;
  begin
    update public.profiles set daily_goal=2000;
    raise exception 'FAIL: direct profile write accepted';
  exception when insufficient_privilege then null; end;
  result:=public.apply_settings_command(gen_random_uuid(),'goal.upsert','{"local_day":"2026-10-29","goal":1800}');
  if result->>'revision'<>'1' then raise exception 'FAIL: goal create'; end if;
  begin
    perform public.apply_settings_command(gen_random_uuid(),'goal.upsert','{"local_day":"2026-10-29","goal":500}',null);
    raise exception 'FAIL: duplicate goal without revision accepted';
  exception when serialization_failure then null; end;
  begin
    insert into public.daily_goals(user_id,local_day,goal) values(auth.uid(),'2026-10-30',2000);
    raise exception 'FAIL: direct goal write accepted';
  exception when insufficient_privilege then null; end;
  begin
    perform public.apply_settings_command(gen_random_uuid(),'goal.upsert','{"local_day":"2026-10-30","goal":-1}');
    raise exception 'FAIL: invalid goal accepted';
  exception when check_violation then null; end;
end;
$$;
reset role;
rollback;
select 'settings sync checks passed' as result;
