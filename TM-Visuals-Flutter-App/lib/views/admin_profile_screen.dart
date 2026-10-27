import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_profile_viewmodel.dart';
import 'invoice_list_screen.dart';

class AdminProfileScreen extends StatelessWidget {
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
                        color: Colors.amber.withOpacity(0.25),
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
              
              GestureDetector(
               onTap: () {
               Navigator.push(
                  context,
                 MaterialPageRoute(
        builder: (context) => InvoiceListScreen(),
      ),
    );
  },
  child: Container(
    width: 100,
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.grey[850],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${vm.user.invoices}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Invoices',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
          ),
        ),
      ],
    ),
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
                  subtitle: Text('Request, deposit proof',
                      style: TextStyle(color: Colors.white54, fontSize: 10)),
                  trailing: Switch(
                    value: vm.bookingAlerts,
                    activeColor: Colors.black,
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

      // ---------- Bottom navigation ----------
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.amber,
        type: BottomNavigationBarType.fixed,
        currentIndex: vm.navIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          vm.changeNav(index);
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined), label: 'Content'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}