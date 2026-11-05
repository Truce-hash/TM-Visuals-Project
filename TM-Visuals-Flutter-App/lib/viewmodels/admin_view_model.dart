import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Must match the exact values stored in booking.booking_status.
class BookingStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const completed = 'completed';

  // CHANGE (if needed): statuses that should NOT count as a pending delivery
  // even though they aren't completed (e.g. a cancelled booking will never
  // be delivered). Edit these to match the values in your data.
  static const notDeliverable = {
    'cancelled',
    'canceled',
    'declined',
    'rejected',
  };
}

class UpcomingBooking {
  final String id;
  final String clientName;
  final String eventType;
  final String? location;
  final DateTime date;
  final String? startTime;
  final String? endTime;

  UpcomingBooking({
    required this.id,
    required this.clientName,
    required this.eventType,
    required this.date,
    this.location,
    this.startTime,
    this.endTime,
  });
}

class AdminDashboardViewModel extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  bool isLoading = false;
  String? error;

  int pendingBookings = 0;
  int confirmedBookings = 0; // CHANGE: back again for the dashboard card
  int pendingDeliveries = 0;
  int completedOrders = 0;
  List<UpcomingBooking> upcoming = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // client_content is no longer needed here, so it's removed.
      final rows = await _client.rpc('tmv_admin_get_bookings');

      final list = List<Map<String, dynamic>>.from(rows);

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      // --- Counts ------------------------------------------------------
      pendingBookings = list
          .where((b) => b['booking_status'] == BookingStatus.pending)
          .length;
      confirmedBookings = list
          .where((b) => b['booking_status'] == BookingStatus.confirmed)
          .length;
      completedOrders = list
          .where((b) => b['booking_status'] == BookingStatus.completed)
          .length;

      // CHANGE: pending deliveries = every booking NOT marked completed
      // (minus cancelled/declined ones, see BookingStatus.notDeliverable).
      pendingDeliveries = list.where((b) {
        final status = b['booking_status'];
        return status != BookingStatus.completed &&
            !BookingStatus.notDeliverable.contains(status);
      }).length;

      // --- Upcoming list: PENDING bookings only ------------------------
      final result = <UpcomingBooking>[];
      for (final b in list) {
        if (b['booking_status'] != BookingStatus.pending) continue;

        final slot = _earliestSlot(b);
        if (slot == null) continue; // no date linked, can't place it

        final date = DateTime.parse(slot['slot_date']);
        if (date.isBefore(startOfToday)) continue;

        result.add(
          UpcomingBooking(
            id: b['booking_id'],
            clientName: b['client']?['user']?['full_name'] ?? 'Unknown client',
            eventType: b['event_type'] ?? 'Event',
            location: b['location'],
            date: date,
            startTime: slot['start_time'],
            endTime: slot['end_time'],
          ),
        );
      }
      result.sort((a, b) => a.date.compareTo(b.date));
      upcoming = result;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _earliestSlot(Map<String, dynamic> booking) {
    final slots = (booking['booking_slot'] as List?) ?? [];
    Map<String, dynamic>? best;
    DateTime? bestDate;

    for (final s in slots) {
      final ts = s['time_slot'];
      final raw = ts?['slot_date'] as String?;
      if (raw == null) continue;
      final d = DateTime.parse(raw);
      if (bestDate == null || d.isBefore(bestDate)) {
        bestDate = d;
        best = Map<String, dynamic>.from(ts);
      }
    }
    return best;
  }
}
