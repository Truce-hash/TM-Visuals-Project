import 'package:flutter_test/flutter_test.dart';
import 'package:photography_flutter_application/models/clients_model.dart';
import 'package:photography_flutter_application/models/content_model.dart';
import 'package:photography_flutter_application/models/service_list_model.dart';

void main() {
  test('delivery links must use http or https', () {
    expect(isValidDeliveryLink('https://example.com/gallery'), isTrue);
    expect(isValidDeliveryLink('http://example.com/gallery'), isTrue);
    expect(isValidDeliveryLink('ftp://example.com/gallery'), isFalse);
    expect(isValidDeliveryLink('not a link'), isFalse);
  });

  test('service rows map active state and identifiers', () {
    final service = ServicesListModel.fromMap({
      'service_id': 'service-1',
      'service_name': 'Photography',
      'description': 'Event photography',
      'created_at': '2025-01-02T03:04:05Z',
      'is_active': true,
    });

    expect(service.id, 'service-1');
    expect(service.serviceName, 'Photography');
    expect(service.availability, 'Available');
    expect(service.toMap()['is_active'], isTrue);
  });

  test('client rows parse the related profile and booking dates', () {
    final client = Clients.fromMap({
      'client_id': 'client-1',
      'user': {
        'full_name': 'Alex Example',
        'email': 'alex@example.com',
        'phone': '0123456789',
      },
      'bookings': [
        {
          'booking_id': 'booking-1',
          'event_type': 'Wedding',
          'created_at': '2025-04-05T10:00:00Z',
          'booking_status': 'confirmed',
        },
      ],
    });

    expect(client.name, 'Alex Example');
    expect(client.email, 'alex@example.com');
    expect(client.previousBookings, '1');
    expect(client.bookings.single.date, '2025-04-05T10:00:00Z');
  });

  test('client delivery content parses booking labels', () {
    final content = ContentModel.fromMap({
      'content_id': 'content-1',
      'booking_id': 'booking-1',
      'title': 'Wedding gallery',
      'delivery_link': 'https://example.com/gallery',
      'uploaded_at': '2025-04-05T10:00:00Z',
      'event_type': 'Wedding',
      'client_name': 'Alex Example',
    });

    expect(content.contentId, 'content-1');
    expect(content.uploadedAt, '2025-04-05');
    expect(content.eventType, 'Wedding');
    expect(content.clientName, 'Alex Example');
  });

  test('booking options include the client name in their label', () {
    final booking = ContentBookingOption.fromMap({
      'booking_id': 'booking-1',
      'booking_status': 'confirmed',
      'client': {
        'user': {'full_name': 'Alex Example'},
      },
    });

    expect(booking.label, 'Booking - Alex Example (confirmed)');
  });
}
