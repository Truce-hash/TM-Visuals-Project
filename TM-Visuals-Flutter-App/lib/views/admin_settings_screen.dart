import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_settings_viewmodel.dart';

class AdminSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var vm = context.watch<AdminSettingsViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TM ', style: TextStyle(color: Colors.white, fontSize: 20)),
            Text('Visuals',
                style: TextStyle(color: Colors.amber, fontSize: 20)),
            SizedBox(width: 8),
            
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.amber),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Settings',
              style: TextStyle(color: Colors.white, fontSize: 22)),
          SizedBox(height: 16),
          Container(
            height: 300,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                TextField(
                  obscureText: vm.hidePassword,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (value) {
                    vm.settings.password = value;
                  },
                  decoration: InputDecoration(
                    icon: SizedBox(
                      width: 130,
                      child: Text('Change Password:',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    hintText: 'Password...',
                    hintStyle: TextStyle(color: Colors.white38),
                    suffixIcon: IconButton(
                      icon: Icon(
                          vm.hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70),
                      onPressed: () {
                        vm.toggleHidePassword();
                      },
                    ),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
                TextField(
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (value) {
                    vm.settings.email = value;
                  },
                  decoration: InputDecoration(
                    icon: SizedBox(
                      width: 130,
                      child: Text('Change Email:',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    hintText: 'Email...',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
                TextField(
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (value) {
                    vm.settings.phone = value;
                  },
                  decoration: InputDecoration(
                    icon: SizedBox(
                      width: 130,
                      child: Text('Change Phone:',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    hintText: 'Phone...',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () {
                vm.save();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Settings saved')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('SAVE',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.amber,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
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