/*import 'package:flutter/material.dart';
import 'package:photography_flutter_application/models/booking_list_model.dart';
import 'package:photography_flutter_application/views/bookings.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  final BookingListModel booking;

  const InvoiceDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Invoice Details",
          style: TextStyle(color: Colors.orange),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 46, 46, 46),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Reference",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.white,
                            ),
                          onPressed: () {
                            // Add download functionality here
                          },
                        ),
                      ],
                    ),
                    const Divider(
                      color: Color.fromARGB(31, 104, 103, 103),
                      height: 24,
                    ),

                    const Text(
                      'Client:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      booking.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Date :',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 20),

                    const Divider(color: Colors.white, height: 24),
                    
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingsScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "CANCEL",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.orange,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 26),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, size: 26),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month, size: 26),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 26),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore, size: 26),
            label: "Explore",
          ),
        ],
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:photography_flutter_application/models/booking_list_model.dart';
import 'package:photography_flutter_application/views/bookings.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

const _amber = Color(0xFFFFB300);

class InvoiceDetailsScreen extends StatelessWidget {
  final BookingList booking;

  /// URL of the invoice PDF (leave null if there is no invoice yet).
  final String? invoiceUrl;

  /// Optional: shown as the heading and in the Invoice ID row.
  final String? invoiceId;

  /// Optional: defaults to the booking's client name.
  final String? receiver;

  const InvoiceDetailsScreen({
    super.key,
    required this.booking,
    this.invoiceUrl,
    this.invoiceId,
    this.receiver,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Delete invoice?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO: delete the invoice from your backend here.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white, fontSize: 14);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back arrow + amber line
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const Divider(color: _amber, height: 1, indent: 4, endIndent: 4),

            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Invoice Details',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),

            // Card
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _amber),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Heading + download
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              invoiceId ?? 'Reference',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.file_download_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              // Add download functionality here
                            },
                          ),
                        ],
                      ),

                      // Details table
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Invoice ID', style: white),
                                  SizedBox(height: 6),
                                  Text('Receiver', style: white),
                                  SizedBox(height: 6),
                                  Text('Date Created', style: white),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              color: _amber,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(invoiceId ?? '—', style: white),
                                  const SizedBox(height: 6),
                                  Text(
                                    receiver ?? booking.clientName ?? '—',
                                    style: white.copyWith(color: _amber),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(booking.serviceId, style: white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Invoice PDF box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _amber),
                        ),
                        child: SizedBox(
                          height: 380,
                          child: ColoredBox(
                            color: Colors.white,
                            child: (invoiceUrl == null || invoiceUrl!.isEmpty)
                                ? const Center(
                                    child: Text(
                                      'No invoice available',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  )
                                : SfPdfViewer.network(invoiceUrl!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Delete button
                      SizedBox(
                        width: 140,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => _confirmDelete(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A1212),
                            side: const BorderSide(color: Color(0xFFE53935)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'DELETE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _amber,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined, size: 28),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined, size: 28),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined, size: 28),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu, size: 28),
            label: "Menu",
          ),
        ],
      ),
    );
  }
}
