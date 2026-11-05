import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';

class InvoiceListViewModel extends ChangeNotifier {
  InvoiceListViewModel({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  List<Invoice> allInvoices = [];
  bool isLoading = false;
  String? error;

  String searchText = '';

  // The list the screen shows (filtered by the search box)
  List<Invoice> get invoices {
    return allInvoices
        .where(
          (i) => i.reference.toLowerCase().contains(searchText.toLowerCase()),
        )
        .toList();
  }

  void search(String text) {
    searchText = text;
    notifyListeners();
  }

  Future<void> loadInvoices() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _client
          .from('tmv_invoice')
          .select('invoice_id,reference,file_path,created_at')
          .order('created_at', ascending: false);
      allInvoices = rows.map((row) {
        final rawDate = row['created_at']?.toString();
        final date = rawDate == null ? null : DateTime.tryParse(rawDate);
        return Invoice(
          id: row['invoice_id']?.toString() ?? '',
          reference: row['reference']?.toString() ?? 'Invoice',
          filePath: row['file_path']?.toString() ?? '',
          dateCreated: date == null
              ? ''
              : DateFormat('dd/MM/yyyy').format(date.toLocal()),
        );
      }).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Uri> signedInvoiceUrl(String filePath) async {
    final signedUrl = await _client.storage
        .from('invoices')
        .createSignedUrl(filePath, 300);
    return Uri.parse(signedUrl);
  }
}
