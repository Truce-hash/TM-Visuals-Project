import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/add_invoice_model.dart';

String? validateInvoicePdf(String name, Uint8List bytes) {
  if (!name.toLowerCase().endsWith('.pdf')) return 'Choose a PDF file.';
  if (bytes.length > 10 * 1024 * 1024) {
    return 'PDF files must be at most 10 MiB.';
  }
  if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
    return 'The selected file does not contain a PDF header.';
  }
  return null;
}

abstract class InvoiceDataSource {
  Future<List<InvoiceBooking>> loadBookings();
  Future<AddInvoiceModel> uploadInvoice({
    required String bookingId,
    required String reference,
    required String fileName,
    required Uint8List fileBytes,
    required String invoiceId,
    bool uncertainBefore = false,
  });
  Future<Uri> signedInvoiceUrl(String path);
}

class AddInvoiceService implements InvoiceDataSource {
  AddInvoiceService({SupabaseClient? supabase})
    : client = supabase ?? Supabase.instance.client;
  final SupabaseClient client;
  static const bucket = 'invoices';
  Future<String> requireAdminId() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in.');
    final row = await client
        .from('admin')
        .select('admin_id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) {
      throw const AuthException('Administrator access is required.');
    }
    return row['admin_id'] as String;
  }

  @override
  Future<List<InvoiceBooking>> loadBookings() async {
    final results = <InvoiceBooking>[];
    for (var offset = 0; ; offset += 200) {
      final rows = await client
          .from('booking')
          .select(
            'booking_id,event_type,booking_status,client:client(users(full_name))',
          )
          .order('created_at', ascending: false)
          .order('booking_id')
          .range(offset, offset + 199);
      results.addAll(
        rows.map((row) {
          final name =
              ((row['client'] as Map?)?['users'] as Map?)?['full_name'] ??
              'Client';
          final id = row['booking_id'] as String;
          return InvoiceBooking(
            id: id,
            label:
                '$name | ${row['event_type'] ?? 'Booking'} | ${row['booking_status']} | ${id.substring(0, id.length < 8 ? id.length : 8)}',
          );
        }),
      );
      if (rows.length < 200) break;
    }
    return results;
  }

  Future<AddInvoiceModel?> _find(String id) async {
    final row = await client
        .from('invoice')
        .select()
        .eq('invoice_id', id)
        .maybeSingle();
    return row == null ? null : AddInvoiceModel.fromMap(row);
  }

  AddInvoiceModel _matching(
    AddInvoiceModel invoice,
    String admin,
    String booking,
    String reference,
    String path,
  ) {
    if (invoice.adminId != admin ||
        invoice.bookingId != booking ||
        invoice.reference != reference ||
        invoice.filePath != path) {
      throw StateError('This invoice ID belongs to different details.');
    }
    return invoice;
  }

  @override
  Future<AddInvoiceModel> uploadInvoice({
    required String bookingId,
    required String reference,
    required String fileName,
    required Uint8List fileBytes,
    required String invoiceId,
    bool uncertainBefore = false,
  }) async {
    final validation = validateInvoicePdf(fileName, fileBytes);
    if (validation != null) throw FormatException(validation);
    reference = reference.trim();
    if (reference.isEmpty || reference.length > 120) {
      throw const FormatException(
        'Enter a reference of 1Ã¢â‚¬â€œ120 characters.',
      );
    }
    if (bookingId.isEmpty) throw const FormatException('Choose a booking.');
    final admin = await requireAdminId();
    final path = '$admin/$bookingId/$invoiceId.pdf';
    final previous = await _find(invoiceId);
    if (previous != null) {
      return _matching(previous, admin, bookingId, reference, path);
    }
    var uploaded = false;
    try {
      try {
        await client.storage
            .from(bucket)
            .uploadBinary(
              path,
              fileBytes,
              fileOptions: const FileOptions(
                contentType: 'application/pdf',
                upsert: false,
              ),
            );
        uploaded = true;
      } on StorageException catch (e) {
        // Only the same immutable attempt may reuse an uncertain prior upload.
        if (!uncertainBefore ||
            !(e.statusCode == '409' ||
                e.error == 'Duplicate' ||
                e.message.toLowerCase().contains('already exists'))) {
          rethrow;
        }
      }
      final row = await client
          .from('invoice')
          .insert({
            'invoice_id': invoiceId,
            'admin_id': admin,
            'booking_id': bookingId,
            'reference': reference,
            'file_path': path,
          })
          .select()
          .single();
      return AddInvoiceModel.fromMap(row);
    } catch (e) {
      try {
        final committed = await _find(invoiceId);
        if (committed != null) {
          return _matching(committed, admin, bookingId, reference, path);
        }
        // A missing row does not prove rollback after a transport failure.
        // Clean up only a confirmed first-attempt database rejection.
        if (e is PostgrestException &&
            RegExp(r'^(22|23|42)[0-9A-Z]{3}$').hasMatch(e.code ?? '') &&
            uploaded &&
            !uncertainBefore) {
          await client.storage.from(bucket).remove([path]);
        }
      } catch (_) {
        /* Retain the object whenever the commit outcome is uncertain. */
      }
      rethrow;
    }
  }

  @override
  Future<Uri> signedInvoiceUrl(String path) async =>
      Uri.parse(await client.storage.from(bucket).createSignedUrl(path, 300));
}
