import 'package:flutter/material.dart';
import 'package:photography_flutter_application/models/booking_list_model.dart';
import 'package:photography_flutter_application/viewmodels/bookingList_viewmodel.dart';
import 'package:photography_flutter_application/views/booking_details.dart';
import 'package:provider/provider.dart';
import 'package:photography_flutter_application/services/Formatters.dart';
import '../widgets/bookingStatusChip.dart';
import '../widgets/admin_bottom_nav.dart';

//Kamohelo P testing bookings screen

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final vm = context.read<BookingsViewModel>();
    await vm.load();
    vm.startListening();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingsViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("TM Visuals", style: TextStyle(color: Colors.orange)),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 71, 69, 69),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: TextField(
                        onChanged: vm.setQuery,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search...",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    ),

                    // Filter tabs from the viewmodel (Needs action / Confirmed / ...)
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        children: [
                          for (final f in BookingFilter.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${f.label} (${vm.countFor(f)})'),
                                labelStyle: TextStyle(
                                  color: vm.filter == f
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                selected: vm.filter == f,
                                showCheckmark: false,
                                selectedColor: Colors.orange,
                                backgroundColor: Colors.black,
                                side: const BorderSide(color: Colors.orange),
                                onSelected: (_) => vm.setFilter(f),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    SizedBox(height: 500, child: _buildList(context, vm)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, BookingsViewModel vm) {
    if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.state == LoadState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: vm.load, child: const Text('Try again')),
          ],
        ),
      );
    }

    final bookingsList = vm.visible;
    if (bookingsList.isEmpty) {
      return Center(
        child: Text(
          vm.query.isNotEmpty
              ? 'No bookings match "${vm.query}".'
              : 'No bookings in "${vm.filter.label}".',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: bookingsList.length,
      itemBuilder: (context, index) {
        final BookingList item = bookingsList[index];
        return Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.orange),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailScreen(bookingId: item.id),
                ),
              );
            },
            title: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                item.displayName,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.location, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),
                Text(
                  fmtBlocks(item.blocks),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 15),
              ],
            ),
            trailing: BookingStatusChip(item.status),
          ),
        );
      },
    );
  }
}
