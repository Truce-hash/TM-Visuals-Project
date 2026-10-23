import 'package:flutter/material.dart';
import '../models/invoice.dart';

class InvoiceListViewModel extends ChangeNotifier {
  List<Invoice> allInvoices = [
    Invoice(reference: 'Reference', dateCreated: '03/10/2026'),
  ];

  String searchText = '';

  // The list the screen shows (filtered by the search box)
  List<Invoice> get invoices {
    return allInvoices
        .where((i) =>
            i.reference.toLowerCase().contains(searchText.toLowerCase()))
        .toList();
  }

  void search(String text) {
    searchText = text;
    notifyListeners();
  }
}