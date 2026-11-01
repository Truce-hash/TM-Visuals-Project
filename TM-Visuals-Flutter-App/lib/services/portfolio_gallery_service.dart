import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_model.dart';

class PortfolioGalleryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _itemTable = 'portfolio_item';
  static const String _bucket = 'portfolio';
  static const String _itemColumns =
      'media_id, admin_id, category_id, title, media_location, media_type';

  /// True when the signed-in user is listed in the admin table.
  Future<bool> isAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final admin = await _supabase
        .from('admin')
        .select('admin_id')
        .eq('user_id', user.id)
        .maybeSingle();

    return admin != null;
  }

  Future<List<PortfolioCategory>> fetchCategories() async {
    final response = await _supabase
        .from('portfolio_category')
        .select('category_id, category_name')
        .order('category_name');

    return response
        .map<PortfolioCategory>(
          (item) => PortfolioCategory.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<PortfolioItem>> fetchItems({String? categoryId}) async {
    var query = _supabase.from(_itemTable).select(_itemColumns);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query.order('title');

    return response
        .map<PortfolioItem>(
          (item) => PortfolioItem.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Updates the title and category. Throws if RLS blocked the change
  /// (0 rows updated). Returns the updated row.
  Future<PortfolioItem> updateItem({
    required String id,
    required String title,
    required String categoryId,
  }) async {
    final rows = await _supabase
        .from(_itemTable)
        .update({'title': title, 'category_id': categoryId})
        .eq('media_id', id)
        .select(_itemColumns);

    if (rows.isEmpty) {
      throw const PortfolioError('Could not update this item.');
    }

    return PortfolioItem.fromMap(Map<String, dynamic>.from(rows.first));
  }

  /// Deletes the database row first, then the file in storage.
  /// If the file cannot be removed, the row is still gone and the
  /// error is ignored (the user-facing delete succeeded).
  Future<void> deleteItem(PortfolioItem item) async {
    if (item.id == null || item.id!.isEmpty) {
      throw const PortfolioError('No portfolio item selected.');
    }

    final rows = await _supabase
        .from(_itemTable)
        .delete()
        .eq('media_id', item.id!)
        .select('media_id');

    if (rows.isEmpty) {
      throw const PortfolioError('Could not delete this item.');
    }

    final path = _storagePathFrom(item.mediaLocation);
    if (path == null) return;

    try {
      await _supabase.storage.from(_bucket).remove([path]);
    } catch (_) {
      // The row is already deleted; an orphaned file is not worth
      // failing the whole operation.
    }
  }

  /// Turns a public URL back into the storage path
  String? _storagePathFrom(String url) {
    final marker = '/object/public/$_bucket/';
    final index = url.indexOf(marker);
    if (index == -1) return null;

    final raw = url.substring(index + marker.length).split('?').first;
    return Uri.decodeComponent(raw);
  }
}