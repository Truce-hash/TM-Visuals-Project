import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_settings.dart';

class AdminSettingsService {
  AdminSettingsService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  AdminSettings load() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in again.');
    return AdminSettings(
      email: user.email ?? '',
      phone: (user.userMetadata?['phone'] ?? user.phone ?? '').toString(),
    );
  }

  Future<void> save(AdminSettings settings) async {
    final user = _client.auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('Please sign in again.');
    }

    final email = settings.email.trim();
    final phone = settings.phone.trim();
    final password = settings.newPassword;
    final changePassword = password.isNotEmpty;
    final changeEmail = email != user.email;

    if (email.isEmpty || !email.contains('@')) {
      throw const FormatException('Enter a valid email address.');
    }
    if (phone.length > 40) {
      throw const FormatException(
        'Phone numbers must be 40 characters or fewer.',
      );
    }
    if (changePassword) {
      if (settings.currentPassword.isEmpty) {
        throw const FormatException(
          'Enter your current password to change it.',
        );
      }
      if (password.length < 8) {
        throw const FormatException(
          'Use at least 8 characters for the new password.',
        );
      }
      if (password != settings.confirmPassword) {
        throw const FormatException('The new passwords do not match.');
      }
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: settings.currentPassword,
      );
    }

    await _client.auth.updateUser(
      UserAttributes(
        email: changeEmail ? email : null,
        password: changePassword ? password : null,
        data: {...?user.userMetadata, 'phone': phone},
      ),
    );

    if (changePassword) {
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
    }
  }
}
