import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar_model.dart';
import '../models/blocked_time_range.dart';

abstract class CalendarDataSource {
  Future<List<CalendarSlot>> loadMonth(DateTime month);
  Future<List<CalendarSlot>> loadDate(DateTime date);
  Future<Map<String, CalendarDayAvailability>> loadAvailability(DateTime month);
  Future<void> saveAvailability(
    DateTime date,
    bool available, {
    List<BlockedTimeRange> blockedTimes = const [],
  });
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
          .from('tmv_time_slot')
          .select(
            'time_slot_id,slot_date,start_time,end_time,tmv_booking_slot(selection_status,expires_at,tmv_booking(booking_id,event_type,location,booking_status,tmv_client(tmv_user(full_name))))',
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
  Future<Map<String, CalendarDayAvailability>> loadAvailability(
    DateTime month,
  ) async {
    final from = dateKey(DateTime(month.year, month.month));
    final until = dateKey(DateTime(month.year, month.month + 1));
    final values = await Future.wait<dynamic>([
      client.rpc(
        'tmv_get_month_availability',
        params: {'p_year': month.year, 'p_month': month.month},
      ),
      _blockedTimes(from, until),
    ]);
    final availability = values[0] as Map<String, dynamic>;
    final days = availability['days'] as Map<String, dynamic>;
    final blocks = <String, List<BlockedTimeRange>>{};
    for (final row in values[1] as List) {
      int minutes(String value) {
        final parts = value.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }

      (blocks[row['slot_date']] ??= []).add(
        BlockedTimeRange(
          startMinutes: minutes(row['start_time']),
          endMinutes: minutes(row['end_time']),
        ),
      );
    }
    return {
      for (final entry in days.entries)
        entry.key: CalendarDayAvailability(
          available: entry.value['status'] != 'blocked',
          status: entry.value['status'] as String,
          blockedTimes: List.unmodifiable(blocks[entry.key] ?? []),
        ),
    };
  }

  Future<List<Map<String, dynamic>>> _blockedTimes(
    String from,
    String until,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += 200) {
      final rows = await client
          .from('tmv_date_time_block')
          .select('slot_date,start_time,end_time')
          .gte('slot_date', from)
          .lt('slot_date', until)
          .order('slot_date', ascending: true)
          .order('start_time', ascending: true)
          .range(offset, offset + 199);
      result.addAll(rows);
      if (rows.length < 200) return result;
    }
  }

  @override
  Future<void> saveAvailability(
    DateTime date,
    bool available, {
    List<BlockedTimeRange> blockedTimes = const [],
  }) async {
    final issue = BlockedTimeRange.validate(blockedTimes);
    if (issue != null) throw FormatException(issue);
    String time(int value) =>
        '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
    await client.rpc(
      'tmv_admin_save_date_availability',
      params: {
        'p_date': dateKey(date),
        'p_available': available,
        'p_blocks': [
          for (final range in blockedTimes)
            {
              'start_time': time(range.startMinutes),
              'end_time': time(range.endMinutes),
            },
        ],
      },
    );
  }
}
