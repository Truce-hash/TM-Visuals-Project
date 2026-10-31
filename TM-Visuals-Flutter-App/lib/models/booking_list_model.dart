import 'package:flutter/foundation.dart';

//Kamohelo P testing model for booking list screen
enum BookingStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  declined('declined', 'Declined'),
  cancelled('cancelled', 'Cancelled'),
  completed('completed', 'Completed'),
  unknown('', 'Unknown');

  const BookingStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static BookingStatus parse(String? v) => BookingStatus.values.firstWhere(
    (s) => s.dbValue == v && s != BookingStatus.unknown,
    orElse: () => BookingStatus.unknown,
  );
}

DateTime _at(DateTime day, String hhmm) {
  final p = hhmm.split(':');
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(p[0]),
    int.parse(p[1]),
  );
}

/// One row of booking_slot joined with its time_slot.
@immutable
class BookedSlot {
  final String bookingSlotId;
  final String timeSlotId;
  final DateTime date;
  final String start;
  final String end;
  final String selectionStatus; // held | confirmed | released
  final DateTime? expiresAt; // not a booking_slot column; kept for compatibility

  const BookedSlot({
    required this.bookingSlotId,
    required this.timeSlotId,
    required this.date,
    required this.start,
    required this.end,
    required this.selectionStatus,
    this.expiresAt,
  });

  bool get isReleased => selectionStatus == 'released';
  DateTime get startsAt => _at(date, start);
  DateTime get endsAt => _at(date, end);

  /// Returns null when the time_slot couldn't be read, so one bad row
  /// doesn't take the whole booking down.
  static BookedSlot? tryFromJson(Map<String, dynamic> j) {
    final ts = j['time_slot'] as Map<String, dynamic>?;
    if (ts == null) return null;
    final d = DateTime.parse(ts['slot_date'] as String);
    return BookedSlot(
      bookingSlotId: j['booking_slot_id'].toString(),
      timeSlotId: j['time_slot_id'].toString(),
      date: DateTime(d.year, d.month, d.day),
      start: (ts['start_time'] as String).substring(0, 5),
      end: (ts['end_time'] as String).substring(0, 5),
      selectionStatus: (j['selection_status'] as String?) ?? 'held',
      expiresAt: j['expires_at'] == null
          ? null
          : DateTime.parse(j['expires_at'] as String).toLocal(),
    );
  }
}

/// Back-to-back slots merged into one range (09:00–10:00 + 10:00–11:00 = 09:00–11:00).
@immutable
class TimeBlock {
  final DateTime date;
  final String start;
  final String end;
  const TimeBlock(this.date, this.start, this.end);

  DateTime get startsAt => _at(date, start);
  DateTime get endsAt => _at(date, end);
  int get minutes => endsAt.difference(startsAt).inMinutes;
}

@immutable
class BookingList {
  /// Use this in `.from('booking').select(BookingList.selectQuery)`.
  /// booking has no service_id column: services come through booking_service.
  static const String selectQuery = '''
    booking_id, client_id, event_type, budget, requirements,
    number_of_people, location, terms_accepted, booking_status,
    created_at, updated_at, hold_expires_at,
    client ( user:users ( full_name, email, phone ) ),
    booking_service ( service ( service_id, service_name ) ),
    booking_slot (
      booking_slot_id, time_slot_id, selection_status,
      time_slot ( slot_date, start_time, end_time )
    )
  ''';

  final String id;
  final String clientId;
  final String serviceId; // first linked service ('' if none)
  final String eventType;
  final double? budget;
  final String requirements;
  final int numberOfPeople;
  final String location;
  final bool termsAccepted;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? holdExpires; // booking.hold_expires_at

  // Joined data (not columns of booking itself)
  final String? clientName;
  final String? clientEmail;
  final String? clientPhone;
  final String? serviceName; // all linked service names, comma separated
  final List<BookedSlot> slots;

  const BookingList({
    required this.id,
    required this.clientId,
    required this.serviceId,
    required this.eventType,
    required this.budget,
    required this.requirements,
    required this.numberOfPeople,
    required this.location,
    required this.termsAccepted,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.holdExpires,
    this.clientName,
    this.clientEmail,
    this.clientPhone,
    this.serviceName,
    this.slots = const [],
  });

  BookingList copyWith({
    String? id,
    String? clientId,
    String? serviceId,
    String? eventType,
    double? budget,
    String? requirements,
    int? numberOfPeople,
    String? location,
    bool? termsAccepted,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? holdExpires,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? serviceName,
    List<BookedSlot>? slots,
  }) {
    return BookingList(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      serviceId: serviceId ?? this.serviceId,
      eventType: eventType ?? this.eventType,
      budget: budget ?? this.budget,
      requirements: requirements ?? this.requirements,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      location: location ?? this.location,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      holdExpires: holdExpires ?? this.holdExpires,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      serviceName: serviceName ?? this.serviceName,
      slots: slots ?? this.slots,
    );
  }

  factory BookingList.fromJson(Map<String, dynamic> j) {
    final user =
        (j['client'] as Map<String, dynamic>?)?['user']
            as Map<String, dynamic>?;

    final services = ((j['booking_service'] as List?) ?? const [])
        .map((e) => (e as Map<String, dynamic>)['service'])
        .whereType<Map<String, dynamic>>()
        .toList();

    final slots =
        ((j['booking_slot'] as List?) ?? const [])
            .map((e) => BookedSlot.tryFromJson(e as Map<String, dynamic>))
            .whereType<BookedSlot>()
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return BookingList(
      id: j['booking_id'].toString(),
      clientId: j['client_id'].toString(),
      serviceId: services.isEmpty ? '' : services.first['service_id'].toString(),
      eventType: (j['event_type'] as String?) ?? '',
      budget: j['budget'] == null
          ? null
          : double.tryParse(j['budget'].toString()),
      requirements: (j['requirements'] as String?) ?? '',
      numberOfPeople: (j['number_of_people'] as num?)?.toInt() ?? 0,
      location: (j['location'] as String?) ?? '',
      termsAccepted: j['terms_accepted'] == true,
      status: BookingStatus.parse(j['booking_status'] as String?),
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(j['updated_at'] as String).toLocal(),
      holdExpires: j['hold_expires_at'] == null
          ? null
          : DateTime.parse(j['hold_expires_at'] as String).toLocal(),
      clientName: user?['full_name'] as String?,
      clientEmail: user?['email'] as String?,
      clientPhone: user?['phone'] as String?,
      serviceName: services.isEmpty
          ? null
          : services.map((s) => s['service_name']).join(', '),
      slots: slots,
    );
  }

  // ---- derived values ----

  String get displayName => (clientName?.trim().isNotEmpty ?? false)
      ? clientName!.trim()
      : 'Unknown client';

  /// Time ranges the booking occupies. Released slots only count when nothing else is left
  /// (so a declined booking still shows what was asked for).
  List<TimeBlock> get blocks {
    final active = slots.where((s) => !s.isReleased).toList();
    final src = active.isEmpty ? slots : active;
    final out = <TimeBlock>[];
    for (final s in src) {
      final last = out.isEmpty ? null : out.last;
      if (last != null && last.date == s.date && last.end == s.start) {
        out[out.length - 1] = TimeBlock(last.date, last.start, s.end);
      } else {
        out.add(TimeBlock(s.date, s.start, s.end));
      }
    }
    return out;
  }

  DateTime? get firstStart => blocks.isEmpty ? null : blocks.first.startsAt;
  DateTime? get lastEnd => blocks.isEmpty ? null : blocks.last.endsAt;
  int get totalMinutes => blocks.fold(0, (sum, b) => sum + b.minutes);

  /// When a pending request's slot hold runs out (null if none recorded).
  DateTime? get holdExpiresAt =>
      status == BookingStatus.pending ? holdExpires : null;

  // ---- which actions the admin may take (single source of truth for the UI) ----

  bool get canConfirm => status == BookingStatus.pending && slots.isNotEmpty;
  bool get canDecline => status == BookingStatus.pending;
  bool get canCancel =>
      status == BookingStatus.confirmed &&
      (lastEnd == null || lastEnd!.isAfter(DateTime.now()));
  bool get canComplete =>
      status == BookingStatus.confirmed &&
      firstStart != null &&
      !firstStart!.isAfter(DateTime.now());

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      displayName,
      clientEmail,
      clientPhone,
      serviceName,
      eventType,
      location,
      id,
    ].any((v) => (v ?? '').toLowerCase().contains(q));
  }
}