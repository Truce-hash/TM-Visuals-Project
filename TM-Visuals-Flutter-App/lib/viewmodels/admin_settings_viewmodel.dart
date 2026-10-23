import 'package:flutter/material.dart';
import '../models/admin_settings.dart';

class AdminSettingsViewModel extends ChangeNotifier {
  AdminSettings settings = AdminSettings(password: '', email: '', phone: '');

  bool hidePassword = true;

  void toggleHidePassword() {
    hidePassword = !hidePassword;
    notifyListeners();
  }

  void save() {
    // Later: send the new values to the backend
    notifyListeners();
  }
}