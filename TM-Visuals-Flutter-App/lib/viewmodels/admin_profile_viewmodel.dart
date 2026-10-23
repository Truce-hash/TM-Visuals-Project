import 'package:flutter/material.dart';
import '../models/admin_user.dart';

class AdminProfileViewModel extends ChangeNotifier {
  AdminUser user = AdminUser(
    name: 'TM',
    email: 'tmvisuals@gmail.com',
    role: 'Stakeholer / Admin',
    business: 'TM Visuals',
    services: 'Photo>Videos>Combined',
    whatsapp: '0833007857',
    bookings: 0,
    invoices: 0,
    contentDone: 0,
  );

  bool bookingAlerts = true;
  int navIndex = 3;

  void toggleBookingAlerts(bool value) {
    bookingAlerts = value;
    notifyListeners();
  }

  void changeNav(int index) {
    navIndex = index;
    notifyListeners();
  }
}