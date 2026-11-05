import 'package:flutter/foundation.dart';
import '../models/admin_settings.dart';
import '../services/admin_settings_service.dart';

class AdminSettingsViewModel extends ChangeNotifier {
  AdminSettingsViewModel({AdminSettingsService? service})
    : _service = service ?? AdminSettingsService();

  final AdminSettingsService _service;
  AdminSettings settings = AdminSettings(email: '', phone: '');
  bool loading = false;
  bool saving = false;
  bool hidePassword = true;
  String? error;

  void toggleHidePassword() {
    hidePassword = !hidePassword;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      settings = _service.load();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save() async {
    if (saving || loading) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _service.save(settings);
      settings.currentPassword = '';
      settings.newPassword = '';
      settings.confirmPassword = '';
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
