import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar_model.dart';

abstract class CalendarDataSource {
  Future<List<CalendarSlot>> loadMonth(DateTime month);
  Future<List<CalendarSlot>> loadDate(DateTime date);
  Future<Map<String, bool>> loadAvailability(DateTime month);
  Future<void> saveAvailability(DateTime date, bool available);
}

class CalendarService implements CalendarDataSource {
  CalendarService({SupabaseClient? supabase})
    : client = supabase ?? Supabase.instance.client;
  final SupabaseClient client;
  @override
  Future<List<CalendarSlot>> loadMonth(DateTime month) => _slots(
    DateTime(month.year, month.month),
    DateTime(month.year, month.month + 1),
  );
  @override
  Future<List<CalendarSlot>> loadDate(DateTime date) => _slots(
    DateTime(date.year, date.month, date.day),
    DateTime(date.year, date.month, date.day + 1),
  );
  Future<List<CalendarSlot>> _slots(DateTime from, DateTime until) async {
    final slots = <CalendarSlot>[];
    for (var offset = 0; ; offset += 200) {
      final rows = await client
          .from('time_slot')
          .select(
            'time_slot_id,slot_date,start_time,end_time,booking_slot(selection_status,booking:booking(booking_id,event_type,location,booking_status,client:client(users(full_name))))',
          )
          .gte('slot_date', dateKey(from))
          .lt('slot_date', dateKey(until))
          .order('slot_date')
          .order('start_time')
          .order('time_slot_id')
          .range(offset, offset + 199);
      slots.addAll(rows.map(CalendarSlot.fromMap));
      if (rows.length < 200) break;
    }
    return slots;
  }

  @override
  Future<Map<String, bool>> loadAvailability(DateTime month) async {
    final rows = await client
        .from('date_availability')
        .select('slot_date,is_available')
        .gte('slot_date', dateKey(DateTime(month.year, month.month)))
        .lt('slot_date', dateKey(DateTime(month.year, month.month + 1)));
    return {
      for (final row in rows)
        row['slot_date'] as String: row['is_available'] as bool,
    };
  }

  @override
  Future<void> saveAvailability(DateTime date, bool available) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in.');
    final admin = await client
        .from('admin')
        .select('admin_id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (admin == null) {
      throw const AuthException('Administrator access is required.');
    }
    await client
        .from('date_availability')
        .upsert({
          'slot_date': dateKey(date),
          'is_available': available,
          'updated_by': admin['admin_id'],
        }, onConflict: 'slot_date')
        .select('slot_date')
        .single();
  }
}
