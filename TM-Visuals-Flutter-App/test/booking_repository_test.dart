import 'package:flutter_test/flutter_test.dart';
import 'package:photography_flutter_application/models/booking_list_model.dart';
import 'package:photography_flutter_application/services/repos/bookingListRepo.dart';

void main() {
  Map<String, dynamic> bookingRow(String id) => {
    'booking_id': id,
    'client_id': 'client-1',
    'event_type': 'Wedding',
    'booking_status': 'confirmed',
    'created_at': '2025-04-05T10:00:00Z',
    'updated_at': '2025-04-05T10:00:00Z',
    'booking_service': <dynamic>[],
    'booking_slot': <dynamic>[],
  };

  test('booking RPC rows are converted to a typed booking list', () {
    final List<BookingList> bookings = parseBookingRows(
      List<dynamic>.of([bookingRow('booking-1')]),
    );

    expect(bookings, hasLength(1));
    expect(bookings.single.id, 'booking-1');
  });

  test('booking RPC result honors the requested limit', () {
    final bookings = parseBookingRows(
      List<dynamic>.of([bookingRow('booking-1'), bookingRow('booking-2')]),
      limit: 1,
    );

    expect(bookings.map((booking) => booking.id), ['booking-1']);
  });

  test('booking RPC rejects an unexpected response shape', () {
    expect(
      () => parseBookingRows({'booking_id': 'booking-1'}),
      throwsFormatException,
    );
    expect(
      () => parseBookingRows(List<dynamic>.of(['not-a-booking-row'])),
      throwsFormatException,
    );
  });
}
