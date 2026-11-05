import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user.dart';

class AdminProfileViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AdminUser? _user;
  bool _isLoading = false;
  bool bookingAlerts = true;
  Object? profileError;
  int navIndex = 3;

  AdminUser? get user => _user;
  bool get isLoading => _isLoading;

  /* -------------------------------------------------------------
     OLD HARDCODED INITIALIZATION (Kept here for backup reference)
     -------------------------------------------------------------
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
  ------------------------------------------------------------- */

  Future<void> fetchAdminProfile() async {
    _isLoading = true;
    profileError = null;
    notifyListeners();

    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      final userData = await _supabase
          .from('tmv_user')
          .select('user_id,auth_user_id,full_name,email,phone')
          .eq('auth_user_id', authUser.id)
          .single();

      final adminData = await _supabase
          .from('tmv_admin')
          .select('admin_id,user_id,business_name,booking_alerts')
          .eq('user_id', authUser.id)
          .maybeSingle();
      if (adminData == null) {
        throw StateError('This account does not have administrator access.');
      }
      bookingAlerts = adminData['booking_alerts'] as bool? ?? true;

      List serviceData = [];
      final activeAdminId = adminData['admin_id'].toString();
      if (activeAdminId.isNotEmpty) {
        serviceData = await _supabase
            .from('tmv_service')
            .select()
            .eq('admin_id', activeAdminId);
      }

      final bookingsCount = await _supabase.from('tmv_booking').count();
      final invoicesCount = await _supabase.from('tmv_invoice').count();
      final contentCount = await _supabase.from('tmv_client_content').count();

      final Map<String, dynamic> fullJsonData = Map<String, dynamic>.from(
        userData,
      );
      fullJsonData['admin'] = adminData;
      fullJsonData['service'] = serviceData;

      _user = AdminUser.fromJson(
        fullJsonData,
        bookings: bookingsCount,
        invoices: invoicesCount,
        contentDone: contentCount,
      );
    } catch (e) {
      profileError = e;
      debugPrint('Error loading relational admin profile data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAdminProfile({
    required String name,
    required String businessName,
    required String phone,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    profileError = null;
    notifyListeners();

    try {
      await _supabase.rpc(
        'tmv_update_my_profile',
        params: {'p_full_name': name, 'p_phone': phone},
      );

      if (_user!.adminId.isNotEmpty) {
        await _supabase.rpc(
          'tmv_set_admin_business_name',
          params: {'p_business_name': businessName},
        );
      }

      await fetchAdminProfile();
      return profileError == null;
    } catch (e) {
      profileError = e;
      debugPrint('Error updating relational profile tables: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleBookingAlerts(bool value) async {
    final oldValue = bookingAlerts;
    bookingAlerts = value;
    profileError = null;
    notifyListeners();
    try {
      await _supabase.rpc(
        'tmv_set_admin_booking_alerts',
        params: {'p_enabled': value},
      );
    } catch (e) {
      bookingAlerts = oldValue;
      profileError = e;
      debugPrint('Error saving booking alert preference: $e');
      notifyListeners();
      rethrow;
    }
  }

  void changeNav(int index) {
    navIndex = index;
    notifyListeners();
  }
}
