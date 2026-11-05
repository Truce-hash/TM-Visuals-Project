import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:photography_flutter_application/models/booking_list_model.dart';

/// Table names live here so a rename in the database is a one-line change.
class BookingTable {
  static const booking = 'tmv_booking';
}

class BookingRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<BookingList>> fetchAll({int limit = 500}) async {
    final response = await _db.rpc('tmv_admin_get_bookings');
    return parseBookingRows(response, limit: limit);
  }

  Future<BookingList> fetchOne(String id) async {
    final bookings = await fetchAll();
    return bookings.firstWhere(
      (booking) => booking.id == id,
      orElse: () => throw StateError('Booking not found.'),
    );
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
      'tmv_admin_set_booking_status',
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

@visibleForTesting
List<BookingList> parseBookingRows(Object? response, {int limit = 500}) {
  if (response is! List) {
    throw const FormatException('The bookings response was not a list.');
  }

  final bookings = <BookingList>[];
  for (final row in response) {
    if (row is! Map) {
      throw const FormatException('A booking response row was not an object.');
    }
    bookings.add(BookingList.fromJson(Map<String, dynamic>.from(row)));
  }
  return bookings.take(limit).toList(growable: false);
}
