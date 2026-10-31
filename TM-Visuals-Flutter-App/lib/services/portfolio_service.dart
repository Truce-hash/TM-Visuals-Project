import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_model.dart';

class PortfolioService {
  final SupabaseClient supabase = Supabase.instance.client;

  static const String categoryTable = 'portfolio_category';
  static const String itemTable = 'portfolio_item';
  static const String bucket = 'portfolio';

  /// Returns the admin_id of the signed-in user, or throws a
  /// user-friendly error.
  Future<String> requireAdminId() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw const PortfolioError('Please log in first.');
    }

    final admin = await supabase
        .from('admin')
        .select('admin_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (admin == null) {
      throw const PortfolioError(
        'Only the administrator can manage portfolio content.',
      );
    }

    return admin['admin_id'].toString();
  }

  /// Fetches all categories ordered by category_name
  Future<List<PortfolioCategory>> fetchCategories() async {
    final response = await supabase
        .from(categoryTable)
        .select('category_id, category_name')
        .order('category_name');

    return response
        .map<PortfolioCategory>(
          (item) => PortfolioCategory.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Inserts a new category
  Future<Map<String, dynamic>> insertCategory(String name) async {
    await requireAdminId();

    final inserted = await supabase
        .from(categoryTable)
        .insert({'category_name': name})
        .select('category_id, category_name')
        .single();

    return Map<String, dynamic>.from(inserted);
  }

  /// Renames a category. Throws if RLS blocked the change (0 rows updated).
  Future<void> updateCategory(String id, String name) async {
    await requireAdminId();

    final rows = await supabase
        .from(categoryTable)
        .update({'category_name': name})
        .eq('category_id', id)
        .select('category_id');

    if (rows.isEmpty) {
      throw const PortfolioError('Could not update this category.');
    }
  }

  /// Removes a category. Throws if RLS blocked the change (0 rows deleted).
  Future<void> deleteCategory(String id) async {
    await requireAdminId();

    final rows = await supabase
        .from(categoryTable)
        .delete()
        .eq('category_id', id)
        .select('category_id');

    if (rows.isEmpty) {
      throw const PortfolioError('Could not remove this category.');
    }
  }

  /// Uploads binary file to Supabase Storage
  Future<String> uploadFile({
    required String path,
    required Uint8List fileData,
    required String contentType,
  }) async {
    await supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          fileData,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Removes an uploaded file if subsequent operations fail
  Future<void> removeFile(String path) async {
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (_) {
      // The original error is more useful to show.
    }
  }

  /// Inserts metadata into the portfolio items table
  Future<void> insertPortfolioItem({
    required String adminId,
    required String categoryId,
    required String title,
    required String mediaUrl,
    required String mediaType,
  }) async {
    await supabase.from(itemTable).insert({
      'admin_id': adminId,
      'category_id': categoryId,
      'title': title,
      'media_location': mediaUrl,
      'media_type': mediaType,
    });
  }
}