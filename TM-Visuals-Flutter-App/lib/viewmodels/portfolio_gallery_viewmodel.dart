import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_model.dart';
import '../services/portfolio_gallery_service.dart';

class PortfolioGalleryViewModel extends ChangeNotifier {
  final PortfolioGalleryService _service = PortfolioGalleryService();

  static const int maxTitleLength = 100;

  List<PortfolioItem> items = [];
  List<PortfolioCategory> categories = [];
  String? selectedCategoryId;

  bool isLoading = true;
  bool isBusy = false; // true while saving or deleting
  bool isAdmin = false;
  String? errorMessage;

  Future<void> loadGallery() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      categories = await _service.fetchCategories();
      items = await _service.fetchItems(categoryId: selectedCategoryId);
    } catch (error) {
      errorMessage = friendlyError(error);
    }

    try {
      isAdmin = await _service.isAdmin();
    } catch (error) {
      debugPrint('Admin check failed: $error');
      isAdmin = false;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> selectCategory(String? categoryId) async {
    selectedCategoryId = categoryId;
    await loadGallery();
  }

  String categoryName(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return '';
  }

  void _sortItems() {
    items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  Future<void> updateItem(
    PortfolioItem item, {
    required String title,
    required String categoryId,
    required void Function(String) onMessage,
  }) async {
    final id = item.id;
    final newTitle = title.trim();

    if (id == null || id.isEmpty) {
      onMessage('No portfolio item selected.');
      return;
    }

    if (newTitle.isEmpty) {
      onMessage('Please enter a title.');
      return;
    }

    if (newTitle.length > maxTitleLength) {
      onMessage(
        'Title is too long. Maximum length is $maxTitleLength characters.',
      );
      return;
    }

    if (newTitle == item.title && categoryId == item.categoryId) {
      return; // nothing changed
    }

    isBusy = true;
    notifyListeners();

    try {
      final updated = await _service.updateItem(
        id: id,
        title: newTitle,
        categoryId: categoryId,
      );

      final index = items.indexWhere((i) => i.id == id);
      if (index != -1) {
        // If a category filter is active and the item moved out of it,
        // it no longer belongs in this list.
        if (selectedCategoryId != null &&
            updated.categoryId != selectedCategoryId) {
          items.removeAt(index);
        } else {
          items[index] = updated;
        }
      }
      _sortItems();

      onMessage('Portfolio item updated.');
    } catch (error) {
      onMessage(friendlyError(error));
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(
    PortfolioItem item, {
    required void Function(String) onMessage,
  }) async {
    isBusy = true;
    notifyListeners();

    try {
      await _service.deleteItem(item);
      items.removeWhere((i) => i.id == item.id);
      onMessage('Portfolio item deleted.');
    } catch (error) {
      onMessage(friendlyError(error));
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  String friendlyError(Object error) {
    debugPrint('Portfolio gallery error: $error');

    if (error is PortfolioError) return error.message;

    if (error is PostgrestException) {
      switch (error.code) {
        case '42501':
          return 'You do not have permission to do that.';
        case '23503':
          return 'A related record could not be found.';
      }
    }

    return 'Something went wrong. Please check your connection and try again.';
  }
}