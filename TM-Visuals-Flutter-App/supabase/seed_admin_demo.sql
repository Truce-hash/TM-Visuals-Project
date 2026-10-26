-- Run as postgres after admin_features.sql and day_availability.sql.
-- Adds fictional calendar examples. Does not create Auth accounts or admin access.
-- Repeated runs leave this dataset and any subsequent edits unchanged.
begin;
do $$
declare
  demo_days date[];
  names text[] := array['Demo - Amara Nkosi','Demo - Jordan Naidoo','Demo - Lindiwe Mokoena'];
  emails text[] := array['tmv-demo-v1-amara@example.invalid','tmv-demo-v1-jordan@example.invalid','tmv-demo-v1-lindiwe@example.invalid'];
  events text[] := array['Demo wedding photography','Demo portrait session','Demo birthday photography','Demo family session','Demo corporate photography'];
  states text[] := array['approved','approved','pending','cancelled','approved'];
  locations text[] := array['Demo Garden Venue, Johannesburg','Demo Studio, Johannesburg','Demo Event Hall, Pretoria','Demo Park, Johannesburg','Demo Office, Sandton'];
  budgets numeric[] := array[5000,1200,2500,1800,4000];
  people integer[] := array[40,1,20,4,10];
  clients integer[] := array[1,2,1,3,2];
  day_indices integer[] := array[1,1,2,3,4,5];
  starts time[] := array[time '09:00',time '14:00',time '10:00',time '13:00',time '09:00',time '09:00'];
  i integer;
  uid uuid;
  cid uuid;
  bid uuid;
  sid uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended('tmv-demo-v1',0));
  if exists(select 1 from public.users where email=any(emails)) then
    if (select count(*) from public.users where email=any(emails))<>3
      or (select count(*) from public.booking where requirements like '[TMV-DEMO-V1] %')<>5 then
      raise exception 'Partial demo dataset found. Inspect it before adding more samples.';
    end if;
    raise notice 'Demo dataset already exists; no records changed.';
    return;
  end if;
  -- Choose unused dates so real schedules and existing availability stay intact.
  -- These brief locks prevent another writer using a chosen date during seeding.
  lock table public.time_slot,public.date_availability in share row exclusive mode;
  select array_agg(d order by d) into demo_days from (
    select date '2026-10-26'+n as d from generate_series(1,60) n
    where not exists(select 1 from public.time_slot s where s.slot_date=date '2026-10-26'+n)
      and not exists(select 1 from public.date_availability a where a.slot_date=date '2026-10-26'+n)
    order by n limit 5
  ) free_days;
  if coalesce(array_length(demo_days,1),0)<>5 then
    raise exception 'Not enough unused dates for sample data; nothing added.';
  end if;
  for i in 1..3 loop
    uid:=md5('tmv-demo-v1:user:'||i)::uuid;
    cid:=md5('tmv-demo-v1:client:'||i)::uuid;
    insert into public.users(user_id,full_name,email,role)values(uid,names[i],emails[i],'client');
    insert into public.client(client_id,user_id)values(cid,uid);
  end loop;
  for i in 1..6 loop
    sid:=md5('tmv-demo-v1:slot:'||i)::uuid;
    insert into public.time_slot(time_slot_id,slot_date,start_time,end_time,slot_status)
      values(sid,demo_days[day_indices[i]],starts[i],starts[i]+interval '2 hours','available');
    if i<=5 then
      bid:=md5('tmv-demo-v1:booking:'||i)::uuid;
      cid:=md5('tmv-demo-v1:client:'||clients[i])::uuid;
      insert into public.booking(booking_id,client_id,event_type,budget,requirements,number_of_people,location,terms_accepted,booking_status)
        values(bid,cid,events[i],budgets[i],'[TMV-DEMO-V1] Fictional calendar and invoice-upload example '||i,people[i],locations[i],true,states[i]);
      insert into public.booking_slot(booking_id,time_slot_id,selection_status)
        values(bid,sid,case when states[i]='cancelled' then 'cancelled' else 'selected' end);
    end if;
  end loop;
  -- Close after making the example reservation, preserving its booked session.
  insert into public.date_availability(slot_date,is_available)
    values(demo_days[4],false),(demo_days[5],false);
end$$;
commit;

select s.slot_date,s.start_time,s.end_time,
  coalesce(u.full_name,'No booking - closed demo day') as client,
  b.event_type,b.booking_status,coalesce(a.is_available,true) as day_available
from public.time_slot s
left join public.booking_slot bs on bs.time_slot_id=s.time_slot_id
left join public.booking b on b.booking_id=bs.booking_id
left join public.client c on c.client_id=b.client_id
left join public.users u on u.user_id=c.user_id
left join public.date_availability a on a.slot_date=s.slot_date
where s.time_slot_id in(select md5('tmv-demo-v1:slot:'||i)::uuid from generate_series(1,6)i)
order by s.slot_date,s.start_time;
