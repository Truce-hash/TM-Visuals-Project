import {PGlite} from '@electric-sql/pglite';
import {readFile} from 'node:fs/promises';
const db=new PGlite();
try {
  for(const path of ['./fixture.sql','../../supabase/admin_features.sql','../../supabase/day_availability.sql']) {
    await db.exec(await readFile(new URL(path,import.meta.url),'utf8'));
  }
  await db.exec("insert into public.time_slot(slot_date,start_time,end_time,slot_status) values('2026-10-27','09:00','10:00','available'); insert into public.date_availability(slot_date,is_available) values('2026-10-28',false)");
  const seed=await readFile(new URL('../../supabase/seed_admin_demo.sql',import.meta.url),'utf8');
  await db.exec(seed);
  const snapshot=await db.query("select slot_date,start_time,end_time,slot_status from public.time_slot order by slot_date,start_time");
  await db.exec("update public.booking set location='User edited demo location' where booking_id=md5('tmv-demo-v1:booking:1')::uuid");
  await db.exec(seed);
  const after=await db.query("select slot_date,start_time,end_time,slot_status from public.time_slot order by slot_date,start_time");
  if(JSON.stringify(snapshot.rows)!==JSON.stringify(after.rows))throw Error('Repeat seed changed or duplicated slots');
  const {rows:[row]}=await db.query("select (select count(*) from public.users) users,(select count(*) from public.admin) admins,(select count(*) from public.booking) bookings,(select count(*) from public.time_slot) slots,(select count(*) from public.date_availability where not is_available) closures,(select location from public.booking where booking_id=md5('tmv-demo-v1:booking:1')::uuid) edited_location,(select min(slot_date)::text from public.time_slot where time_slot_id in(select md5('tmv-demo-v1:slot:'||i)::uuid from generate_series(1,6)i)) first_demo_day");
  if(row.users!==3||row.admins!==0||row.bookings!==5||row.slots!==7||row.closures!==3||row.edited_location!=='User edited demo location'||row.first_demo_day!=='2026-10-29')throw Error('Seed counts, date isolation, or edit preservation failed: '+JSON.stringify(row));
  const {rows:[counts]}=await db.query("select count(*) filter(where b.booking_status='approved' and a.is_available=false) booked_closed,count(*) filter(where b.booking_status='cancelled') cancelled from public.booking b join public.booking_slot bs using(booking_id) join public.time_slot s using(time_slot_id) left join public.date_availability a using(slot_date)");
  if(counts.booked_closed!==1||counts.cancelled!==1)throw Error('Expected booking examples missing');
  console.log('PASS: 3 fictional clients, 5 bookings, 6 slots, 2 demo closures; repeat run preserves edits and existing dates.');
} catch(error) { console.error(error); process.exitCode=1; }
finally {await db.close();}
