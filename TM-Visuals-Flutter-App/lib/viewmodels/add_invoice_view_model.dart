import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/add_invoice_model.dart';
import '../services/add_invoice_service.dart';

class AddInvoiceViewModel extends ChangeNotifier {
  AddInvoiceViewModel({InvoiceDataSource? service, String? initialBookingId})
    : service = service ?? AddInvoiceService(),
      bookingId = initialBookingId;
  final InvoiceDataSource service;
  List<InvoiceBooking> bookings = [];
  List<AddInvoiceModel> invoices = [];
  String? bookingId, fileName, errorMessage, loadError;
  String? invoiceListError;
  String reference = '';
  Uint8List? _bytes;
  String? _invoiceId;
  AddInvoiceModel? invoice;
  bool isLoading = false,
      loadingBookings = true,
      loadingInvoices = true,
      locked = false,
      _uncertain = false,
      _disposed = false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadBookings() async {
    loadingBookings = true;
    loadError = null;
    _changed();
    try {
      final result = await service.loadBookings();
      if (!_disposed) bookings = result;
    } catch (e) {
      if (!_disposed) loadError = e.toString();
    } finally {
      if (!_disposed) {
        loadingBookings = false;
        _changed();
      }
    }
  }

  Future<void> loadInvoices() async {
    loadingInvoices = true;
    invoiceListError = null;
    _changed();
    try {
      final result = await service.loadInvoices();
      if (!_disposed) invoices = result;
    } catch (e) {
      if (!_disposed) invoiceListError = e.toString();
    } finally {
      if (!_disposed) {
        loadingInvoices = false;
        _changed();
      }
    }
  }

  /// Resume unresolved attempts for this authenticated app session.
  void prepareForBooking(String? initialBookingId) {
    if (locked && invoice == null) return;
    bookingId = initialBookingId;
    reference = '';
    fileName = null;
    _bytes = null;
    _invoiceId = null;
    invoice = null;
    locked = false;
    _uncertain = false;
    errorMessage = null;
  }

  void selectBooking(String? id) {
    if (!locked) {
      bookingId = id;
      _changed();
    }
  }

  void setReference(String value) {
    if (!locked) reference = value;
  }

  void selectPdf(String name, Uint8List bytes) {
    if (locked) return;
    final validation = validateInvoicePdf(name, bytes);
    if (validation != null) {
      fileName = null;
      _bytes = null;
      errorMessage = validation;
      _changed();
      return;
    }
    fileName = name;
    _bytes = Uint8List.fromList(bytes);
    errorMessage = null;
    _changed();
  }

  Future<bool> submit() async {
    if (isLoading || invoice != null) return false;
    if (bookingId == null || bookingId!.isEmpty) {
      errorMessage = 'Choose a booking.';
      _changed();
      return false;
    }
    if (reference.trim().isEmpty || reference.trim().length > 120) {
      errorMessage = 'Enter a reference of 1â€“120 characters.';
      _changed();
      return false;
    }
    if (_bytes == null) {
      errorMessage = 'Choose a PDF file.';
      _changed();
      return false;
    }
    isLoading = true;
    locked = true;
    errorMessage = null;
    _invoiceId ??= const Uuid().v4();
    _changed();
    try {
      final result = await service.uploadInvoice(
        bookingId: bookingId!,
        reference: reference.trim(),
        fileName: fileName!,
        fileBytes: _bytes!,
        invoiceId: _invoiceId!,
        uncertainBefore: _uncertain,
      );
      if (!_disposed) {
        invoice = result;
        await loadInvoices();
      }
      return true;
    } catch (e) {
      _uncertain = true;
      if (!_disposed) errorMessage = e.toString();
      return false;
    } finally {
      if (!_disposed) {
        isLoading = false;
        _changed();
      }
    }
  }

  // Compatibility entry point for callers of the original owned viewmodel.
  Future<bool> uploadInvoice({
    required String bookingId,
    required String reference,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    if (locked || isLoading) return false;
    selectBooking(bookingId);
    setReference(reference);
    selectPdf(fileName, fileBytes);
    return submit();
  }

  void clearError() {
    errorMessage = null;
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
