
import 'package:flutter/material.dart';
import 'admin_widgets.dart';

/// Shared navigation for all TM Visuals admin screens.
class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const routes = [
    '/',              // 0 Home
    '/bookings',      // 1 Bookings
    '/calendar',      // 2 Calendar
    '/admin-profile', // 3 Profile
    '/more',          // 4 More
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: adminGold,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black87,

      // Display labels underneath all navigation icons.
      showSelectedLabels: true,
      showUnselectedLabels: true,

      selectedFontSize: 12,
      unselectedFontSize: 11,

      onTap: (index) {
        final target = routes[index];
        if (ModalRoute.of(context)?.settings.name == target) return;
        Navigator.of(context).pushReplacementNamed(target);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 26),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_note_outlined, size: 26),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined, size: 26),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined, size: 26),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu, size: 26),
          label: 'More',
        ),
      ],
    );
  }
}
