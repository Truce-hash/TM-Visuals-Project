import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_settings.dart';

class AdminSettingsService {
  AdminSettingsService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AdminSettings> load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in again.');

    final profile = await _client
        .from('tmv_user')
        .select('full_name,phone')
        .eq('auth_user_id', user.id)
        .maybeSingle();
    if (profile == null) {
      throw StateError(
        'Your profile could not be found. Please contact support.',
      );
    }

    return AdminSettings(
      email: user.email ?? '',
      phone: (profile['phone'] ?? '').toString(),
      fullName: (profile['full_name'] ?? '').toString(),
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

    if (changeEmail || changePassword) {
      await _client.auth.updateUser(
        UserAttributes(
          email: changeEmail ? email : null,
          password: changePassword ? password : null,
        ),
      );
    }

    await _client.rpc(
      'tmv_update_my_profile',
      params: {'p_full_name': settings.fullName, 'p_phone': phone},
    );

    if (changePassword) {
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
    }
  }
}
