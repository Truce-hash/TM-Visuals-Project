import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/content_model.dart';

class ContentService {
  ContentService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// client_content.access_status is NOT NULL. Use the same words here and
  /// in any client-side screen that filters on it.
  static const String accessActive = 'active';

  static const String _contentColumns =
      'content_id,booking_id,title,delivery_link,uploaded_at';

  Future<List<ContentBookingOption>> fetchBookingsForClient(
    String clientId,
  ) async {
    final rows = await _client
        .from('booking')
        .select(
          'booking_id,event_type,booking_status,client:client_id(user:user_id(full_name))',
        )
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      final client = map['client'] is Map
          ? Map<String, dynamic>.from(map['client'])
          : <String, dynamic>{};
      final user = client['user'] is Map
          ? Map<String, dynamic>.from(client['user'])
          : <String, dynamic>{};
      return ContentBookingOption(
        bookingId: (map['booking_id'] ?? '').toString(),
        eventType: (map['event_type'] ?? 'Booking').toString(),
        status: (map['booking_status'] ?? '').toString(),
        clientName: (user['full_name'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<ContentModel>> fetchForClient(String clientId) async {
    final bookings = await _client
        .from('booking')
        .select(
          'booking_id,event_type,client:client_id(user:user_id(full_name))',
        )
        .eq('client_id', clientId);

    if (bookings.isEmpty) return [];

    final bookingDetails = <String, Map<String, String>>{};
    for (final booking in bookings) {
      final row = Map<String, dynamic>.from(booking);
      final bookingId = (row['booking_id'] ?? '').toString();
      final client = row['client'] is Map
          ? Map<String, dynamic>.from(row['client'])
          : <String, dynamic>{};
      final user = client['user'] is Map
          ? Map<String, dynamic>.from(client['user'])
          : <String, dynamic>{};
      bookingDetails[bookingId] = {
        'event_type': (row['event_type'] ?? '').toString(),
        'client_name': (user['full_name'] ?? '').toString(),
      };
    }

    final rows = await _client
        .from('client_content')
        .select(_contentColumns)
        .inFilter('booking_id', bookingDetails.keys.toList())
        .order('uploaded_at', ascending: false);

    return rows.map((content) {
      final row = Map<String, dynamic>.from(content);
      final details =
          bookingDetails[(row['booking_id'] ?? '').toString()] ?? {};
      return ContentModel.fromMap({
        ...row,
        'event_type': details['event_type'],
        'client_name': details['client_name'],
      });
    }).toList();
  }

  Future<ContentModel> addContent({
    required String bookingId,
    required String title,
    required String deliveryLink,
  }) async {
    _validateLink(deliveryLink);
    final row = await _client
        .from('client_content')
        .insert({
          'booking_id': bookingId,
          'title': title.trim(),
          'delivery_link': deliveryLink.trim(),
          'access_status': accessActive,
        })
        .select(_contentColumns)
        .single();
    return ContentModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<ContentModel> updateContent({
    required ContentModel content,
    required String title,
    required String deliveryLink,
  }) async {
    _validateLink(deliveryLink);
    final rows = await _client
        .from('client_content')
        .update({'title': title.trim(), 'delivery_link': deliveryLink.trim()})
        .eq('content_id', content.contentId)
        .select(_contentColumns);

    // RLS blocks updates silently (0 rows), so check the result.
    if (rows.isEmpty) {
      throw const ContentError(
        'You do not have permission to update this content, or it no longer exists.',
      );
    }

    return ContentModel.fromMap({
      ...Map<String, dynamic>.from(rows.first),
      'event_type': content.eventType,
      'client_name': content.clientName,
    });
  }

  Future<void> deleteContent(String contentId) async {
    final deleted = await _client
        .from('client_content')
        .delete()
        .eq('content_id', contentId)
        .select('content_id');

    // RLS blocks deletes silently (0 rows), so check the result.
    if (deleted.isEmpty) {
      throw const ContentError(
        'You do not have permission to delete this content, or it no longer exists.',
      );
    }
  }

  void _validateLink(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const ContentError('Enter a valid http or https delivery link.');
    }
  }
}