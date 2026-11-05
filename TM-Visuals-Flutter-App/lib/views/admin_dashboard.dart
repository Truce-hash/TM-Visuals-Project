import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photography_flutter_application/views/admin_sign_in.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_top_nav.dart';

// Fix this path to wherever your viewmodel file lives.
import 'package:photography_flutter_application/viewmodels/admin_view_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const Color backgroundColor = Colors.black;
  static const Color cardColor = Color(0xFF292929);
  static const Color accentColor = Colors.amber;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminDashboardViewModel _vm = AdminDashboardViewModel();

  @override
  void initState() {
    super.initState();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  // Opens another screen, then refreshes the counts when the admin returns.
  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboard.backgroundColor,
      appBar: const AdminTopNav(),

      drawer: Drawer(
        backgroundColor: AdminDashboard.cardColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'DASHBOARD',
                  style: TextStyle(
                    color: AdminDashboard.accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
const Divider(color: AdminDashboard.accentColor),

// Drawer navigation items
for (final item in const [
  ('/', 'Home', Icons.home_outlined),
  ('/bookings', 'Bookings', Icons.event_note_outlined),
  ('/calendar', 'Calendar', Icons.calendar_today_outlined),
  ('/admin-profile', 'Profile', Icons.account_circle_outlined),
  ('/more', 'More', Icons.menu),
])
  ListTile(
    leading: Icon(item.$3, color: AdminDashboard.accentColor),
    title: Text(
      item.$2,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: () {
      Navigator.of(context).pop();

      if (item.$1 != '/') {
        Navigator.of(context).pushReplacementNamed(item.$1);
      }
    },
  ),

const Spacer(),
const Divider(color: Colors.white24),
_menuItem(Icons.logout, 'Log Out'),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),

      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.isLoading && _vm.upcoming.isEmpty && _vm.error == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AdminDashboard.accentColor,
              ),
            );
          }

          return RefreshIndicator(
            color: AdminDashboard.accentColor,
            onRefresh: _vm.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'DASHBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here's an overview of TM Visuals.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 22),

                if (_vm.error != null) ...[
                  Text(
                    'Could not load dashboard: ${_vm.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                ],

                // ---------------- Dashboard statistics ----------------
                // CHANGE: Confirmed Bookings card is back (original 2x2 layout).
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.pending_actions,
                        label: 'Pending Bookings',
                        value: '${_vm.pendingBookings}',
                        // Optional: make tappable once you have a bookings screen
                        // onTap: () => _openAndRefresh(
                        //   const AdminBookingsScreen(initialFilter: 'pending'),
                        // ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.calendar_month,
                        label: 'Confirmed Bookings',
                        value: '${_vm.confirmedBookings}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_outline,
                        label: 'Pending Deliveries',
                        value: '${_vm.pendingDeliveries}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.photo_library_outlined,
                        label: 'Completed Orders',
                        value: '${_vm.completedOrders}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ---------------- Upcoming bookings (pending only) ------
                const Text(
                  'Upcoming Bookings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (_vm.upcoming.isEmpty)
                  const _EmptyUpcomingCard()
                else
                  ..._vm.upcoming.map((b) => _UpcomingBookingCard(booking: b)),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  Widget _menuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () async {
        if (title != 'Log Out') return;

        try {
          await Supabase.instance.client.auth.signOut();

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminSignInScreen(),
              ),
              (route) => false,
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
          }
        }
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminDashboard.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AdminDashboard.accentColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: AdminDashboard.accentColor, size: 27),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyUpcomingCard extends StatelessWidget {
  const _EmptyUpcomingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminDashboard.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminDashboard.accentColor, width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.hourglass_top_outlined,
            color: AdminDashboard.accentColor,
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No pending bookings.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  final UpcomingBooking booking;

  const _UpcomingBookingCard({required this.booking});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _dateText =>
      '${booking.date.day} ${_months[booking.date.month - 1]} ${booking.date.year}';

  String _hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  String get _timeText {
    if (booking.startTime == null) return '';
    final start = _hhmm(booking.startTime!);
    final end = booking.endTime != null ? ' - ${_hhmm(booking.endTime!)}' : '';
    return '  •  $start$end';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminDashboard.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminDashboard.accentColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hourglass_top_outlined,
            color: AdminDashboard.accentColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.clientName} • ${booking.eventType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_dateText$_timeText',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (booking.location != null &&
                    booking.location!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    booking.location!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
