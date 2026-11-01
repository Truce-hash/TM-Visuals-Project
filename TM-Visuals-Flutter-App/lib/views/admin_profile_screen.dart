/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_profile_viewmodel.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var vm = context.watch<AdminProfileViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Profile',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        actions: [
          Container(
            width: 28,
            height: 28,
            decoration:
                BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.notifications_none,
                size: 16, color: Colors.black),
          ),
          SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration:
                BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.tune, size: 16, color: Colors.black),
          ),
          SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.amber),
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // ---------- User card ----------
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Text(vm.user.name,
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vm.user.name,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(vm.user.email,
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                    SizedBox(height: 4),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(vm.user.role,
                          style: TextStyle(color: Colors.amber, fontSize: 9)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // ---------- Stats ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vm.user.bookings}',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    SizedBox(height: 10),
                    Text('Bookings',
                        style: TextStyle(color: Colors.white, fontSize: 9)),
                  ],
                ),
              ),
              Container(
                width: 100,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vm.user.invoices}',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    SizedBox(height: 10),
                    Text('Invoices',
                        style: TextStyle(color: Colors.white, fontSize: 9)),
                  ],
                ),
              ),
              Container(
                width: 100,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vm.user.contentDone}',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    SizedBox(height: 10),
                    Text('Content Done',
                        style: TextStyle(color: Colors.white, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // ---------- Business Details ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Business Details',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () {},
                child: Text('Edit',
                    style: TextStyle(color: Colors.amber, fontSize: 12)),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Business',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text(vm.user.business,
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Services',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text(vm.user.services,
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Whatsapp',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text(vm.user.whatsapp,
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ---------- Manage ----------
          Text('Manage',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.lock_outline,
                        color: Colors.amber, size: 18),
                  ),
                  title: Text('Change password',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text('Secure sign in',
                      style: TextStyle(color: Colors.white54, fontSize: 10)),
                  trailing: Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.notifications_none,
                        color: Colors.amber, size: 18),
                  ),
                  title: Text('New booking alerts',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text('Request, deposit proof , reschedules',
                      style: TextStyle(color: Colors.white54, fontSize: 10)),
                  trailing: Switch(
                    value: vm.bookingAlerts,
                    activeThumbColor: Colors.black,
                    activeTrackColor: Colors.amber,
                    onChanged: (value) {
                      vm.toggleBookingAlerts(value);
                    },
                  ),
                ),
                Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.circle_outlined,
                        color: Colors.amber, size: 18),
                  ),
                  title: Text('Services & pricing',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text('Packages, negotiation',
                      style: TextStyle(color: Colors.white54, fontSize: 10)),
                  trailing: Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // ---------- Logout ----------
          Center(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.logout, color: Colors.red, size: 16),
              label: Text('Logout',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:photography_flutter_application/views/admin_settings_screen.dart';
import 'package:photography_flutter_application/views/admin_sign_in.dart';
import 'package:photography_flutter_application/views/bookings.dart';
import 'package:photography_flutter_application/views/service_list_view.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/admin_profile_viewmodel.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AdminProfileViewModel>().fetchAdminProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var vm = context.watch<AdminProfileViewModel>();

    String displayName = vm.user?.name ?? 'Tshedza Mulaudzi';
    String displayEmail = vm.user?.email ?? 'tmvisuals@gmail.com';
    String displayRole = vm.user?.role ?? 'Admin';
    String displayBusiness = vm.user?.business ?? 'TM Visuals';
    String displayServices =
        vm.user?.servicesList?.join(' > ') ?? 'Photo > Videos > Combined';
    String displayWhatsapp = vm.user?.whatsapp ?? '0833007857';

    int totalBookings = vm.user?.bookings ?? 3;
    int totalInvoices = vm.user?.invoices ?? 2;
    int totalContent = vm.user?.contentDone ?? 1;

    Color cardBgColor = const Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingsScreen(),
                    ),
                  );
                },
              ),

              if (totalBookings > 0)
                Positioned(
                  top: 8,
                  right: 8,
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
                      '$totalBookings',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ---------- User Card ----------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName.substring(0, 2).toUpperCase()
                        : 'TM',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayEmail,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          displayRole,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------- Stats Grid Row ----------
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Bookings', totalBookings, cardBgColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Invoices', totalInvoices, cardBgColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Content Done',
                  totalContent,
                  cardBgColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- Business Details Header ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Business Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _showEditBottomSheet(
                  context,
                  vm,
                  displayName,
                  displayBusiness,
                  displayWhatsapp,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ---------- Business Details Block ----------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildRowDetail('Business', displayBusiness),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.black54, height: 1),
                ),
                _buildRowDetail('Services', displayServices),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.black54, height: 1),
                ),
                _buildRowDetail('Whatsapp', displayWhatsapp),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------- Manage Section Header ----------
          const Text(
            'Manage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // ---------- Manage Settings Actions Block ----------
          Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent, // Keeps your custom card color visible
              clipBehavior: Clip
                  .antiAlias, // Ensures ink ripples don't spill outside rounded corners
              child: Column(
                children: [
                  _buildMenuRow(
                    Icons.lock_outline,
                    'Change password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.black54, height: 1),
                  _buildMenuSwitchRow(
                    Icons.notifications_none,
                    'New booking alerts',
                    vm.bookingAlerts,
                    (val) {
                      vm.toggleBookingAlerts(val);
                    },
                  ),
                  const Divider(color: Colors.black54, height: 1),
                  _buildMenuRow(
                    Icons.layers_outlined,
                    'Services & pricing',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiceList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ---------- Logout Action Row ----------
          GestureDetector(
            onTap: () async {
              try {
                await Supabase.instance.client.auth.signOut();

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminSignInScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuRow(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.amber, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildMenuSwitchRow(
    IconData icon,
    String title,
    bool value,
    ValueChanged onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.amber, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: Switch(
        value: value,
        // ignore: deprecated_member_use
        activeColor: Colors.amber,
        activeTrackColor: Colors.amber.withValues(alpha: 0.3),
        inactiveTrackColor: Colors.grey,
        onChanged: onChanged,
      ),
    );
  }

  void _showEditBottomSheet(
    BuildContext context,
    AdminProfileViewModel vm,
    String name,
    String business,
    String phone,
  ) {
    final nameController = TextEditingController(text: name);
    final businessController = TextEditingController(text: business);
    final whatsappController = TextEditingController(text: phone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Profile Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField('Name', nameController),
              _buildTextField('Business Name', businessController),
              _buildTextField('WhatsApp Number', whatsappController),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final success = await vm.updateAdminProfile(
                    name: nameController.text.trim(),
                    businessName: businessController.text.trim(),
                    phone: whatsappController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile details updated successfully!',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to update profile. Checking network/RLS policy.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.amber),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amber),
          ),
        ),
      ),
    );
  }
}
