import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking_list_model.dart';
import '../viewmodels/admin_profile_viewmodel.dart';
import '../viewmodels/bookingList_viewmodel.dart';
import '../widgets/admin_page_app_bar.dart';
import '../widgets/admin_widgets.dart';
import 'booking_details.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingsViewModel>();
    final profile = context.watch<AdminProfileViewModel>();
    final requests =
        bookings.allBookings
            .where((booking) => booking.status == BookingStatus.pending)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: const AdminPageAppBar(title: 'Notifications'),
      body: RefreshIndicator(
        onRefresh: bookings.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('New booking alerts'),
              subtitle: const Text('Enable alerts for new booking requests'),
              value: profile.bookingAlerts,
              onChanged: (enabled) async {
                try {
                  await profile.toggleBookingAlerts(enabled);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(adminError(error))));
                  }
                }
              },
            ),
            if (profile.profileError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  adminError(profile.profileError!),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const Divider(),
            Text(
              'New booking requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (bookings.state == LoadState.loading ||
                bookings.state == LoadState.idle)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (bookings.state == LoadState.error)
              AdminErrorNotice(
                error:
                    bookings.error ?? 'Booking requests could not be loaded.',
                retry: bookings.load,
              )
            else if (requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'You have no new booking requests.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final booking in requests)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                      color: adminGold,
                    ),
                    title: Text(booking.displayName),
                    subtitle: Text(
                      '${booking.serviceName ?? booking.eventType}\n'
                      '${DateFormat.yMMMd().add_jm().format(booking.createdAt.toLocal())}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingDetailScreen(bookingId: booking.id),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
