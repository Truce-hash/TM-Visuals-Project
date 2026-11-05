import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clients_model.dart';

class ClientsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Clients>> fetchClients() async {
    final rows = await _supabase.rpc('tmv_admin_get_clients');
    return (rows as List)
        .map((row) => Clients.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
