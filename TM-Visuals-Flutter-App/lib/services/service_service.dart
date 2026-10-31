import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_list_model.dart';

class ServiceService {
  ServiceService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _columns =
      'service_id,service_name,description,is_active,created_at';

  /// service.admin_id is NOT NULL, so look up the signed-in admin first.
  Future<String> _requireAdminId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Please log in first.');

    final admin = await _client
        .from('admin')
        .select('admin_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (admin == null) {
      throw StateError('Only the administrator can manage services.');
    }
    return admin['admin_id'].toString();
  }

  Future<List<ServicesListModel>> fetchServices() async {
    final rows = await _client
        .from('service')
        .select(_columns)
        .order('created_at', ascending: false);
    return rows
        .map<ServicesListModel>(
          (row) => ServicesListModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<ServicesListModel> addService({
    required String serviceName,
    required String description,
  }) async {
    final adminId = await _requireAdminId();

    final row = await _client
        .from('service')
        .insert({
          'admin_id': adminId,
          'service_name': serviceName.trim(),
          'description': description.trim(),
          'is_active': true,
        })
        .select(_columns)
        .single();
    return ServicesListModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<ServicesListModel> updateService(ServicesListModel service) async {
    final rows = await _client
        .from('service')
        .update(service.toMap())
        .eq('service_id', service.id)
        .select(_columns);

    // RLS blocks updates silently (0 rows), so check the result.
    if (rows.isEmpty) {
      throw StateError(
        'You do not have permission to update this service, or it no longer exists.',
      );
    }
    return ServicesListModel.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Future<void> deleteService(String serviceId) async {
    final deleted = await _client
        .from('service')
        .delete()
        .eq('service_id', serviceId)
        .select('service_id');
    if (deleted.isEmpty) {
      throw StateError('The service was not found or could not be deleted.');
    }
  }
}