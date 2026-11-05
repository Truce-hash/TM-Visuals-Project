import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_profile_viewmodel.dart';

/// Profile's branded header, shared by the main administrator pages.
/// Reads an already loaded booking count; it does not fetch profile data.
class AdminTopNav extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopNav({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final bookingCount = context.select<AdminProfileViewModel?, int>(
      (vm) => (vm?.bookingAlerts ?? true) ? vm?.user?.bookings ?? 0 : 0,
    );

    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TM ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Visuals',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Colors.orangeAccent),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none, size: 24),
              onPressed: () {
                if (ModalRoute.of(context)?.settings.name != '/notifications') {
                  Navigator.of(context).pushNamed('/notifications');
                }
              },
            ),
            if (bookingCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      bookingCount > 99 ? '99+' : '$bookingCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.tune, size: 24),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
