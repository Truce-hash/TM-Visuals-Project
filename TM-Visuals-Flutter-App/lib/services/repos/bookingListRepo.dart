import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photography_flutter_application/models/booking_list_model.dart';

/// Table names live here so a rename in the database is a one-line change.
class BookingTable {
  static const booking = 'booking';
}

class BookingRepository {
  final SupabaseClient _db = Supabase.instance.client;

  // One round trip: the booking, who asked, what for, and which slots.
  // booking has no service_id column: services are linked through
  // booking_service, so the select string lives in the model.
  static const String _select = BookingList.selectQuery;

  Future<List<BookingList>> fetchAll({int limit = 500}) async {
    final rows = await _db
        .from(BookingTable.booking)
        .select(_select)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(BookingList.fromJson).toList();
  }

  Future<BookingList> fetchOne(String id) async {
    final row = await _db
        .from(BookingTable.booking)
        .select(_select)
        .eq('booking_id', id)
        .single();
    return BookingList.fromJson(row);
  }

  /// One database call changes the booking status, its slots and creates the client
  /// notification together, so they can never disagree. Rejected moves
  /// (slot taken, booking already changed) come back as a PostgrestException.
  Future<void> setStatus(
    String bookingId,
    BookingStatus target, {
    String? reason,
  }) async {
    await _db.rpc(
      'admin_set_booking_status',
      params: {
        'p_booking_id': bookingId,
        'p_new_status': target.dbValue,
        'p_reason': reason,
      },
    );
  }

  /// Fires [onChange] whenever any booking row changes (new request, status change).
  RealtimeChannel listen(void Function() onChange) {
    return _db
        .channel('admin-bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: BookingTable.booking,
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> stopListening(RealtimeChannel channel) =>
      _db.removeChannel(channel);
}