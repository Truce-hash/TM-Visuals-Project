import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw StateError('Please sign in again.');
      final rows = await _supabase
          .from('tmv_notification')
          .select('notification_id,booking_id,title,body,created_at,read_at')
          .eq('recipient_type', 'admin')
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _notifications = rows
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final bookings = context.read<BookingsViewModel>();
    try {
      final id = notification['notification_id'].toString();
      if (notification['read_at'] == null) {
        await _supabase.rpc(
          'tmv_mark_notification_read',
          params: {'p_notification_id': id},
        );
        if (mounted) {
          setState(() {
            notification['read_at'] = DateTime.now().toIso8601String();
          });
        }
      }
      final bookingId = notification['booking_id'].toString();
      if (bookings.bookingById(bookingId) == null) await bookings.load();
      if (!mounted) return;
      if (bookings.bookingById(bookingId) == null) {
        throw StateError(
          'The booking linked to this notification was not found.',
        );
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: bookingId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(adminError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AdminProfileViewModel>();

    return Scaffold(
      appBar: const AdminPageAppBar(title: 'Notifications'),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
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
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              AdminErrorNotice(error: _error!, retry: _loadNotifications)
            else if (_notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'You have no notifications.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final notification in _notifications)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                      color: adminGold,
                    ),
                    title: Text(
                      notification['title']?.toString() ?? 'Notification',
                    ),
                    subtitle: Text(
                      '${notification['body'] ?? ''}\n'
                      '${DateFormat.yMMMd().add_jm().format(DateTime.parse(notification['created_at'].toString()).toLocal())}',
                    ),
                    isThreeLine: true,
                    trailing: notification['read_at'] == null
                        ? const Icon(Icons.circle, size: 10, color: adminGold)
                        : const Icon(Icons.chevron_right),
                    onTap: () => _openNotification(notification),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
