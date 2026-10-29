-- Transactional integration checks; all fixtures are rolled back.
begin;
insert into auth.users(id,email) values
 ('11111111-1111-4111-8111-111111111111','island-test-a@example.invalid'),
 ('22222222-2222-4222-8222-222222222222','island-test-b@example.invalid');

set local role authenticated;
set local request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
do $$
declare
  payload jsonb:='{"id":"33333333-3333-4333-8333-333333333333","amount":250,"occurred_at":"2026-10-28T01:00:00Z","local_day":"2026-10-28","offset_minutes":420,"on_time":true}';
  result jsonb;
  replay jsonb;
begin
  if (select count(*) from public.profiles)<>1 then raise exception 'FAIL: profile RLS'; end if;
  result:=public.apply_intake_command('44444444-4444-4444-8444-444444444444','intake.upsert',payload);
  if result->>'revision'<>'1' or result->>'amount'<>'250' then raise exception 'FAIL: insert'; end if;
  replay:=public.apply_intake_command('44444444-4444-4444-8444-444444444444','intake.upsert',payload);
  if result<>replay or (select count(*) from public.water_intakes)<>1 then raise exception 'FAIL: replay'; end if;
  begin
    perform public.apply_intake_command('44444444-4444-4444-8444-444444444444','intake.upsert',payload||'{"amount":350}');
    raise exception 'FAIL: altered replay accepted';
  exception when invalid_parameter_value then null;
  end;
  result:=public.apply_intake_command('55555555-5555-4555-8555-555555555555','intake.upsert',payload||'{"amount":350}',1);
  if result->>'revision'<>'2' or result->>'amount'<>'350' then raise exception 'FAIL: edit'; end if;
  begin
    perform public.apply_intake_command('66666666-6666-4666-8666-666666666666','intake.upsert',payload,1);
    raise exception 'FAIL: stale revision accepted';
  exception when serialization_failure then null;
  end;
  begin
    insert into public.water_intakes(id,user_id,amount,occurred_at,local_day,offset_minutes)
      values(gen_random_uuid(),auth.uid(),250,now(),current_date,420);
    raise exception 'FAIL: direct write accepted';
  exception when insufficient_privilege then null;
  end;
end;
$$;

set local request.jwt.claim.sub='22222222-2222-4222-8222-222222222222';
do $$
begin
  if (select count(*) from public.water_intakes)<>0 then raise exception 'FAIL: intake RLS'; end if;
  if (select count(*) from public.sync_receipts)<>0 then raise exception 'FAIL: receipt RLS'; end if;
  begin
    perform public.apply_intake_command('77777777-7777-4777-8777-777777777777','intake.delete',
      '{"id":"33333333-3333-4333-8333-333333333333"}',2);
    raise exception 'FAIL: cross-user mutation accepted';
  exception when insufficient_privilege then null;
  end;
end;
$$;

set local request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
do $$
declare result jsonb;
begin
  result:=public.apply_intake_command('88888888-8888-4888-8888-888888888888','intake.delete',
      '{"id":"33333333-3333-4333-8333-333333333333"}',2);
  if result->>'deleted'<>'true' or result->>'revision'<>'3' then raise exception 'FAIL: tombstone'; end if;
  begin
    perform public.apply_intake_command('99999999-9999-4999-8999-999999999999','intake.upsert',
      '{"id":"33333333-3333-4333-8333-333333333333","amount":250}',3);
    raise exception 'FAIL: deleted row resurrected';
  exception when invalid_parameter_value then null;
  end;
  if (select count(*) from public.sync_receipts)<>3 then raise exception 'FAIL: failed operations wrote receipts'; end if;
end;
$$;
rollback;
select 'Backend integration checks passed' as result;
