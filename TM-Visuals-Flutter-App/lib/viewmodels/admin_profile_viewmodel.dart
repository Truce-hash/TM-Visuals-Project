import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user.dart';

class AdminProfileViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AdminUser? _user;
  bool _isLoading = false;
  bool bookingAlerts = true;
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
    notifyListeners();

    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      final userData = await _supabase
          .from('users')
          .select('*, admin(*)')
          .eq('user_id', authUser.id)
          .single();

      final adminList = userData['admin'] as List?;
      String activeAdminId = '';
      if (adminList != null && adminList.isNotEmpty) {
        activeAdminId = adminList.first['admin_id'] ?? '';
      }

      List serviceData = [];
      if (activeAdminId.isNotEmpty) {
        serviceData = await _supabase
            .from('service')
            .select()
            .eq('admin_id', activeAdminId);
      }

      final bookingsCount = await _supabase.from('booking').count();
      final invoicesCount = await _supabase.from('invoice').count();
      final contentCount = await _supabase.from('client_content').count();

      final Map<String, dynamic> fullJsonData = Map<String, dynamic>.from(
        userData,
      );
      fullJsonData['service'] = serviceData;

      _user = AdminUser.fromJson(
        fullJsonData,
        bookings: bookingsCount,
        invoices: invoicesCount,
        contentDone: contentCount,
      );
    } catch (e) {
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
    notifyListeners();

    try {
      await _supabase
          .from('users')
          .update({'full_name': name, 'phone': phone})
          .eq('user_id', _user!.userId);

      if (_user!.adminId.isNotEmpty) {
        await _supabase
            .from('admin')
            .update({'business_name': businessName})
            .eq('admin_id', _user!.adminId);
      }

      await fetchAdminProfile();
      return true;
    } catch (e) {
      debugPrint('Error updating relational profile tables: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void toggleBookingAlerts(bool value) {
    bookingAlerts = value;
    notifyListeners();
  }

  void changeNav(int index) {
    navIndex = index;
    notifyListeners();
  }
}
