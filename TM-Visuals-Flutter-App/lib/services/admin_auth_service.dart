import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAuthService {
  AdminAuthService(this.client);
  final SupabaseClient client;
  Stream<AuthState> get changes => client.auth.onAuthStateChange;
  String? get userId => client.auth.currentUser?.id;
  Future<String?> currentAdminId() async {
    final id = userId;
    if (id == null) return null;
    final row = await client
        .from('admin')
        .select('admin_id')
        .eq('user_id', id)
        .maybeSingle();
    return row?['admin_id'] as String?;
  }

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => client.auth.signOut();
}
